import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> setupFirebaseForTesting() async {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Register all MethodChannel handlers
  const channelFirebaseCore = MethodChannel('plugins.flutter.io/firebase_core');
  const channelFirebaseAuth = MethodChannel('plugins.flutter.io/firebase_auth');
  final mockFirebaseCoreResponses = <String, dynamic>{
    'Firebase#initializeCore': [
      {
        'name': '[DEFAULT]',
        'options': {
          'apiKey': 'test-api-key',
          'appId': 'test-app-id',
          'messagingSenderId': 'test-sender-id',
          'projectId': 'test-project',
        },
      }
    ],
    'Firebase#initializeApp': {
      'name': '[DEFAULT]',
      'options': {
        'apiKey': 'test-api-key',
        'appId': 'test-app-id',
        'messagingSenderId': 'test-sender-id',
        'projectId': 'test-project',
      },
    },
  };

  channelFirebaseCore.setMockMethodCallHandler((MethodCall call) async {
    return mockFirebaseCoreResponses[call.method];
  });

  channelFirebaseAuth.setMockMethodCallHandler((MethodCall call) async {
    switch (call.method) {
      case 'Auth#registerIdTokenListener':
      case 'Auth#registerAuthStateListener':
        return {'name': '[DEFAULT]'};
      default:
        return null;
    }
  });

  try {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'test-api-key',
        appId: 'test-app-id',
        messagingSenderId: 'test-sender-id',
        projectId: 'test-project',
      ),
    );
  } catch (e) {
    print('Firebase initialization error: $e');
  }
}