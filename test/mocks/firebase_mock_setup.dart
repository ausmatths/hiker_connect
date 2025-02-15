import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> setupFirebaseTestMocks() async {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Set up method channel mock
  const channel = MethodChannel('plugins.flutter.io/firebase_core');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
    channel,
        (MethodCall methodCall) async {
      if (methodCall.method == 'Firebase#initializeCore') {
        return [
          {
            'name': '[DEFAULT]',
            'options': {
              'apiKey': 'test-api-key',
              'appId': 'test-app-id',
              'messagingSenderId': 'test-sender-id',
              'projectId': 'test-project',
            },
            'pluginConstants': {},
          }
        ];
      }

      if (methodCall.method == 'Firebase#initializeApp') {
        return {
          'name': '[DEFAULT]',
          'options': {
            'apiKey': 'test-api-key',
            'appId': 'test-app-id',
            'messagingSenderId': 'test-sender-id',
            'projectId': 'test-project',
          },
        };
      }

      return null;
    },
  );
}