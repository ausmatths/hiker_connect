import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
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
  late MockFirebaseFirestore mockFirestore;
  late MockFirebaseStorage mockStorage;

  setUp(() async {
    // Setup Firebase for tests - this handles all the method channel mocking
    await setupFirebaseForTests();

    // Set up mock objects
    mockUser = MockUser();
    mockFirestore = getMockFirestore(); // Use the getter function
    mockStorage = getMockStorage();   // Use the getter function

    testUser = UserModel(
      uid: 'test-uid',
      email: 'test@example.com',
      displayName: 'Test User',
      bio: 'Test bio',
      photoUrl: '',
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
          ChangeNotifierProvider<AuthService>.value(
            value: mockAuthService,
          ),
          Provider<FirebaseFirestore>.value(
            value: mockFirestore,
          ),
          Provider<FirebaseStorage>.value(
            value: mockStorage,
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

          // Pre-pump a frame to allow the test to create the MaterialApp
          await tester.pumpWidget(createTestableWidget(const ProfileScreen()));

          // Now find the CircularProgressIndicator
          expect(find.byType(CircularProgressIndicator), findsOneWidget);
        });

    testWidgets('ProfileScreen loads and displays user data',
            (WidgetTester tester) async {
          mockAuthService.updateMockData(userData: testUser, user: mockUser);

          // Create a completed future with the test user
          final testUserFuture = Future.value(testUser);

          // Build the widget with the testUserFuture
          await tester.pumpWidget(createTestableWidget(
              ProfileScreen(testUserFuture: testUserFuture)
          ));

          // Wait for the UI to render
          await tester.pumpAndSettle();

          // Verify the username is displayed
          expect(find.text('Test User'), findsOneWidget);

          // Navigate to where the bio is displayed - first tap "More" tab
          await tester.tap(find.text('More'));
          await tester.pumpAndSettle();

          // The "Info" tab should be selected by default in the nested TabBar
          // Now we should see the bio
          expect(find.text('Test bio'), findsOneWidget);
        });

    testWidgets('Medical tab displays correct information',
            (WidgetTester tester) async {
          mockAuthService.updateMockData(userData: testUser, user: mockUser);

          // Create a completed future with the test user
          final testUserFuture = Future.value(testUser);

          // Build the widget with the testUserFuture
          await tester.pumpWidget(createTestableWidget(
              ProfileScreen(testUserFuture: testUserFuture)
          ));

          // Wait for the UI to render
          await tester.pumpAndSettle();

          // First find and tap the 'More' tab
          await tester.tap(find.text('More'));
          await tester.pumpAndSettle();

          // Debug what tabs are available
          print('Tabs after tapping More:');
          tester.allWidgets.where((widget) => widget is Tab).forEach((widget) {
            if (widget is Tab) {
              print('Tab: ${widget.text}');
            }
          });

          // Then find and tap the 'Medical' tab within the nested TabBar
          await tester.tap(find.text('Medical'));
          await tester.pumpAndSettle();

          // Verify medical information is displayed
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