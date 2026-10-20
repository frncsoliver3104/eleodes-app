"use strict";
const {onRequest} = require("firebase-functions/v2/https");
const {initializeApp} = require("firebase-admin/app");
const {getDatabase} = require("firebase-admin/database");
const {getAuth} = require("firebase-admin/auth");
const {createHash} = require("node:crypto");
const {nextAttempt, pairDevice} = require("./pairing");
initializeApp();

exports.pairAwgDevice = onRequest({
  region: "asia-southeast1", cors: true, maxInstances: 3,
  concurrency: 8, timeoutSeconds: 30, memory: "256MiB",
}, async (req, res) => {
  res.set("Cache-Control", "no-store");
  if (req.method !== "POST") return res.status(405).json({error: "Use POST."});
  if (!req.is("application/json") || !req.body ||
      typeof req.body.deviceId !== "string" ||
      typeof req.body.deviceSecret !== "string" ||
      !req.body.deviceId.trim() || req.body.deviceId.length > 128 ||
      !req.body.deviceSecret.trim() || req.body.deviceSecret.length > 512 ||
      Number(req.headers["content-length"] || 0) > 4096) {
    return res.status(400).json({error: "Invalid pairing request."});
  }
  try {
    const db = getDatabase();
    const now = Date.now();
    // Global limit bounds distributed guessing; 256 hashed IP buckets bound
    // storage. Bucket collisions may conservatively throttle unrelated clients.
    const bucket = createHash("sha256").update(req.ip || "unknown").digest("hex").slice(0, 2);
    const limits = db.ref("_private/pairLimits");
    const global = await limits.child("global").transaction(
      (value) => nextAttempt(value, now, 200, 60 * 60 * 1000));
    if (!global.committed) return res.status(429).json({error: "Try again later."});
    const ip = await limits.child(`buckets/${bucket}`).transaction(
      (value) => nextAttempt(value, now, 20, 15 * 60 * 1000));
    if (!ip.committed) return res.status(429).json({error: "Try again later."});
    const [credentials, registration] = await Promise.all([
      db.ref("_private/deviceAuth").get(), db.ref("AWG/registered").get(),
    ]);
    const result = await pairDevice(req.body, {
      record: credentials.val(), registered: registration.val(),
      issueToken: (uid, claims) => getAuth().createCustomToken(uid, claims),
    });
    if (!result) return res.status(401).json({error: "Invalid device credentials."});
    return res.status(200).json(result);
  } catch (_) {
    // Never log request bodies, credentials, hashes, or returned tokens.
    return res.status(503).json({error: "Device verification unavailable."});
  }
});
