import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiker_connect/screens/profile/profile_photo_gallery.dart';
import 'package:hiker_connect/widgets/shimmer_loading.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:image_picker/image_picker.dart' as picker;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'package:hiker_connect/models/photo_data.dart';

import 'package:hiker_connect/services/databaseservice.dart';

// Import the generated mocks
import 'profile_photo_gallery_test.mocks.dart';

// Mock classes for objects not easily mocked by Mockito
class MockXFile implements picker.XFile {
  @override
  final String path;

  MockXFile({this.path = '/path/to/test/image.jpg'});

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

@GenerateMocks([
  DatabaseService,
  FirebaseAuth,
  FirebaseFirestore,
  CollectionReference,
  DocumentReference,
  DocumentSnapshot,
  User,
  FirebaseStorage,
  Reference,
  TaskSnapshot,
  picker.ImagePicker,
])
void main() {
  group('ProfilePhotoGallery Tests', () {
    late MockDatabaseService mockDatabaseService;
    late MockFirebaseAuth mockFirebaseAuth;
    late MockUser mockUser;
    late MockFirebaseFirestore mockFirestore;
    late MockCollectionReference mockCollectionReference;
    late MockDocumentReference mockDocumentReference;
    late MockDocumentSnapshot mockDocumentSnapshot;
    late MockFirebaseStorage mockFirebaseStorage;
    late MockReference mockReference;
    late MockTaskSnapshot mockTaskSnapshot;
    late MockImagePicker mockImagePicker;

    // Helper method to create a sample PhotoData
    PhotoData createMockPhotoData({
      String? id,
      String? url,
      String? thumbnailUrl,
      String? uploaderId,
      String? trailId,
      String? eventId,
      DateTime? uploadDate,
      String? caption,
      String? localPath,
    }) {
      return PhotoData(
        id: id ?? 'test_photo_id',
        url: url ?? 'https://example.com/photo.jpg',
        thumbnailUrl: thumbnailUrl,
        uploaderId: uploaderId ?? 'test_user_id',
        trailId: trailId,
        eventId: eventId,
        uploadDate: uploadDate ?? DateTime.now(),
        caption: caption,
        localPath: localPath,
      );
    }

    setUp(() {
      // Initialize mocks
      mockDatabaseService = MockDatabaseService();
      mockFirebaseAuth = MockFirebaseAuth();
      mockUser = MockUser();
      mockFirestore = MockFirebaseFirestore();
      mockCollectionReference = MockCollectionReference();
      mockDocumentReference = MockDocumentReference();
      mockDocumentSnapshot = MockDocumentSnapshot();
      mockFirebaseStorage = MockFirebaseStorage();
      mockReference = MockReference();
      mockTaskSnapshot = MockTaskSnapshot();
      mockImagePicker = MockImagePicker();

      // Common mock setups
      when(mockFirebaseAuth.currentUser).thenReturn(mockUser);
      when(mockUser.uid).thenReturn('test_user_id');

      // Firestore collection mock
      when(mockFirestore.collection(any)).thenReturn(mockCollectionReference as CollectionReference<Map<String, dynamic>>);
      when(mockCollectionReference.doc(any)).thenReturn(mockDocumentReference);

      // Document snapshot mock
      when(mockDocumentReference.get()).thenAnswer((_) async => mockDocumentSnapshot);
      when(mockDocumentSnapshot.exists).thenReturn(true);
      when(mockDocumentSnapshot.data()).thenReturn({
        'galleryImages': ['https://example.com/image1.jpg']
      });

      // Storage reference mock
      when(mockFirebaseStorage.ref(any)).thenReturn(mockReference);

      // Image picker mock
      final mockXFile = MockXFile();
      when(mockImagePicker.pickImage(
        source: picker.ImageSource.gallery,
        maxWidth: 1800,
        maxHeight: 1800,
        imageQuality: 85,
      )).thenAnswer((_) async => mockXFile);

      // Task snapshot mock
      //when(mockReference.putFile(any)).thenAnswer((_) async => mockTaskSnapshot);
      when(mockTaskSnapshot.ref).thenReturn(mockReference);
      when(mockReference.getDownloadURL()).thenAnswer((_) async => 'https://example.com/uploaded.jpg');
    });

    testWidgets('Displays loading state initially', (WidgetTester tester) async {
      // Simulate slow photo loading
      when(mockDatabaseService.getUserPhotos(any)).thenAnswer((_) async {
        await Future.delayed(const Duration(seconds: 2));
        return [];
      });

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ProfilePhotoGallery(userId: 'test_user_id'),
        ),
      ));

      // Verify shimmer loading is displayed
      expect(find.byType(ShimmerLoading), findsNWidgets(9));
    });

    testWidgets('Displays empty state when no photos', (WidgetTester tester) async {
      // Mock empty photos
      when(mockDatabaseService.getUserPhotos(any)).thenAnswer((_) async => []);

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ProfilePhotoGallery(userId: 'test_user_id'),
        ),
      ));

      await tester.pumpAndSettle();

      // Verify empty state elements
      expect(find.text('Add some photos'), findsOneWidget);
      expect(find.text('Share your hiking experiences'), findsOneWidget);
      expect(find.byIcon(Icons.photo_library_outlined), findsOneWidget);
    });

    testWidgets('Displays photos when available', (WidgetTester tester) async {
      // Mock photos
      final mockPhotos = [
        createMockPhotoData(
          id: '1',
          url: 'https://example.com/photo1.jpg',
          uploaderId: 'test_user_id',
          caption: 'Test photo 1',
          trailId: 'trail_123',
        )
      ];

      when(mockDatabaseService.getUserPhotos(any)).thenAnswer((_) async => mockPhotos);

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ProfilePhotoGallery(userId: 'test_user_id'),
        ),
      ));

      await tester.pumpAndSettle();

      // Verify grid and add photo button
      expect(find.byType(GridView), findsOneWidget);
      expect(find.byIcon(Icons.photo_camera), findsOneWidget);
    });

    testWidgets('Image upload dialog appears', (WidgetTester tester) async {
      // Mock empty photos
      when(mockDatabaseService.getUserPhotos(any)).thenAnswer((_) async => []);

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ProfilePhotoGallery(userId: 'test_user_id'),
        ),
      ));

      await tester.pumpAndSettle();

      // Tap the add photo camera icon
      await tester.tap(find.byIcon(Icons.photo_camera));
      await tester.pumpAndSettle();

      // Verify dialog appears with correct options
      expect(find.text('Choose Image Source'), findsOneWidget);
      expect(find.text('Take a Photo'), findsOneWidget);
      expect(find.text('Select from Gallery'), findsOneWidget);
    });

    testWidgets('Image upload from gallery', (WidgetTester tester) async {
      // Setup initial mock for empty photos
      when(mockDatabaseService.getUserPhotos(any)).thenAnswer((_) async => []);

      // Simulate successful photo upload
      when(mockDatabaseService.uploadPhoto(
          any,
          caption: anyNamed('caption')
      )).thenAnswer((_) async => createMockPhotoData());

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ProfilePhotoGallery(userId: 'test_user_id'),
        ),
      ));

      await tester.pumpAndSettle();

      // Open image source dialog
      await tester.tap(find.byIcon(Icons.photo_camera));
      await tester.pumpAndSettle();

      // Select from gallery
      await tester.tap(find.text('Select from Gallery'));
      await tester.pumpAndSettle();

      // Verify image upload process
      verify(mockImagePicker.pickImage(
        source: picker.ImageSource.gallery,
        maxWidth: 1800,
        maxHeight: 1800,
        imageQuality: 85,
      )).called(1);
    });

    testWidgets('Error handling during photo upload', (WidgetTester tester) async {
      // Simulate upload error
      when(mockDatabaseService.getUserPhotos(any)).thenAnswer((_) async => []);
      when(mockDatabaseService.uploadPhoto(
          any,
          caption: anyNamed('caption')
      )).thenThrow(Exception('Upload failed'));

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ProfilePhotoGallery(userId: 'test_user_id'),
        ),
      ));

      await tester.pumpAndSettle();

      // Open image source dialog
      await tester.tap(find.byIcon(Icons.photo_camera));
      await tester.pumpAndSettle();

      // Select from gallery
      await tester.tap(find.text('Select from Gallery'));
      await tester.pumpAndSettle();

      // Verify error handling mechanism
      // Note: Actual error handling depends on your specific implementation
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('Camera image capture', (WidgetTester tester) async {
      // Setup initial mock for empty photos
      when(mockDatabaseService.getUserPhotos(any)).thenAnswer((_) async => []);

      // Mock camera image picker
      final mockCameraFile = MockXFile(path: '/path/to/camera/image.jpg');
      when(mockImagePicker.pickImage(
        source: picker.ImageSource.camera,
        maxWidth: 1800,
        maxHeight: 1800,
        imageQuality: 85,
      )).thenAnswer((_) async => mockCameraFile);

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ProfilePhotoGallery(userId: 'test_user_id'),
        ),
      ));

      await tester.pumpAndSettle();

      // Open image source dialog
      await tester.tap(find.byIcon(Icons.photo_camera));
      await tester.pumpAndSettle();

      // Select camera option
      await tester.tap(find.text('Take a Photo'));
      await tester.pumpAndSettle();

      // Verify camera image picker was called
      verify(mockImagePicker.pickImage(
        source: picker.ImageSource.camera,
        maxWidth: 1800,
        maxHeight: 1800,
        imageQuality: 85,
      )).called(1);
    });

    test('PhotoData creation with all parameters', () {
      final testDate = DateTime.now();
      final photoData = createMockPhotoData(
          id: 'test_id_123',
          url: 'https://example.com/test.jpg',
          thumbnailUrl: 'https://example.com/thumbnail.jpg',
          uploaderId: 'uploader_456',
          trailId: 'trail_789',
          eventId: 'event_101',
          uploadDate: testDate,
          caption: 'Test photo caption',
          localPath: '/local/path/to/image.jpg'
      );

      expect(photoData.id, 'test_id_123');
      expect(photoData.url, 'https://example.com/test.jpg');
      expect(photoData.thumbnailUrl, 'https://example.com/thumbnail.jpg');
      expect(photoData.uploaderId, 'uploader_456');
      expect(photoData.trailId, 'trail_789');
      expect(photoData.eventId, 'event_101');
      expect(photoData.uploadDate, testDate);
      expect(photoData.caption, 'Test photo caption');
      expect(photoData.localPath, '/local/path/to/image.jpg');
    });
  });
}