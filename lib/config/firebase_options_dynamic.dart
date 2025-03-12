import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:hiker_connect/utils/env_config.dart';
import 'package:hiker_connect/firebase_options.dart'; // Import the default options as fallback

class DynamicFirebaseOptions {
  // Private constructor to prevent instantiation
  DynamicFirebaseOptions._();

  // Get the appropriate FirebaseOptions for the current platform
  static FirebaseOptions get currentPlatform {
    // Check if we have the required environment variables
    if (!_hasRequiredFirebaseConfig()) {
      // Fall back to the generated static options
      return DefaultFirebaseOptions.currentPlatform;
    }

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
      default:
      // Fall back to the generated static options
        return DefaultFirebaseOptions.currentPlatform;
    }
  }

  // Check if we have all required Firebase environment variables
  static bool _hasRequiredFirebaseConfig() {
    return EnvConfig.hasKey('FIREBASE_API_KEY') &&
        EnvConfig.hasKey('FIREBASE_APP_ID') &&
        EnvConfig.hasKey('FIREBASE_PROJECT_ID') &&
        EnvConfig.hasKey('FIREBASE_MESSAGING_SENDER_ID') &&
        EnvConfig.hasKey('FIREBASE_STORAGE_BUCKET');
  }

  static FirebaseOptions get web => FirebaseOptions(
    apiKey: EnvConfig.firebaseApiKey,
    appId: EnvConfig.firebaseAppId,
    messagingSenderId: EnvConfig.firebaseMessagingSenderId,
    projectId: EnvConfig.firebaseProjectId,
    authDomain: EnvConfig.firebaseAuthDomain,
    storageBucket: EnvConfig.firebaseStorageBucket,
    measurementId: EnvConfig.firebaseMeasurementId,
  );

  static FirebaseOptions get android => FirebaseOptions(
    apiKey: EnvConfig.firebaseApiKey,
    appId: EnvConfig.firebaseAppId,
    messagingSenderId: EnvConfig.firebaseMessagingSenderId,
    projectId: EnvConfig.firebaseProjectId,
    storageBucket: EnvConfig.firebaseStorageBucket,
  );

  static FirebaseOptions get ios => FirebaseOptions(
    apiKey: EnvConfig.firebaseApiKey,
    appId: EnvConfig.firebaseAppId,
    messagingSenderId: EnvConfig.firebaseMessagingSenderId,
    projectId: EnvConfig.firebaseProjectId,
    storageBucket: EnvConfig.firebaseStorageBucket,
    iosClientId: EnvConfig.firebaseIosClientId,
    iosBundleId: EnvConfig.firebaseIosBundleId,
  );

  static FirebaseOptions get macos => FirebaseOptions(
    apiKey: EnvConfig.firebaseApiKey,
    appId: EnvConfig.firebaseAppId,
    messagingSenderId: EnvConfig.firebaseMessagingSenderId,
    projectId: EnvConfig.firebaseProjectId,
    storageBucket: EnvConfig.firebaseStorageBucket,
    iosClientId: EnvConfig.firebaseIosClientId,
    iosBundleId: EnvConfig.firebaseIosBundleId,
  );
}