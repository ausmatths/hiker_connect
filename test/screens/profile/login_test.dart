import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiker_connect/models/user_model.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:hiker_connect/services/firebase_auth.dart';
import 'package:hiker_connect/screens/auth/login_screen.dart';
import 'package:hiker_connect/services/google_events_service.dart';
import 'package:hiker_connect/providers/auth_provider.dart';
import 'package:provider/provider.dart';

// Import the generated mocks
import 'login_test.mocks.dart';

// Mock classes
@GenerateMocks([AuthService, GoogleEventsService])
void main() {
  late MockAuthService mockAuthService;
  late MockGoogleEventsService mockGoogleEventsService;

  // Sample user model for testing
  UserModel createTestUser() {
    return UserModel(
      uid: 'test-uid',
      email: 'test@example.com',
      displayName: 'Test User',
      bio: 'Test bio',
      photoUrl: null,
      location: UserLocation(
        geoPoint: const GeoPoint(37.7749, -122.4194),
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
    );
  }

  setUp(() {
    mockAuthService = MockAuthService();
    mockGoogleEventsService = MockGoogleEventsService();

    // Set up basic mock responses - we'll use more specific ones in each test
    when(mockAuthService.currentUser).thenReturn(null);
  });

  Widget createTestWidget() {
    return MediaQuery(
      data: const MediaQueryData(size: Size(1080, 1920)),
      child: MaterialApp(
        home: HikerAuthProvider(
          authService: mockAuthService,
          child: MultiProvider(
            providers: [
              Provider<GoogleEventsService>.value(value: mockGoogleEventsService),
            ],
            child: const LoginScreen(),
          ),
        ),
      ),
    );
  }

  testWidgets('LoginScreen renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle(); // Wait for any animations to complete

    expect(find.text('Hiker Connect'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2)); // Email and password fields
    expect(find.text('Forgot Password?'), findsOneWidget);
    expect(find.text('Sign in with Google'), findsOneWidget);
    expect(find.text("Don't have an account?"), findsOneWidget);
  });

  testWidgets('Password visibility toggle works', (WidgetTester tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    // Find visibility toggle button - initially password is hidden
    expect(find.byIcon(Icons.visibility_off), findsOneWidget);

    // Tap visibility toggle to show password
    await tester.tap(find.byIcon(Icons.visibility_off));
    await tester.pump();

    // Verify icon changed to show password is visible
    expect(find.byIcon(Icons.visibility), findsOneWidget);
    expect(find.byIcon(Icons.visibility_off), findsNothing);

    // Tap again to hide password
    await tester.tap(find.byIcon(Icons.visibility));
    await tester.pump();

    // Verify icon changed back
    expect(find.byIcon(Icons.visibility_off), findsOneWidget);
    expect(find.byIcon(Icons.visibility), findsNothing);
  });

  // testWidgets('Login with valid credentials calls correct method', (WidgetTester tester) async {
  //   // Prepare the mock to return a Future<UserModel>
  //   final testUser = createTestUser();
  //
  //   // Use .thenAnswer with an async function that returns a Future
  //   when(mockAuthService.signInWithEmailAndPassword(
  //       email: anyNamed('email'),
  //       password: anyNamed('password')
  //   )).thenAnswer((_) async => testUser);
  //
  //   await tester.pumpWidget(createTestWidget());
  //   await tester.pumpAndSettle();
  //
  //   // Enter valid credentials
  //   await tester.enterText(find.byType(TextFormField).at(0), 'test@example.com');
  //   await tester.enterText(find.byType(TextFormField).at(1), 'password123');
  //
  //   // Ensure login button is visible
  //   final loginButtonFinder = find.widgetWithText(ElevatedButton, 'Login');
  //   await tester.ensureVisible(loginButtonFinder);
  //
  //   // Tap login button
  //   await tester.tap(loginButtonFinder);
  //   await tester.pump();
  //
  //   // Verify login method was called with correct parameters
  //   verify(mockAuthService.signInWithEmailAndPassword(
  //     email: 'test@example.com',
  //     password: 'password123',
  //   )).called(1);
  // });
  //
  // testWidgets('Google sign-in calls correct method', (WidgetTester tester) async {
  //   // Setup mock only for this test
  //   when(mockAuthService.signInWithGoogle()).thenAnswer((_) async => createTestUser());
  //
  //   await tester.pumpWidget(createTestWidget());
  //   await tester.pumpAndSettle();
  //
  //   // Find Google sign-in button
  //   final googleButtonFinder = find.widgetWithText(ElevatedButton, 'Sign in with Google');
  //   await tester.ensureVisible(googleButtonFinder);
  //
  //   // Tap Google sign-in button
  //   await tester.tap(googleButtonFinder);
  //   await tester.pump();
  //
  //   // Verify Google sign-in method was called
  //   verify(mockAuthService.signInWithGoogle()).called(1);
  // });
}