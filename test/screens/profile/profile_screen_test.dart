// test/screens/profile/profile_screen_test.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:hiker_connect/models/user_model.dart';
import 'package:hiker_connect/screens/profile/profile_screen.dart';
import 'package:hiker_connect/services/firebase_auth.dart';
import 'package:mockito/annotations.dart';

// Import Firebase test utilities
import '../../firebase_test_utils.dart';
// Import mock auth service
import '../../services/firebase_auth_mock.dart';

// Generate mocks with unique names
@GenerateMocks([], customMocks: [
  MockSpec<User>(as: #GeneratedMockUser),
  MockSpec<FirebaseFirestore>(as: #GeneratedMockFirestore),
])

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockAuthService mockAuthService;
  late UserModel testUser;
  late User mockUser;
  late FirebaseFirestore mockFirestore;

  // Set up platform channel for Firebase Auth
  const MethodChannel channel = MethodChannel('plugins.flutter.io/firebase_auth');

  setUp(() {
    // Setup Firebase for tests
    setupFirebaseForTests();

    // Set up platform channel mock
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      switch (methodCall.method) {
        case 'signInWithCredential':
          return {'user': {'uid': 'test-uid'}};
        case 'getIdToken':
          return 'mock_token';
        default:
          return null;
      }
    });

    // Use MockUser from firebase_test_utils.dart - don't try to mock the uid property
    mockUser = MockUser();
    mockFirestore = MockFirebaseFirestore();
    // Remove the when() call - MockUser already provides uid property

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

  tearDown(() {
    // Clear platform channel mock
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  Widget createTestableWidget(Widget child) {
    return MaterialApp(
      home: MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthService>.value(
            value: mockAuthService,
          ),
          Provider<FirebaseFirestore>.value(
            value: mockFirestore,
          ),
        ],
        child: child,
      ),
    );
  }

  group('ProfileScreen Widget Tests', () {
    testWidgets('ProfileScreen shows loading indicator when user data is null',
            (WidgetTester tester) async {
          mockAuthService.updateMockData(userData: null, user: mockUser);
          await tester.pumpWidget(createTestableWidget(const ProfileScreen()));
          expect(find.byType(CircularProgressIndicator), findsOneWidget);
          await tester.pumpAndSettle();
        });

    testWidgets('ProfileScreen loads and displays user data',
            (WidgetTester tester) async {
          mockAuthService.updateMockData(userData: testUser, user: mockUser);
          await tester.pumpWidget(createTestableWidget(const ProfileScreen()));
          await tester.pumpAndSettle();
          expect(find.text('Test User'), findsOneWidget);
          expect(find.text('Test bio'), findsOneWidget);
        });

    testWidgets('Medical tab displays correct information',
            (WidgetTester tester) async {
          mockAuthService.updateMockData(userData: testUser, user: mockUser);
          await tester.pumpWidget(createTestableWidget(const ProfileScreen()));
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
      expect(userMap['email'], testUser.email);
      expect(userMap['displayName'], testUser.displayName);
      expect(userMap['bio'], testUser.bio);
      expect(userMap['location']['address'], testUser.location?.address);
    });

    test('EmergencyContact converts to and from Map correctly', () {
      final contact = EmergencyContact(
        name: 'Test Contact',
        relationship: 'Friend',
        phoneNumber: '+1234567890',
      );
      final Map<String, dynamic> contactMap = contact.toMap();
      final EmergencyContact reconstructedContact = EmergencyContact.fromMap(contactMap);
      expect(reconstructedContact.name, contact.name);
      expect(reconstructedContact.relationship, contact.relationship);
      expect(reconstructedContact.phoneNumber, contact.phoneNumber);
    });
  });
}