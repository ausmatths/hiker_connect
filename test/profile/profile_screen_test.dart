import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hiker_connect/models/user_model.dart';
import 'package:hiker_connect/screens/profile/profile_screen.dart';
import 'package:hiker_connect/providers/auth_provider.dart';
import 'package:hiker_connect/services/firebase_auth.dart';
import 'dart:async';
import '../helpers/test_helpers.dart';
import '../mocks/auth_mock.mocks.dart';

void main() {
  late MockAuthService mockAuthService;
  late User mockFirebaseUser;
  late UserModel testUser;

  setUpAll(() async {
    TestSetup.setupFirebaseAuthMocks();
    await TestSetup.setupFirebaseForTesting();
  });

  setUp(() {
    mockAuthService = MockAuthService();
    mockFirebaseUser = MockUser();

    // Set up default behaviors
    when(mockAuthService.currentUser).thenReturn(mockFirebaseUser);
    when(mockFirebaseUser.uid).thenReturn('test_uid');

    testUser = UserModel(
      uid: 'test_uid',
      email: 'test@example.com',
      displayName: 'Test User',
      photoUrl: null,
      bio: 'Test bio',
      interests: ['Hiking', 'Camping'],
      createdAt: DateTime.now(),
      lastActive: DateTime.now(),
      isEmailVerified: true,
      following: ['user1', 'user2'],
      followers: ['user3', 'user4'],
      phoneNumber: '+1234567890',
      location: UserLocation(
        geoPoint: const GeoPoint(47.6062, -122.3321),
        address: 'Test Address',
      ),
      emergencyContacts: [
        EmergencyContact(
          name: 'Emergency Contact',
          relationship: 'Family',
          phoneNumber: '123-456-7890',
        ),
      ],
      bloodType: 'O+',
      medicalConditions: [],
      medications: [],
      insuranceInfo: 'Test Insurance',
      allergies: 'None',
      dateOfBirth: DateTime(1990, 1, 1),
      gender: 'Other',
      height: 170.0,
      weight: 70.0,
      preferredLanguage: 'English',
      socialLinks: {
        'Facebook': 'facebook.com/test',
        'Instagram': 'instagram.com/test',
      },
    );
  });

  Future<void> pumpProfileScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HikerAuthProvider(
          authService: mockAuthService,
          child: const ProfileScreen(),
        ),
      ),
    );
  }

  group('ProfileScreen Tests', () {
    testWidgets('shows loading indicator while fetching data',
            (WidgetTester tester) async {
          // Arrange
          final completer = Completer<UserModel>();
          when(mockAuthService.getCurrentUserData())
              .thenAnswer((_) => completer.future);

          // Act
          await pumpProfileScreen(tester);
          await tester.pump();

          // Assert - Loading state
          expect(find.byType(CircularProgressIndicator), findsOneWidget);

          // Complete loading
          completer.complete(testUser);
          await tester.pumpAndSettle();

          // Verify loading is gone
          expect(find.byType(CircularProgressIndicator), findsNothing);
          expect(find.text(testUser.displayName), findsOneWidget);
        });

    testWidgets('displays user information correctly',
            (WidgetTester tester) async {
          // Arrange
          when(mockAuthService.getCurrentUserData())
              .thenAnswer((_) async => testUser);

          // Act
          await pumpProfileScreen(tester);
          await tester.pumpAndSettle();

          // Assert
          expect(find.text(testUser.displayName), findsOneWidget);
          expect(find.text(testUser.bio!), findsOneWidget);
          expect(find.text(testUser.phoneNumber!), findsOneWidget);
        });

    testWidgets('handles error state correctly', (WidgetTester tester) async {
      // Arrange
      when(mockAuthService.getCurrentUserData())
          .thenThrow(Exception('Failed to load user data'));

      // Act
      await pumpProfileScreen(tester);
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Error loading profile'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('handles sign out', (WidgetTester tester) async {
      // Arrange
      when(mockAuthService.getCurrentUserData())
          .thenAnswer((_) async => testUser);
      when(mockAuthService.signOut()).thenAnswer((_) async => null);

      // Act
      await pumpProfileScreen(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.logout));
      await tester.pumpAndSettle();

      // Assert
      verify(mockAuthService.signOut()).called(1);
    });
  });
}