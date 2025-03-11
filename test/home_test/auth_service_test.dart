// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter_test/flutter_test.dart';
// import 'package:mockito/annotations.dart';
// import 'package:mockito/mockito.dart';
//
// // Generate mock classes
// @GenerateMocks([FirebaseAuth])
// import 'auth_service_test.mocks.dart';
//
// // Fake implementation of UserCredential for mocking
// class FakeUserCredential implements UserCredential {
//   @override
//   User? get user => FakeUser();
//
//   // Implement other required methods/properties
//   @override
//   dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
// }
//
// // Fake implementation of User for mocking
// class FakeUser implements User {
//   @override
//   String get uid => 'fakeUid';
//
//   @override
//   String get email => 'fake@example.com';
//
//   @override
//   String? get displayName => 'Fake User';
//
//   // Implement other required methods/properties
//   @override
//   dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
// }
//
// // Define AuthenticationService (assuming this is your service class)
// class AuthenticationService {
//   FirebaseAuth firebaseAuth = FirebaseAuth.instance;
//
//   Future<User?> signUpUser(String email, String password) async {
//     try {
//       final userCredential = await firebaseAuth.createUserWithEmailAndPassword(
//         email: email,
//         password: password,
//       );
//       return userCredential.user;
//     } on FirebaseAuthException catch (e) {
//       print('Sign-up failed: ${e.code}');
//       return null;
//     }
//   }
// }
//
// void main() {
//   group('AuthenticationService', () {
//     late AuthenticationService authService;
//     late MockFirebaseAuth mockFirebaseAuth;
//
//     setUp(() {
//       mockFirebaseAuth = MockFirebaseAuth();
//       authService = AuthenticationService();
//       authService.firebaseAuth = mockFirebaseAuth;
//     });
//
//     test('signUpUser returns a User if signup is successful', () async {
//       // Use the properly typed return value
//       final fakeCredential = FakeUserCredential();
//
//       when(mockFirebaseAuth.createUserWithEmailAndPassword(
//         email: anyNamed('email'),
//         password: anyNamed('password'),
//       )).thenAnswer((_) async => fakeCredential);
//
//       // Call the signUpUser method
//       final result = await authService.signUpUser('test@example.com', 'password');
//
//       // Verify the result is a User object
//       expect(result, isA<User>());
//       expect(result?.email, 'fake@example.com');
//       expect(result?.uid, 'fakeUid');
//     });
//
//     test('signUpUser returns null if signup fails', () async {
//       // Mock the createUserWithEmailAndPassword method to throw an exception
//       when(mockFirebaseAuth.createUserWithEmailAndPassword(
//         email: anyNamed('email'),
//         password: anyNamed('password'),
//       )).thenThrow(FirebaseAuthException(code: 'error'));
//
//       // Call the signUpUser method
//       final result = await authService.signUpUser('test@example.com', 'password');
//
//       // Verify the result is null
//       expect(result, isNull);
//     });
//   });
// }