"use strict";
const {test} = require("node:test");
const assert = require("node:assert/strict");
const {hashSecret, pairDevice, nextAttempt} = require("../pairing");
const {prepareMigration, migrateDevice} = require("../provisioning");

const device = {deviceId: "Awg-1", deviceName: "Original AWG", deviceSecret: "same-secret-123"};

test("administrator migration refuses public rules before reading or changing data",async()=>{
  await assert.rejects(migrateDevice({
    getRulesJSON:async()=>({rules:{".read":true,".write":true}}),
    ref:()=>assert.fail("Public rules must prevent migration"),
  },device.deviceId,{rules:{".read":false,".write":false}}));
});

test("migration keeps the existing ID/secret/QR and removes plaintext atomically", async () => {
  const updates = await prepareMigration(device, null);
  assert.deepEqual(Object.keys(updates).sort(), ["AWG/device/deviceSecret", "_private/deviceAuth"]);
  assert.equal(updates["AWG/device/deviceSecret"], null);
  const record = updates["_private/deviceAuth"];
  assert.equal(record.deviceId, device.deviceId);
  assert.equal(record.deviceName, device.deviceName);
  assert.equal(JSON.stringify(updates).includes(device.deviceSecret), false);
  let issued;
  const result = await pairDevice({deviceId: " awg-1 ", deviceSecret: device.deviceSecret}, {
    record, registered: true,
    issueToken: async (uid, claims) => { issued = {uid, claims}; return "signed-token"; },
  });
  assert.deepEqual(result, {deviceId: device.deviceId, deviceName: device.deviceName, token: "signed-token"});
  assert.match(issued.uid, /^awg-app-[a-f0-9]{32}$/);
  assert.deepEqual(issued.claims, {awgRole:"app", awgDeviceId:device.deviceId, awgAuthVersion:record.authVersion});
});

test("rerunning migration retains credentials and disabled state", async () => {
  const initial = (await prepareMigration(device, null))["_private/deviceAuth"];
  initial.enabled = false;
  const {deviceSecret, ...publicDevice} = device;
  const repeat = await prepareMigration(publicDevice, initial);
  assert.deepEqual(repeat["_private/deviceAuth"], initial);
  await assert.rejects(prepareMigration(publicDevice, null));
});

test("wrong ID/secret, malformed input, unregistered and disabled devices never issue tokens", async () => {
  const record = (await prepareMigration(device, null))["_private/deviceAuth"];
  const cases = [
    {input:{deviceId:"other",deviceSecret:device.deviceSecret}},
    {input:{deviceId:device.deviceId,deviceSecret:"incorrect"}},
    {input:{deviceId:device.deviceId,deviceSecret:device.deviceSecret},registered:false},
    {input:{deviceId:device.deviceId,deviceSecret:device.deviceSecret},record:{...record,enabled:false}},
    {input:{deviceId:device.deviceId,deviceSecret:device.deviceSecret},record:{...record,hash:"invalid"}},
    {input:null}, {input:{deviceId:{},deviceSecret:"a"}},
    {input:{deviceId:device.deviceId,deviceSecret:"x".repeat(513)}},
  ];
  for (const value of cases) {
    const result = await pairDevice(value.input, {
      record: value.record ?? record,
      registered: value.registered ?? true,
      issueToken: async () => { assert.fail("Invalid credentials must not mint tokens"); },
    });
    assert.equal(result, null);
  }
});

test("hash is salted and server failures cannot return partial grants", async () => {
  const first = await hashSecret(device.deviceSecret, "a".repeat(64));
  const second = await hashSecret(device.deviceSecret, "b".repeat(64));
  assert.notEqual(first, second);
  const record = (await prepareMigration(device, null))["_private/deviceAuth"];
  await assert.rejects(pairDevice(device, {record,registered:true,issueToken:async () => {throw Error("signer unavailable");}}));
});

test("rate limiter blocks excess attempts and resets only after the window", () => {
  let value;
  for(let i=0;i<20;i++) value=nextAttempt(value,1000,20,900000);
  assert.equal(value.count,20);
  assert.equal(nextAttempt(value,1001,20,900000),undefined);
  assert.equal(nextAttempt(value,999,20,900000),undefined);
  assert.equal(nextAttempt(value,900999,20,900000),undefined);
  assert.deepEqual(nextAttempt(value,901000,20,900000),{startedAt:901000,count:1});
});
