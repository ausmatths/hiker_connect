import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

// Fake implementation of UserCredential for mocking
class FakeUserCredential extends Fake implements UserCredential {
  @override
  User get user => FakeUser();
}

// Fake implementation of User for mocking
class FakeUser extends Fake implements User {
  @override
  String get uid => 'fakeUid';

  @override
  String get email => 'fake@example.com';

  @override
  String? get displayName => 'Fake User';
}

// Define AuthenticationService (assuming this is your service class)
class AuthenticationService {
  FirebaseAuth firebaseAuth = FirebaseAuth.instance;

  Future<User?> signUpUser(String email, String password) async {
    try {
      final userCredential = await firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      print('Sign-up failed: ${e.code}');
      return null;
    }
  }
}

void main() {
  group('AuthenticationService', () {
    late AuthenticationService authService;
    late MockFirebaseAuth mockFirebaseAuth;

    setUp(() {
      mockFirebaseAuth = MockFirebaseAuth();
      authService = AuthenticationService();
      authService.firebaseAuth = mockFirebaseAuth;
    });

    test('signUpUser returns a User if signup is successful', () async {
      when(mockFirebaseAuth.createUserWithEmailAndPassword(
        email: any(named: 'email'),
        password: any(named: 'password'),
      )).thenAnswer((_) async => FakeUserCredential());

      // Call the signUpUser method
      final result = await authService.signUpUser('test@example.com', 'password');

      // Verify the result is a User object
      expect(result, isA<User>());
      expect(result?.email, 'fake@example.com');
      expect(result?.uid, 'fakeUid');
    });

    test('signUpUser returns null if signup fails', () async {
      // Mock the createUserWithEmailAndPassword method to throw an exception
      when(mockFirebaseAuth.createUserWithEmailAndPassword(
        email: any(named: 'email'),
        password: any(named: 'password'),
      )).thenThrow(FirebaseAuthException(code: 'error'));

      // Call the signUpUser method
      final result = await authService.signUpUser('test@example.com', 'password');

      // Verify the result is null
      expect(result, isNull);
    });
  });
}