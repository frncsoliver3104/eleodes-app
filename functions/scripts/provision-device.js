"use strict";
const {initializeApp, applicationDefault, deleteApp} = require("firebase-admin/app");
const {getDatabase} = require("firebase-admin/database");
const {readFileSync} = require("node:fs");
const {join} = require("node:path");
const {migrateDevice} = require("../provisioning");

async function main() {
  const [projectId, databaseURL, rawId] = process.argv.slice(2);
  if (!projectId || !databaseURL || !rawId || !/^https:\/\//.test(databaseURL)) {
    throw new Error("Missing project, HTTPS database URL, or device ID.");
  }
  const deviceId = rawId.trim();
  if (!deviceId || deviceId.length > 128) {
    throw new Error("Invalid device metadata.");
  }
  const app = initializeApp({credential: applicationDefault(), projectId, databaseURL});
  const db = getDatabase();
  try {
    const expected = JSON.parse(readFileSync(join(__dirname, "../../database.rules.json"), "utf8"));
    await migrateDevice(db, deviceId, expected);
    console.log("Migration complete. The existing Device ID, Secret and QR are unchanged.");
    console.log("The secret is now stored only as a private hash. Pair the updated app once.");
  } finally {
    db.goOffline();
    await deleteApp(app);
  }
}
main().catch((error) => {
  // Error messages contain no submitted secret/token or credential objects.
  console.error("Provisioning failed:", error.code || "Check administrator setup, rules, and arguments.");
  process.exitCode = 1;
});
