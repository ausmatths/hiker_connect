import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class TestSetup {
  static Future<void> setupFirebaseForTesting() async {
    TestWidgetsFlutterBinding.ensureInitialized();

    await Firebase.initializeApp();
  }

  static void setupFirebaseAuthMocks() {
    TestWidgetsFlutterBinding.ensureInitialized();

    const channel = MethodChannel('plugins.flutter.io/firebase_auth');
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      switch (methodCall.method) {
        case 'currentUser':
          return null;
        default:
          return null;
      }
    });
  }
}