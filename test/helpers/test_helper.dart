import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';

Future<void> setupFirebaseForTesting() async {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Create the method channel
  const MethodChannel channel = MethodChannel(
    'plugins.flutter.io/firebase_core',
  );

  // Set up the mock handler
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
    channel,
        (MethodCall methodCall) async {
      switch (methodCall.method) {
        case 'Firebase#initializeCore':
          return [
            {
              'name': '[DEFAULT]',
              'options': {
                'apiKey': '123',
                'appId': '123',
                'messagingSenderId': '123',
                'projectId': '123',
                'storageBucket': 'default-bucket',
              },
              'pluginConstants': {},
            }
          ];

        case 'Firebase#initializeApp':
          return {
            'name': '[DEFAULT]',
            'options': {
              'apiKey': '123',
              'appId': '123',
              'messagingSenderId': '123',
              'projectId': '123',
              'storageBucket': 'default-bucket',
            },
            'pluginConstants': {},
          };

        default:
          return null;
      }
    },
  );

  // Initialize Firebase
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: '123',
      appId: '123',
      messagingSenderId: '123',
      projectId: '123',
      storageBucket: 'default-bucket',
    ),
  );
}