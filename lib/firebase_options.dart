import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default FirebaseOptions
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // ================= WEB =================
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyB3LV5Npb3iz8C2KrX2bz8tK_6oQqy1IMw',
    appId: '1:971924610923:web:f94c41cc01208c0d0ef62e',
    messagingSenderId: '971924610923',
    projectId: 'awg-iot-system',
    authDomain: 'awg-iot-system.firebaseapp.com',
    storageBucket: 'awg-iot-system.firebasestorage.app',
    measurementId: 'G-SRY4XVNXDJ',

    databaseURL:
        'https://awg-iot-system-default-rtdb.asia-southeast1.firebasedatabase.app',
  );

  // ================= ANDROID =================

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDITKeS9Y1c6SxekzAezAiNwbdeTBiS3OM',
    appId: '1:971924610923:android:72537ae0c42ddaa30ef62e',
    messagingSenderId: '971924610923',
    projectId: 'awg-iot-system',
    databaseURL:
        'https://awg-iot-system-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'awg-iot-system.firebasestorage.app',
  );
  // ================= IOS =================

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAJxitiLmckWCTL3f2Fwuy7sN5o1lKgcYg',
    appId: '1:971924610923:ios:09402fde83befa380ef62e',
    messagingSenderId: '971924610923',
    projectId: 'awg-iot-system',
    databaseURL:
        'https://awg-iot-system-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'awg-iot-system.firebasestorage.app',
    iosBundleId: 'com.example.myApp',
  );
  // ================= MACOS =================
  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAJxitiLmckWCTL3f2Fwuy7sN5o1lKgcYg',
    appId: '1:971924610923:ios:09402fde83befa380ef62e',
    messagingSenderId: '971924610923',
    projectId: 'awg-iot-system',
    storageBucket: 'awg-iot-system.firebasestorage.app',
    iosBundleId: 'com.example.myApp',

    databaseURL:
        'https://awg-iot-system-default-rtdb.asia-southeast1.firebasedatabase.app',
  );

  // ================= WINDOWS =================
  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyB3LV5Npb3iz8C2KrX2bz8tK_6oQqy1IMw',
    appId: '1:971924610923:web:cd29810f9ae9321a0ef62e',
    messagingSenderId: '971924610923',
    projectId: 'awg-iot-system',
    authDomain: 'awg-iot-system.firebaseapp.com',
    storageBucket: 'awg-iot-system.firebasestorage.app',
    measurementId: 'G-35R2V0TNK7',

    databaseURL:
        'https://awg-iot-system-default-rtdb.asia-southeast1.firebasedatabase.app',
  );
}
