import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiker_connect/models/user_model.dart';
import 'package:hiker_connect/providers/events_provider.dart';
import 'package:mockito/mockito.dart';
import 'package:hiker_connect/services/firebase_auth.dart';
import 'package:hiker_connect/screens/auth//login_screen.dart';
import 'package:hiker_connect/services/google_events_service.dart';
import 'package:hiker_connect/providers/auth_provider.dart';
import 'package:provider/provider.dart';

class MockAuthService extends Mock implements AuthService {}
class MockGoogleEventsService extends Mock implements GoogleEventsService {}
class MockFirebaseAuth extends Mock implements FirebaseAuth {}

void main() {
  late MockAuthService mockAuthService;
  late MockGoogleEventsService mockGoogleEventsService;

  setUp(() {
    mockAuthService = MockAuthService();
    mockGoogleEventsService = MockGoogleEventsService();

  });

  Widget createTestWidget() {
    return MaterialApp(
      home: HikerAuthProvider( // Use your custom provider
        authService: mockAuthService,
        child: MultiProvider(
          providers: [
            Provider<GoogleEventsService>.value(value: mockGoogleEventsService),
          ],
          child: const LoginScreen(),
        ),
        ),
    );
  }

  testWidgets('LoginScreen renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(createTestWidget());

    expect(find.text('Login'), findsNWidgets(2));
    expect(find.text('Hiker Connect'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.text('Forgot Password?'), findsOneWidget);
    expect(find.text('Sign in with Google'), findsOneWidget);
    expect(find.text("Don't have an account?"), findsOneWidget);
    expect(find.text('Sign Up'), findsOneWidget);
  });

  testWidgets('Form validation shows errors for invalid input', (WidgetTester tester) async {
    await tester.pumpWidget(createTestWidget());

    // Tap the login button without entering any input
    await tester.tap(find.byKey(const Key('loginButton')));
    await tester.pump();

    // Verify error messages
    expect(find.text('Please enter your email'), findsOneWidget);
    expect(find.text('Please enter your password'), findsOneWidget);

    // Enter invalid email
    await tester.enterText(find.byType(TextFormField).first, 'invalid-email');
    await tester.tap(find.byKey(const Key('loginButton')));
    await tester.pump();

    // Verify error message for invalid email
    expect(find.text('Please enter a valid email'), findsOneWidget);
  });

  testWidgets('Login with valid email and password', (WidgetTester tester) async {
    when(mockAuthService.signInWithEmailAndPassword(
      email: 'test@example.com',
      password: 'password123',
    )).thenAnswer((_) async => UserModel(
      uid: 'test-uid',
      email: 'test@example.com',
      displayName: 'Test User',
      bio: 'Test bio',
      photoUrl: null,
      location: UserLocation(
        geoPoint: GeoPoint(37.7749, -122.4194),
        address: '123 Test St',
      ),
      createdAt: DateTime.now(),
      lastActive: DateTime.now(),
      following: ['user1'],
      followers: ['user2'],
      medicalConditions: ['Asthma'],
      medications: ['Inhaler'],
      bloodType: 'A+',
      emergencyContacts: [
        EmergencyContact(
          name: 'Test Contact',
          relationship: 'Friend',
          phoneNumber: '+1234567890',
        ),
      ],
      interests: [],
      socialLinks: {},
    ));

    await tester.pumpWidget(createTestWidget());

    // Enter valid email and password
    await tester.enterText(find.byType(TextFormField).first, 'test@example.com');
    await tester.enterText(find.byType(TextFormField).last, 'password123');
    await tester.tap(find.text('Login'));
    await tester.pump();

    // Verify that the login method was called
    verify(mockAuthService.signInWithEmailAndPassword(
      email: 'test@example.com',
      password: 'password123',
    )).called(1);
  });

  testWidgets('Sign in with Google', (WidgetTester tester) async {
    when(mockAuthService.signInWithGoogle()).thenAnswer((_) async => UserModel(
      uid: 'test-uid',
      email: 'test@example.com',
      displayName: 'Test User',
      bio: 'Test bio',
      photoUrl: null,
      location: UserLocation(
        geoPoint: const GeoPoint(0, 0),
        address: '123 Test St',
      ),
      createdAt: DateTime.now(),
      lastActive: DateTime.now(),
      following: ['user1'],
      followers: ['user2'],
      medicalConditions: ['Asthma'],
      medications: ['Inhaler'],
      bloodType: 'A+',
      emergencyContacts: [
        EmergencyContact(
          name: 'Test Contact',
          relationship: 'Friend',
          phoneNumber: '+1234567890',
        ),
      ],
      interests: [],
      socialLinks: {},
    ));

    await tester.pumpWidget(createTestWidget());

    // Tap the Google sign-in button
    await tester.tap(find.text('Sign in with Google'));
    await tester.pump();

    // Verify that the Google sign-in method was called
    verify(mockAuthService.signInWithGoogle()).called(1);
  });

  testWidgets('Error message is shown when login fails', (WidgetTester tester) async {
    when(mockAuthService.signInWithEmailAndPassword(
      email: 'test@example.com',
      password: 'wrongpassword',
    )).thenThrow(FirebaseAuthException(code: 'wrong-password'));

    await tester.pumpWidget(createTestWidget());

    // Enter valid email and wrong password
    await tester.enterText(find.byType(TextFormField).first, 'test@example.com');
    await tester.enterText(find.byType(TextFormField).last, 'wrongpassword');
    await tester.tap(find.text('Login'));
    await tester.pump();

    // Verify error message
    expect(find.text('Incorrect password. Please try again.'), findsOneWidget);
  });

  testWidgets('Forgot password sends reset email', (WidgetTester tester) async {
    when(mockAuthService.resetPassword('test@example.com')).thenAnswer((_) async => true);

    await tester.pumpWidget(createTestWidget());

    // Enter email
    await tester.enterText(find.byType(TextFormField).first, 'test@example.com');
    await tester.tap(find.text('Forgot Password?'));
    await tester.pump();

    // Verify that the reset password method was called
    verify(mockAuthService.resetPassword('test@example.com')).called(1);
  });

  testWidgets('Network error message is shown', (WidgetTester tester) async {
    when(mockAuthService.signInWithEmailAndPassword(
      email: 'test@example.com',
      password: 'password123',
    )).thenThrow(FirebaseAuthException(code: 'network-request-failed'));

    await tester.pumpWidget(createTestWidget());

    // Enter valid email and password
    await tester.enterText(find.byType(TextFormField).first, 'test@example.com');
    await tester.enterText(find.byType(TextFormField).last, 'password123');
    await tester.tap(find.text('Login'));
    await tester.pump();

    // Verify network error message
    expect(find.text('Network error. Please check your connection and try again.'), findsOneWidget);
  });
}