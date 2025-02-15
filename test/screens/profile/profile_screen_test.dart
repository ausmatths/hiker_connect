import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:hiker_connect/models/user_model.dart';
import 'package:hiker_connect/screens/profile/profile_screen.dart';
import 'package:hiker_connect/services/firebase_auth.dart';
import 'package:mockito/annotations.dart';
import 'package:firebase_app_check/firebase_app_check.dart';

import 'profile_screen_test.mocks.dart';

@GenerateMocks([User, FirebaseAppCheck], customMocks: [
  MockSpec<User>(as: #MockFirebaseUser),
])

class MockAuthService with ChangeNotifier implements AuthService {
  UserModel? _mockUserData;
  User? _mockUser;

  MockAuthService({UserModel? mockUserData, User? mockUser})
      : _mockUserData = mockUserData,
        _mockUser = mockUser;

  void updateMockData({UserModel? userData, User? user}) {
    _mockUserData = userData;
    _mockUser = user;
    notifyListeners();
  }

  @override
  Stream<User?> get authStateChanges => Stream.value(_mockUser);

  @override
  User? get currentUser => _mockUser;

  @override
  Future<UserModel?> getCurrentUserData() async => _mockUserData;

  @override
  Future<UserModel?> getUserData(String uid) async => _mockUserData;

  @override
  Future<void> resetPassword(String email) async {
    // Mock implementation
    return;
  }

  @override
  Future<UserModel?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    return _mockUserData;
  }

  @override
  Future<UserModel?> signInWithGoogle() async {
    return _mockUserData;
  }

  @override
  Future<UserModel?> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
  }) async {
    return _mockUserData;
  }

  @override
  Future<void> signOut() async {
    _mockUser = null;
    _mockUserData = null;
    notifyListeners();
  }

  @override
  Future<void> updateUserProfile({
    String? displayName,
    String? bio,
    List<String>? interests,
    String? phoneNumber,
    UserLocation? location,
    DateTime? dateOfBirth,
    String? gender,
    double? height,
    double? weight,
    String? preferredLanguage,
    String? bloodType,
    String? allergies,
    String? insuranceInfo,
    List<String>? medicalConditions,
    List<String>? medications,
    List<EmergencyContact>? emergencyContacts,
    Map<String, String>? socialLinks,
  }) async {
    // Mock implementation
    return;
  }
}

class MockFirestore extends Mock implements FirebaseFirestore {
  @override
  Future<void> enableNetwork() async => Future.value();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockAuthService mockAuthService;
  late UserModel testUser;
  late MockFirebaseUser mockUser;
  late MockFirestore mockFirestore;

  setUp(() {
    mockUser = MockFirebaseUser();
    mockFirestore = MockFirestore();
    when(mockUser.uid).thenReturn('test-uid');
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

  // Firebase Configuration Test
  testWidgets('Test Firebase Configuration', (WidgetTester tester) async {
    await tester.pumpWidget(
      createTestableWidget(
        Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                try {
                  await FirebaseFirestore.instance.collection('test').add({
                    'timestamp': FieldValue.serverTimestamp(),
                    'test': 'Firebase Web Test'
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Firebase write successful!')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Firebase error: $e')),
                  );
                }
              },
              child: const Text('Test Firebase'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Test Firebase'));
    await tester.pumpAndSettle();
  });

  // App Check Test
  testWidgets('Test App Check', (WidgetTester tester) async {
    await tester.pumpWidget(
      createTestableWidget(
        Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                try {
                  await FirebaseFirestore.instance
                      .collection('protected_collection')
                      .add({
                    'timestamp': FieldValue.serverTimestamp(),
                    'appCheck': 'Testing App Check',
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('App Check Verified!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('App Check Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Test App Check'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Test App Check'));
    await tester.pumpAndSettle();
  });

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