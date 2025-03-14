// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
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

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyD5WzgoKn3212enxcqb75cj86JNGRbQBEg',
    appId: '1:967683373829:web:3397a9795c7c410c20956c',
    messagingSenderId: '967683373829',
    projectId: 'hiker-connect',
    authDomain: 'hiker-connect.firebaseapp.com',
    databaseURL: 'https://hiker-connect-default-rtdb.firebaseio.com',
    storageBucket: 'hiker-connect.firebasestorage.app',
    measurementId: 'G-H4ZVJBQWW1',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBJndcitHYrgEHuSHcjlE48QhHnxhRRd8Q',
    appId: '1:967683373829:android:c25cd36567a50f7020956c',
    messagingSenderId: '967683373829',
    projectId: 'hiker-connect',
    databaseURL: 'https://hiker-connect-default-rtdb.firebaseio.com',
    storageBucket: 'hiker-connect.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyC4nCLpr4TR7qZXUzTdGURhc4pHeVh7tPQ',
    appId: '1:967683373829:ios:6c3b56c7d7bc735e20956c',
    messagingSenderId: '967683373829',
    projectId: 'hiker-connect',
    databaseURL: 'https://hiker-connect-default-rtdb.firebaseio.com',
    storageBucket: 'hiker-connect.firebasestorage.app',
    androidClientId: '967683373829-4k5ut5k12o375qc2da2pr47jj9dufk64.apps.googleusercontent.com',
    iosClientId: '967683373829-etonh967dnlo7mrmtha7qvbl78u9a3s9.apps.googleusercontent.com',
    iosBundleId: 'com.ausmatths.hikerConnect',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyC4nCLpr4TR7qZXUzTdGURhc4pHeVh7tPQ',
    appId: '1:967683373829:ios:c3e05838af84240820956c',
    messagingSenderId: '967683373829',
    projectId: 'hiker-connect',
    databaseURL: 'https://hiker-connect-default-rtdb.firebaseio.com',
    storageBucket: 'hiker-connect.firebasestorage.app',
    androidClientId: '967683373829-4k5ut5k12o375qc2da2pr47jj9dufk64.apps.googleusercontent.com',
    iosClientId: '967683373829-uiu2p09vi3j6er3cobi7r354fbm5pird.apps.googleusercontent.com',
    iosBundleId: 'com.example.hikerConnect',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyD5WzgoKn3212enxcqb75cj86JNGRbQBEg',
    appId: '1:967683373829:web:839aaba95ca296af20956c',
    messagingSenderId: '967683373829',
    projectId: 'hiker-connect',
    authDomain: 'hiker-connect.firebaseapp.com',
    databaseURL: 'https://hiker-connect-default-rtdb.firebaseio.com',
    storageBucket: 'hiker-connect.firebasestorage.app',
    measurementId: 'G-85ZZM444KG',
  );

}