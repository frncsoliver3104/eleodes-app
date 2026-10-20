"use strict";
const {randomBytes} = require("node:crypto");
const {hashSecret} = require("./pairing");
const {isDeepStrictEqual} = require("node:util");

// Keep the existing ID, name, secret and QR. Only move secret verification out
// of client-readable data. No returned update contains the plaintext secret.
async function prepareMigration(device, existing) {
  if (!device || typeof device.deviceId !== "string" || !device.deviceId.trim() ||
      device.deviceId.length > 128) throw new Error("Missing device ID.");
  const deviceId = device.deviceId;
  const deviceName = typeof device.deviceName === "string" && device.deviceName.trim()
    ? device.deviceName : "AWG Machine";
  let record;
  if (typeof device.deviceSecret === "string" && device.deviceSecret.trim()) {
    if (device.deviceSecret.trim().length > 512) throw new Error("Invalid secret length.");
    const salt = randomBytes(32).toString("hex");
    record = {deviceId, deviceName, salt,
      hash: await hashSecret(device.deviceSecret.trim(), salt),
      authVersion: randomBytes(16).toString("hex"), enabled: true};
  } else if (existing && existing.deviceId === deviceId &&
      typeof existing.hash === "string" && /^[a-f0-9]{128}$/.test(existing.hash) &&
      typeof existing.salt === "string" && /^[a-f0-9]{64}$/.test(existing.salt) &&
      typeof existing.authVersion === "string" && existing.authVersion &&
      typeof existing.enabled === "boolean") {
    // Re-running migration neither changes credentials nor re-enables a device.
    record = {...existing, deviceName};
  } else {
    throw new Error("Existing secret not found; no replacement will be generated.");
  }
  return {"_private/deviceAuth": record, "AWG/device/deviceSecret": null};
}
async function migrateDevice(db, expectedId, expectedRules) {
  const deployed = await db.getRulesJSON();
  if (!isDeepStrictEqual(deployed.rules, expectedRules.rules)) {
    throw new Error("Publish this project's restricted rules before migration.");
  }
  const root = db.ref();
  const [deviceSnapshot, privateSnapshot] = await Promise.all([
    root.child("AWG/device").get(), root.child("_private/deviceAuth").get(),
  ]);
  const device = deviceSnapshot.val();
  if (!device || device.deviceId !== expectedId) {
    throw new Error("Device ID differs from the existing AWG; no data changed.");
  }
  await root.update(await prepareMigration(device, privateSnapshot.val()));
}
module.exports = {prepareMigration, migrateDevice};
