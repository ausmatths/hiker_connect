import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  // Set up platform channel for Firebase Auth
  const MethodChannel channel = MethodChannel('plugins.flutter.io/firebase_auth');

  setUp(() {
    // Set up platform channel mock using the new approach
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

  group('Platform Channel Tests', () {
    testWidgets('Test auth token retrieval', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestableWidget(
          Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  try {
                    final result = await channel.invokeMethod('getIdToken');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Token: $result')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                },
                child: const Text('Get Token'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Get Token'));
      await tester.pumpAndSettle();
      expect(find.text('Token: mock_token'), findsOneWidget);
    });
  });

  group('Firebase Configuration Tests', () {
    testWidgets('Test Firebase write operation', (WidgetTester tester) async {
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

    testWidgets('ProfileScreen handles platform channel errors gracefully',
            (WidgetTester tester) async {
          // Simulate platform channel error
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
              .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
            throw PlatformException(code: 'ERROR', message: 'Test error');
          });

          mockAuthService.updateMockData(userData: null, user: mockUser);

          // Build widget
          await tester.pumpWidget(createTestableWidget(const ProfileScreen()));

          // Initial frame should show loading indicator
          expect(find.byType(CircularProgressIndicator), findsOneWidget);

          // Wait for async operations to complete
          await tester.pumpAndSettle();

          // Loading indicator should be gone after error
          expect(find.byType(CircularProgressIndicator), findsNothing);

          // Dump the widget tree to see what's actually being rendered
          debugDumpApp();
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
});
  group('AuthService Tests', () {
    testWidgets('Test signInWithEmailAndPassword', (WidgetTester tester) async {
      mockAuthService.updateMockData(userData: testUser, user: mockUser);
      await tester.pumpWidget(createTestableWidget(const ProfileScreen()));
      await tester.pumpAndSettle();

      final result = await mockAuthService.signInWithEmailAndPassword(
        email: 'test@example.com',
        password: 'password',
      );

      expect(result, equals(testUser));
    });

    testWidgets('Test signInWithGoogle', (WidgetTester tester) async {
      mockAuthService.updateMockData(userData: testUser, user: mockUser);
      await tester.pumpWidget(createTestableWidget(const ProfileScreen()));
      await tester.pumpAndSettle();

      final result = await mockAuthService.signInWithGoogle();
      expect(result, equals(testUser));
    });

    testWidgets('Test signUpWithEmailAndPassword', (WidgetTester tester) async {
      mockAuthService.updateMockData(userData: testUser, user: mockUser);
      await tester.pumpWidget(createTestableWidget(const ProfileScreen()));
      await tester.pumpAndSettle();

      final result = await mockAuthService.signUpWithEmailAndPassword(
        email: 'test@example.com',
        password: 'password',
        displayName: 'Test User',
      );

      expect(result, equals(testUser));
    });

    testWidgets('Test signOut', (WidgetTester tester) async {
      mockAuthService.updateMockData(userData: testUser, user: mockUser);
      await tester.pumpWidget(createTestableWidget(const ProfileScreen()));
      await tester.pumpAndSettle();

      await mockAuthService.signOut();
      expect(mockAuthService.currentUser, isNull);
      expect(mockAuthService.getCurrentUserData(), completion(isNull));
    });

    testWidgets('Test resetPassword', (WidgetTester tester) async {
      mockAuthService.updateMockData(userData: testUser, user: mockUser);
      await tester.pumpWidget(createTestableWidget(const ProfileScreen()));
      await tester.pumpAndSettle();

      await mockAuthService.resetPassword('test@example.com');
      // Since it's a mock, we just ensure it doesn't throw an error
      expect(() async => await mockAuthService.resetPassword('test@example.com'), returnsNormally);
    });

    testWidgets('Test updateUserProfile', (WidgetTester tester) async {
      mockAuthService.updateMockData(userData: testUser, user: mockUser);
      await tester.pumpWidget(createTestableWidget(const ProfileScreen()));
      await tester.pumpAndSettle();

      await mockAuthService.updateUserProfile(
        displayName: 'Updated Name',
        bio: 'Updated Bio',
      );

      // Since it's a mock, we just ensure it doesn't throw an error
      expect(() async => await mockAuthService.updateUserProfile(displayName: 'Updated Name'), returnsNormally);
    });
  });

  group('ProfileScreen Widget Tests - Additional', () {
    testWidgets('ProfileScreen shows error when user data fetch fails', (WidgetTester tester) async {
      // Simulate an error when fetching user data
      when(mockAuthService.getCurrentUserData()).thenThrow(Exception('Failed to fetch user data'));

      await tester.pumpWidget(createTestableWidget(const ProfileScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Failed to fetch user data'), findsOneWidget);
    });

    testWidgets('ProfileScreen handles empty user data gracefully', (WidgetTester tester) async {
      mockAuthService.updateMockData(userData: null, user: mockUser);
      await tester.pumpWidget(createTestableWidget(const ProfileScreen()));
      await tester.pumpAndSettle();

      expect(find.text('No user data available'), findsOneWidget);
    });

    testWidgets('ProfileScreen handles null location gracefully', (WidgetTester tester) async {
      final userWithNullLocation = UserModel(
        uid: 'test-uid',
        email: 'test@example.com',
        displayName: 'Test User',
        bio: 'Test bio',
        photoUrl: null,
        location: null, // Null location
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

      mockAuthService.updateMockData(userData: userWithNullLocation, user: mockUser);
      await tester.pumpWidget(createTestableWidget(const ProfileScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Location: Not specified'), findsOneWidget);
    });
  });

  group('Firebase Firestore Tests', () {
    testWidgets('Test Firebase read operation', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestableWidget(
          Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  try {
                    final snapshot = await FirebaseFirestore.instance.collection('test').get();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Read ${snapshot.docs.length} documents')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Firebase error: $e')),
                    );
                  }
                },
                child: const Text('Read Firebase'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Read Firebase'));
      await tester.pumpAndSettle();
      expect(find.text('Read 0 documents'), findsOneWidget);
    });

    testWidgets('Test Firebase error handling', (WidgetTester tester) async {
      when(mockFirestore.collection('test').get()).thenThrow(Exception('Firestore error'));

      await tester.pumpWidget(
        createTestableWidget(
          Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  try {
                    await FirebaseFirestore.instance.collection('test').get();
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Firebase error: $e')),
                    );
                  }
                },
                child: const Text('Test Firebase Error'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Test Firebase Error'));
      await tester.pumpAndSettle();
      expect(find.text('Firebase error: Exception: Firestore error'), findsOneWidget);
    });
  });

  group('UserModel and EmergencyContact Tests - Additional', () {
    test('UserModel handles null values correctly', () {
      final userWithNullValues = UserModel(
        uid: 'test-uid',
        email: '',
        displayName: '',
        bio: null,
        photoUrl: null,
        location: null,
        createdAt: DateTime.now(),
        lastActive: DateTime.now(),
        following: [],
        followers: [],
        medicalConditions: [],
        medications: [],
        bloodType: null,
        emergencyContacts: [],
        interests: [],
        socialLinks: {},
      );

      final userMap = userWithNullValues.toMap();
      expect(userMap['email'], isNull);
      expect(userMap['displayName'], isNull);
      expect(userMap['bio'], isNull);
      expect(userMap['location'], isNull);
    });

    test('EmergencyContact handles null values correctly', () {
      final contactWithNullValues = EmergencyContact(
        name: '',
        relationship: '',
        phoneNumber: '',
      );

      final contactMap = contactWithNullValues.toMap();
      expect(contactMap['name'], isNull);
      expect(contactMap['relationship'], isNull);
      expect(contactMap['phoneNumber'], isNull);
    });
  });
}