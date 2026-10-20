"use strict";
const {scrypt, timingSafeEqual, randomBytes} = require("node:crypto");
const {promisify} = require("node:util");
const derive = promisify(scrypt);

async function hashSecret(secret, salt) {
  return (await derive(secret, salt, 64)).toString("hex");
}

function nextAttempt(current, now, limit, windowMs) {
  const active = current && Number.isFinite(current.startedAt) &&
    now - current.startedAt < windowMs;
  const count = active && Number.isInteger(current.count) ? current.count : 0;
  if (count >= limit) return undefined;
  return {startedAt: active ? current.startedAt : now, count: count + 1};
}

async function pairDevice(input, {record, registered, issueToken}) {
  if (!input || typeof input.deviceId !== "string" ||
      typeof input.deviceSecret !== "string" ||
      input.deviceId.length > 128 || input.deviceSecret.length > 512) return null;
  if (!record || record.enabled !== true ||
      (registered !== true && registered !== "true") ||
      typeof record.deviceId !== "string" || !record.deviceId ||
      typeof record.deviceName !== "string" || !record.deviceName ||
      typeof record.authVersion !== "string" || !record.authVersion ||
      typeof record.salt !== "string" || !/^[a-f0-9]{64}$/.test(record.salt) ||
      typeof record.hash !== "string" || !/^[a-f0-9]{128}$/.test(record.hash)) return null;
  const candidate = await hashSecret(input.deviceSecret.trim(), record.salt);
  const matches = timingSafeEqual(Buffer.from(candidate, "hex"), Buffer.from(record.hash, "hex"));
  if (!matches || input.deviceId.trim().toUpperCase() !== record.deviceId.trim().toUpperCase()) return null;
  const token = await issueToken(`awg-app-${randomBytes(16).toString("hex")}`, {
    awgRole: "app", awgDeviceId: record.deviceId, awgAuthVersion: record.authVersion,
  });
  return {deviceId: record.deviceId, deviceName: record.deviceName, token};
}

module.exports = {hashSecret, nextAttempt, pairDevice};
