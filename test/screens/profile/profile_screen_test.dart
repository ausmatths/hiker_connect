import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:hiker_connect/models/user_model.dart';
import 'package:hiker_connect/screens/profile/profile_screen.dart';
import 'package:hiker_connect/services/firebase_auth.dart';

class MockAuthService extends Mock implements AuthService {
  UserModel? _mockUserData;
  User? _mockUser;

  MockAuthService({UserModel? mockUserData, User? mockUser})
      : _mockUserData = mockUserData,
        _mockUser = mockUser;

  void updateMockData({UserModel? userData, User? user}) {
    _mockUserData = userData;
    _mockUser = user;
  }

  @override
  Future<UserModel?> getCurrentUserData() async => _mockUserData;

  @override
  User? get currentUser => _mockUser;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockAuthService mockAuthService;
  late UserModel testUser;
  late MockUser mockUser;

  setUp(() {
    mockUser = MockUser(uid: 'test-uid');
    testUser = UserModel(
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
    );

    mockAuthService = MockAuthService(
        mockUserData: testUser,
        mockUser: mockUser
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
          mockAuthService.updateMockData(
              userData: null,
              user: mockUser
          );

          await tester.pumpWidget(createTestableWidget(
              const ProfileScreen()
          ));

          expect(find.byType(CircularProgressIndicator), findsOneWidget);
          await tester.pumpAndSettle();
        });

    testWidgets('ProfileScreen loads and displays user data',
            (WidgetTester tester) async {
          mockAuthService.updateMockData(
              userData: testUser,
              user: mockUser
          );

          await tester.pumpWidget(createTestableWidget(
              const ProfileScreen()
          ));

          await tester.pumpAndSettle();

          expect(find.text('Test User'), findsOneWidget);
          expect(find.text('Test bio'), findsOneWidget);
        });

    testWidgets('Medical tab displays correct information',
            (WidgetTester tester) async {
          mockAuthService.updateMockData(
              userData: testUser,
              user: mockUser
          );

          await tester.pumpWidget(createTestableWidget(
              const ProfileScreen()
          ));

          await tester.pumpAndSettle();

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