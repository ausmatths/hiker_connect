// test/firebase_test_utils.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

// Mock classes with warnings suppressed
// ignore: must_be_immutable
class MockFirebaseApp extends Mock implements FirebaseApp {
  @override
  String get name => '[DEFAULT]';
}

// ignore: must_be_immutable
class MockFirebaseAuth extends Mock implements FirebaseAuth {
  @override
  User? get currentUser => MockUser();

  @override
  Stream<User?> authStateChanges() => Stream.value(MockUser());
}

// ignore: must_be_immutable
class MockUser extends Mock implements User {
  @override
  String get uid => 'test-uid';

  @override
  String? get displayName => 'Test User';

  @override
  String? get email => 'test@example.com';
}

// ignore: must_be_immutable
class MockFirebaseFirestore extends Mock implements FirebaseFirestore {
  @override
  CollectionReference<Map<String, dynamic>> collection(String path) {
    return MockCollectionReference();
  }
}

// ignore: must_be_immutable
class MockCollectionReference<T extends Map<String, dynamic>> extends Mock
    implements CollectionReference<T> {
  @override
  Future<DocumentReference<T>> add(T data) async {
    return MockDocumentReference<T>();
  }

  @override
  DocumentReference<T> doc([String? path]) {
    return MockDocumentReference<T>();
  }
}

// ignore: must_be_immutable
class MockDocumentReference<T extends Map<String, dynamic>> extends Mock
    implements DocumentReference<T> {
  @override
  Future<void> set(T data, [SetOptions? options]) async {
    return;
  }

  @override
  Future<DocumentSnapshot<T>> get([GetOptions? options]) async {
    return MockDocumentSnapshot<T>();
  }
}

// ignore: must_be_immutable
class MockDocumentSnapshot<T extends Map<String, dynamic>> extends Mock
    implements DocumentSnapshot<T> {
  @override
  bool exists = true;

  @override
  T data() {
    return {} as T;
  }
}

// ignore: must_be_immutable
class MockGeoPoint extends Mock implements GeoPoint {
  @override
  final double latitude;

  @override
  final double longitude;

  MockGeoPoint(this.latitude, this.longitude);
}

// Setup function
Future<void> setupFirebaseForTests() async {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Setup method channel mocks first
  setupMethodChannelMocks();

  // We'll skip actually calling Firebase.initializeApp() in tests
  // as it would try to make actual calls which we don't want in tests

  // Note: This is a simplified approach for testing
  print('Firebase mock initialization complete');
}

// Method channel mocks
void setupMethodChannelMocks() {
  // Define method channel handlers
  final Map<String, Future<dynamic> Function(MethodCall)> methodCallHandlers = {
    'plugins.flutter.io/firebase_core': (MethodCall call) async {
      switch (call.method) {
        case 'Firebase#initializeCore':
          return [
            {
              'name': '[DEFAULT]',
              'options': {
                'apiKey': 'test-api-key',
                'appId': 'test-app-id',
                'messagingSenderId': 'test-sender-id',
                'projectId': 'test-project',
                'storageBucket': 'default-bucket',
              },
              'pluginConstants': {},
            }
          ];
        case 'Firebase#initializeApp':
          return {
            'name': '[DEFAULT]',
            'options': {
              'apiKey': 'test-api-key',
              'appId': 'test-app-id',
              'messagingSenderId': 'test-sender-id',
              'projectId': 'test-project',
              'storageBucket': 'default-bucket',
            },
            'pluginConstants': {},
          };
        default:
          return null;
      }
    },
    'plugins.flutter.io/firebase_auth': (MethodCall call) async {
      switch (call.method) {
        case 'Auth#authStateChanges':
          return {'user': {'uid': 'test-uid'}};
        case 'Auth#getIdToken':
          return 'mock_token';
        case 'Auth#signInWithCredential':
          return {'user': {'uid': 'test-uid'}};
        default:
          return null;
      }
    },
    'plugins.flutter.io/firebase_firestore': (MethodCall call) async {
      return null;
    },
  };

  // Set up handlers for each channel
  methodCallHandlers.forEach((channel, handler) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(MethodChannel(channel), handler);
  });
}

// Create a fake DocumentSnapshot for testing
class FakeDocumentSnapshot implements DocumentSnapshot<Map<String, dynamic>> {
  final Map<String, dynamic> _data;
  final String _id;

  FakeDocumentSnapshot(this._data, this._id);

  @override
  String get id => _id;

  @override
  bool get exists => _data.isNotEmpty;

  @override
  Map<String, dynamic> data() => _data;

  // Implement required methods from the interface
  @override
  get(Object field) => _data[field.toString()];

  @override
  SnapshotMetadata get metadata => throw UnimplementedError();

  @override
  DocumentReference<Map<String, dynamic>> get reference => throw UnimplementedError();

  @override
  operator [](Object field) => _data[field.toString()];
}