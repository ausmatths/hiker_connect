import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
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

// Mock Firestore implementation
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

// Mock Firebase Storage
// ignore: must_be_immutable
class MockFirebaseStorage extends Mock implements FirebaseStorage {
  @override
  Reference ref([String? path]) {
    return MockReference();
  }
}

// ignore: must_be_immutable
class MockReference extends Mock implements Reference {
  @override
  UploadTask putFile(File file, [SettableMetadata? metadata]) {
    return MockUploadTask();
  }

  @override
  Future<String> getDownloadURL() async {
    return 'https://example.com/test-image.jpg';
  }
}

// ignore: must_be_immutable
class MockUploadTask extends Mock implements UploadTask {
  final MockTaskSnapshot _snapshot = MockTaskSnapshot();

  @override
  TaskSnapshot get snapshot => _snapshot;

  @override
  Future<TaskSnapshot> get future async => _snapshot;
}

// ignore: must_be_immutable
class MockTaskSnapshot extends Mock implements TaskSnapshot {
  @override
  Reference get ref => MockReference();
}

// ignore: must_be_immutable
class MockGeoPoint extends Mock implements GeoPoint {
  @override
  final double latitude;

  @override
  final double longitude;

  MockGeoPoint(this.latitude, this.longitude);
}

// Global mock instances that will be used to intercept Firebase calls
final MockFirebaseFirestore _mockFirestore = MockFirebaseFirestore();
final MockFirebaseStorage _mockStorage = MockFirebaseStorage();

// Setup function
Future<void> setupFirebaseForTests() async {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Setup method channel mocks first
  setupMethodChannelMocks();

  // Since we can't set the instance properties directly, we need to make sure our
  // code in the test calls our getter functions below instead of the static instances
  print('Firebase mock initialization complete');
}

// Getter functions to use in tests instead of the static instances
MockFirebaseFirestore getMockFirestore() => _mockFirestore;
MockFirebaseStorage getMockStorage() => _mockStorage;

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
    'plugins.flutter.io/firebase_storage': (MethodCall call) async {
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
  final bool _exists;

  FakeDocumentSnapshot(this._data, this._id, {bool exists = true}) : _exists = exists;

  @override
  String get id => _id;

  @override
  bool get exists => _exists;

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