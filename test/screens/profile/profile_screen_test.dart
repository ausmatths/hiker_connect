import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:google_sign_in_mocks/google_sign_in_mocks.dart';
import 'package:hiker_connect/models/user_model.dart';
import 'package:hiker_connect/screens/profile/profile_screen.dart';
import 'package:hiker_connect/services/firebase_auth.dart';

class MockAuthService extends Mock implements AuthService {
  UserModel? _mockUserData;
  final User _mockUser = MockUser(uid: 'test-uid');
  final Completer<UserModel?> _completer = Completer<UserModel?>();

  MockAuthService({UserModel? initialUserData}) {
    _mockUserData = initialUserData;
  }

  @override
  User? get currentUser => _mockUser;

  @override
  Future<UserModel?> getCurrentUserData() async {
    return Future.delayed(const Duration(milliseconds: 100), () => _mockUserData);
  }

  @override
  Future<UserModel?> getUserData(String uid) async {
    return Future.delayed(const Duration(milliseconds: 100), () => _mockUserData);
  }

  void updateMockData(UserModel? userData) {
    _mockUserData = userData;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockAuthService mockAuthService;
  late UserModel testUser;

  setUp(() {
    testUser = UserModel(
      uid: 'test-uid',
      email: 'test@example.com',
      displayName: 'Test User',
      bio: 'Test bio',
      photoUrl: null, // Remove network image URL
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
    );
  });

  Widget createTestableWidget(Widget child) {
    return MaterialApp(
      home: MultiProvider(
        providers: [
          Provider<AuthService>.value(
            value: mockAuthService,
          ),
        ],
        child: child,
      ),
    );
  }

  group('ProfileScreen Widget Tests', () {
    testWidgets('ProfileScreen shows loading indicator when user data is null',
            (WidgetTester tester) async {
          // Initialize mockAuthService with null data
          mockAuthService = MockAuthService(initialUserData: null);

          await tester.pumpWidget(createTestableWidget(
              ProfileScreen(authService: mockAuthService)
          ));

          // Initial frame
          await tester.pump();

          // Verify loading indicator is shown
          expect(find.byType(CircularProgressIndicator), findsOneWidget);
        });

    testWidgets('ProfileScreen loads and displays user data',
            (WidgetTester tester) async {
          // Initialize mockAuthService with test data
          mockAuthService = MockAuthService(initialUserData: testUser);

          await tester.pumpWidget(createTestableWidget(
              ProfileScreen(authService: mockAuthService)
          ));

          // Wait for the Future to complete and UI to update
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 100));

          expect(find.text('Test User'), findsOneWidget);
          expect(find.text('Test bio'), findsOneWidget);
        });

    testWidgets('Medical tab displays correct information',
            (WidgetTester tester) async {
          mockAuthService = MockAuthService(initialUserData: testUser);

          await tester.pumpWidget(createTestableWidget(
              ProfileScreen(authService: mockAuthService)
          ));

          // Wait for the initial data to load
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 100));

          // Find and tap the Medical tab
          await tester.tap(find.text('Medical'));
          await tester.pumpAndSettle();

          expect(find.text('A+'), findsOneWidget);
          expect(find.text('Asthma'), findsOneWidget);
          expect(find.text('Inhaler'), findsOneWidget);
        });
  });

  group('UserModel Tests', () {
    test('UserModel converts to and from Map correctly', () {
      final Map<String, dynamic> userMap = testUser.toMap();
      expect(userMap['email'], equals(testUser.email));
      expect(userMap['displayName'], equals(testUser.displayName));
      expect(userMap['bio'], equals(testUser.bio));
      expect(userMap['location']['address'], equals(testUser.location?.address));
    });

    test('EmergencyContact converts to and from Map correctly', () {
      final contact = EmergencyContact(
        name: 'Test Contact',
        relationship: 'Friend',
        phoneNumber: '+1234567890',
      );

      final Map<String, dynamic> contactMap = contact.toMap();
      final EmergencyContact reconstructedContact = EmergencyContact.fromMap(contactMap);

      expect(reconstructedContact.name, equals(contact.name));
      expect(reconstructedContact.relationship, equals(contact.relationship));
      expect(reconstructedContact.phoneNumber, equals(contact.phoneNumber));
    });
  });
}