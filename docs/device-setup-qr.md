# Device setup QR

Encode a plain JSON text payload in the device QR:

```json
{"deviceId":"AWG-ESP32-0001","deviceSecret":"YOUR_DEVICE_SECRET"}
```

The app checks the entered values against the public Firebase fields
`AWG/device/deviceId` and `AWG/device/deviceSecret`. These are case-sensitive
JSON field names. The device Secret must be stored there as plaintext for this
no-Cloud-Function pairing flow. Anyone with database access can read it under
the current public rules. The example secret is a placeholder; no real
credentials are included here.

Connect > Scan device QR opens the camera. A valid payload fills both fields,
keeps the secret hidden, and checks both values against the Firebase device
record. Only successful verification enables Wi-Fi setup. Cancel or camera
denial leaves manual entry available. Invalid QR codes keep the scanner open.

Keep the QR with the device credentials; it contains the device secret.
The scanner does not log or persist the QR payload.

After adding the plugin, run flutter pub get and fully rebuild the app.
Check on a real phone: allow/deny camera, cancel, invalid QR, valid QR with
incorrect credentials, registered device with correct credentials, and scan
again after disconnecting. Verify Wi-Fi setup remains available on success.
