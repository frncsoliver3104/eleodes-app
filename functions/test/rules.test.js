"use strict";
const {test,before,after,beforeEach} = require("node:test");
const {readFileSync} = require("node:fs");
const {join} = require("node:path");
const {initializeTestEnvironment,assertFails,assertSucceeds} = require("@firebase/rules-unit-testing");
const {ref,get,set,update,remove} = require("firebase/database");
const {initializeApp: initializeClientApp, deleteApp: deleteClientApp} = require("firebase/app");
const {getAuth: clientAuth, connectAuthEmulator, signInWithCustomToken, signOut} = require("firebase/auth");
const {getDatabase: clientDatabase, connectDatabaseEmulator, goOffline} = require("firebase/database");
const {initializeApp: initializeAdminApp, deleteApp: deleteAdminApp} = require("firebase-admin/app");
const {getAuth: adminAuth} = require("firebase-admin/auth");
const {getDatabase: adminDatabase} = require("firebase-admin/database");
const {pairDevice} = require("../pairing");
const {migrateDevice} = require("../provisioning");
let env;
const claims={awgRole:"app",awgDeviceId:"Awg-1",awgAuthVersion:"version-1"};
const notification={title:"Alert",message:"Check device",type:"warning",time:123,read:false};
const weather={humidity:70,temperature:30,weatherCode:3,source:"Open-Meteo",fetchedAt:123,latitude:14.5,longitude:121};
before(async()=>{
  if(!process.env.FIREBASE_DATABASE_EMULATOR_HOST || !process.env.FIREBASE_AUTH_EMULATOR_HOST) throw Error("Use Firebase emulators:exec; tests never target a live database.");
  env=await initializeTestEnvironment({projectId:"demo-awg-security",database:{rules:readFileSync(join(__dirname,"../../database.rules.json"),"utf8")}});
});
after(async()=>{if(env) await env.cleanup();});
beforeEach(async()=>{
  await env.clearDatabase();
  await env.withSecurityRulesDisabled(async ctx=>set(ref(ctx.database()),{
    _private:{deviceAuth:{deviceId:"Awg-1",authVersion:"version-1",enabled:true,salt:"private-salt",hash:"private-hash"}},
    AWG:{registered:true,device:{deviceId:"Awg-1",deviceName:"Original AWG"},control:{relay:false,systemEnabled:false},
      live:{temperature:25,notification:{one:notification}},weatherLocation:{latitude:14.5,longitude:121,updatedAt:123}}
  }));
});
const app=()=>env.authenticatedContext("paired-phone",claims).database();

test("public and ordinary authenticated clients cannot read or change device data",async()=>{
  for(const db of [env.unauthenticatedContext().database(),env.authenticatedContext("stranger").database()]){
    await assertFails(get(ref(db,"AWG")));
    await assertFails(get(ref(db,"_private")));
    await assertFails(set(ref(db,"AWG/control/relay"),true));
    await assertFails(remove(ref(db)));
  }
});
test("paired phone can read AWG and send only permitted boolean controls",async()=>{
  const db=app();
  await assertSucceeds(get(ref(db,"AWG")));
  await assertSucceeds(update(ref(db,"AWG/control"),{relay:true,systemEnabled:true}));
  await assertFails(set(ref(db,"AWG/control/relay"),"true"));
  await assertFails(remove(ref(db,"AWG/control/relay")));
  await assertFails(set(ref(db,"AWG/control/unknown"),true));
});
test("paired phone cannot obtain hashes, grant access, forge sensors, rewrite device metadata or delete AWG",async()=>{
  const db=app();
  await assertFails(get(ref(db,"_private/deviceAuth")));
  await assertFails(set(ref(db,"_private/deviceAuth/enabled"),true));
  await assertFails(set(ref(db,"AWG/live/temperature"),99));
  await assertFails(set(ref(db,"AWG/device/deviceSecret"),"replacement"));
  await assertFails(remove(ref(db,"AWG")));
  await assertFails(update(ref(db),{"AWG/control/relay":true,"AWG/registered":false}));
});
test("revoked versions, other devices and firmware roles cannot use app permissions",async()=>{
  for(const changed of [{awgAuthVersion:"old"},{awgDeviceId:"Awg-2"},{awgRole:"firmware"}]){
    const db=env.authenticatedContext("invalid",{...claims,...changed}).database();
    await assertFails(get(ref(db,"AWG")));
    await assertFails(set(ref(db,"AWG/control/relay"),true));
  }
  await env.withSecurityRulesDisabled(ctx=>set(ref(ctx.database(),"_private/deviceAuth/enabled"),false));
  await assertFails(set(ref(app(),"AWG/control/relay"),true));
});
test("legacy plaintext secret prevents AWG reads until administrator migration",async()=>{
  await env.withSecurityRulesDisabled(ctx=>set(ref(ctx.database(),"AWG/device/deviceSecret"),"legacy"));
  await assertFails(get(ref(app(),"AWG")));
});
test("notifications can be created, marked read, selected-deleted and cleared, but must match schema",async()=>{
  const db=app();
  await assertSucceeds(set(ref(db,"AWG/live/notification/two"),notification));
  await assertSucceeds(update(ref(db,"AWG/live/notification/one"),{read:true}));
  await assertFails(set(ref(db,"AWG/live/notification/bad"),{...notification,admin:true}));
  await assertSucceeds(update(ref(db,"AWG/live/notification"),{one:null,two:null}));
  await assertSucceeds(set(ref(db,"AWG/live/notification/one"),notification));
  await assertSucceeds(remove(ref(db,"AWG/live/notification")));
});
test("saved location and weather work with bounds and field validation",async()=>{
  const db=app();
  await assertSucceeds(set(ref(db,"AWG/weatherLocation"),{latitude:14.5,longitude:121,updatedAt:123}));
  await assertFails(set(ref(db,"AWG/weatherLocation"),{latitude:200,longitude:121,updatedAt:123}));
  await assertSucceeds(update(ref(db,"AWG/weatherApiByDate"),{"2026-10-18":weather}));
  await assertFails(set(ref(db,"AWG/weatherApiByDate/2026-10-19"),{...weather,humidity:101}));
  await assertFails(set(ref(db,"AWG/weatherApiByDate/invalid-date"),weather));
});

test("same QR credentials complete token exchange and database access, then sign-out blocks commands",{timeout:30000},async()=>{
  const device={deviceId:"Awg-1",deviceName:"Original AWG",deviceSecret:"same-original-secret"};
  await env.withSecurityRulesDisabled(ctx=>set(ref(ctx.database(),"AWG/device"),device));
  const url="https://demo-awg-security.firebaseio.com";
  // The rules REST API still asks its credential provider for a token in
  // emulator mode. This owner token is emulator-only, never a real credential.
  const admin=initializeAdminApp({projectId:"demo-awg-security",databaseURL:url,
    credential:{getAccessToken:async()=>({access_token:"owner",expires_in:3600})},
  },"token-integration");
  const phone=initializeClientApp({projectId:"demo-awg-security",apiKey:"demo-key",databaseURL:url},"phone-integration");
  const auth=clientAuth(phone);
  connectAuthEmulator(auth,`http://${process.env.FIREBASE_AUTH_EMULATOR_HOST}`,{disableWarnings:true});
  const db=clientDatabase(phone);
  const [host,port]=process.env.FIREBASE_DATABASE_EMULATOR_HOST.split(":");
  connectDatabaseEmulator(db,host,Number(port));
  try {
    const administrator=adminDatabase(admin);
    const rules=JSON.parse(readFileSync(join(__dirname,"../../database.rules.json"),"utf8"));
    await migrateDevice(administrator,device.deviceId,rules);
    const record=(await administrator.ref("_private/deviceAuth").get()).val();
    const grant=await pairDevice(device,{record,registered:true,issueToken:(uid,claims)=>adminAuth(admin).createCustomToken(uid,claims)});
    await signInWithCustomToken(auth,grant.token);
    await assertSucceeds(get(ref(db,"AWG")));
    await assertSucceeds(update(ref(db,"AWG/control"),{relay:true,systemEnabled:true}));
    await assertFails(get(ref(db,"_private/deviceAuth")));
    await signOut(auth);
    await assertFails(set(ref(db,"AWG/control/relay"),false));
  } finally {
    goOffline(db);
    adminDatabase(admin).goOffline();
    await deleteClientApp(phone);
    await deleteAdminApp(admin);
  }
});
