import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';

Future<void> setupFirebaseCoreMocks() async {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Register FirebasePlatform instance
  final platform = FirebasePlatform.instance;

  // Mock method channels
  const channel = MethodChannel('plugins.flutter.io/firebase_core');
  channel.setMockMethodCallHandler((MethodCall methodCall) async {
    switch (methodCall.method) {
      case 'Firebase#initializeCore':
        return [
          {
            'name': '[DEFAULT]',
            'options': {
              'apiKey': 'mock-api-key',
              'appId': 'mock-app-id',
              'messagingSenderId': 'mock-sender-id',
              'projectId': 'mock-project',
              'storageBucket': 'mock-bucket',
            },
            'pluginConstants': {},
          }
        ];
      case 'Firebase#initializeApp':
        return {
          'name': '[DEFAULT]',
          'options': {
            'apiKey': 'mock-api-key',
            'appId': 'mock-app-id',
            'messagingSenderId': 'mock-sender-id',
            'projectId': 'mock-project',
            'storageBucket': 'mock-bucket',
          },
          'pluginConstants': {},
        };
      default:
        return null;
    }
  });
}