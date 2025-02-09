// test/setup/setup.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:firebase_auth/firebase_auth.dart';

@GenerateMocks([FirebaseAuth])
class TestFirebaseInitializer {
  static bool _initialized = false;

  static Future<void> setupFirebaseForTesting() async {
    if (_initialized) return;

    TestWidgetsFlutterBinding.ensureInitialized();

    try {
      await Firebase.initializeApp();
      _initialized = true;
    } catch (e) {
      print('Firebase mock initialization failed: $e');
    }
  }
}

// Make the setup function accessible
Future<void> setupFirebaseForTesting() async {
  await TestFirebaseInitializer.setupFirebaseForTesting();
}
