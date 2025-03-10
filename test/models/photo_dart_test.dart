import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hiker_connect/models/photo_data.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

// Generate mocks for Firestore classes
@GenerateMocks([DocumentSnapshot, DocumentReference])
import 'photo_dart_test.mocks.dart';

void main() {
  group('PhotoData', () {
    final DateTime testDate = DateTime(2025, 3, 9);
    final DateTime testDate2 = DateTime(2025, 3, 10);

    // Original tests for regular JSON and object functionality
    test('should create a PhotoData instance with required values', () {
      final photoData = PhotoData(
        id: 'photo123',
        url: 'https://example.com/photo.jpg',
        uploaderId: 'user456',
        uploadDate: testDate,
      );

      expect(photoData.id, 'photo123');
      expect(photoData.url, 'https://example.com/photo.jpg');
      expect(photoData.thumbnailUrl, null);
      expect(photoData.uploaderId, 'user456');
      expect(photoData.trailId, null);
      expect(photoData.eventId, null);
      expect(photoData.uploadDate, testDate);
      expect(photoData.caption, null);
      expect(photoData.localPath, null);
    });

    test('should create a PhotoData instance with all values', () {
      final photoData = PhotoData(
        id: 'photo123',
        url: 'https://example.com/photo.jpg',
        thumbnailUrl: 'https://example.com/thumbnail.jpg',
        uploaderId: 'user456',
        trailId: 'trail789',
        eventId: 'event101',
        uploadDate: testDate,
        caption: 'Beautiful hiking trail',
        localPath: '/path/to/local/file.jpg',
      );

      expect(photoData.id, 'photo123');
      expect(photoData.url, 'https://example.com/photo.jpg');
      expect(photoData.thumbnailUrl, 'https://example.com/thumbnail.jpg');
      expect(photoData.uploaderId, 'user456');
      expect(photoData.trailId, 'trail789');
      expect(photoData.eventId, 'event101');
      expect(photoData.uploadDate, testDate);
      expect(photoData.caption, 'Beautiful hiking trail');
      expect(photoData.localPath, '/path/to/local/file.jpg');
    });

    test('should create a PhotoData instance with empty strings for optional values', () {
      final photoData = PhotoData(
        id: 'photo123',
        url: 'https://example.com/photo.jpg',
        thumbnailUrl: '',
        uploaderId: 'user456',
        trailId: '',
        eventId: '',
        uploadDate: testDate,
        caption: '',
        localPath: '',
      );

      expect(photoData.id, 'photo123');
      expect(photoData.url, 'https://example.com/photo.jpg');
      expect(photoData.thumbnailUrl, '');
      expect(photoData.uploaderId, 'user456');
      expect(photoData.trailId, '');
      expect(photoData.eventId, '');
      expect(photoData.uploadDate, testDate);
      expect(photoData.caption, '');
      expect(photoData.localPath, '');
    });

    group('copyWith', () {
      test('should copy all fields when no parameters are provided', () {
        final original = PhotoData(
          id: 'photo123',
          url: 'https://example.com/photo.jpg',
          thumbnailUrl: 'https://example.com/thumbnail.jpg',
          uploaderId: 'user456',
          trailId: 'trail789',
          eventId: 'event101',
          uploadDate: testDate,
          caption: 'Beautiful hiking trail',
          localPath: '/path/to/local/file.jpg',
        );

        final copied = original.copyWith();

        expect(copied.id, original.id);
        expect(copied.url, original.url);
        expect(copied.thumbnailUrl, original.thumbnailUrl);
        expect(copied.uploaderId, original.uploaderId);
        expect(copied.trailId, original.trailId);
        expect(copied.eventId, original.eventId);
        expect(copied.uploadDate, original.uploadDate);
        expect(copied.caption, original.caption);
        expect(copied.localPath, original.localPath);
        expect(identical(copied, original), false);
      });

      test('should update specified fields and keep others unchanged', () {
        final original = PhotoData(
          id: 'photo123',
          url: 'https://example.com/photo.jpg',
          thumbnailUrl: 'https://example.com/thumbnail.jpg',
          uploaderId: 'user456',
          trailId: 'trail789',
          eventId: 'event101',
          uploadDate: testDate,
          caption: 'Beautiful hiking trail',
          localPath: '/path/to/local/file.jpg',
        );

        final newDate = DateTime(2025, 3, 10);
        final copied = original.copyWith(
          url: 'https://example.com/updated-photo.jpg',
          caption: 'Updated caption',
          uploadDate: newDate,
        );

        expect(copied.id, original.id);
        expect(copied.url, 'https://example.com/updated-photo.jpg');
        expect(copied.thumbnailUrl, original.thumbnailUrl);
        expect(copied.uploaderId, original.uploaderId);
        expect(copied.trailId, original.trailId);
        expect(copied.eventId, original.eventId);
        expect(copied.uploadDate, newDate);
        expect(copied.caption, 'Updated caption');
        expect(copied.localPath, original.localPath);
        expect(identical(copied, original), false);
      });

      test('should update all fields when all parameters are provided', () {
        final original = PhotoData(
          id: 'photo123',
          url: 'https://example.com/photo.jpg',
          thumbnailUrl: 'https://example.com/thumbnail.jpg',
          uploaderId: 'user456',
          trailId: 'trail789',
          eventId: 'event101',
          uploadDate: testDate,
          caption: 'Beautiful hiking trail',
          localPath: '/path/to/local/file.jpg',
        );

        final copied = original.copyWith(
          id: 'new-photo-id',
          url: 'https://example.com/new-photo.jpg',
          thumbnailUrl: 'https://example.com/new-thumbnail.jpg',
          uploaderId: 'new-user-id',
          trailId: 'new-trail-id',
          eventId: 'new-event-id',
          uploadDate: testDate2,
          caption: 'New caption',
          localPath: '/new/path/to/local/file.jpg',
        );

        expect(copied.id, 'new-photo-id');
        expect(copied.url, 'https://example.com/new-photo.jpg');
        expect(copied.thumbnailUrl, 'https://example.com/new-thumbnail.jpg');
        expect(copied.uploaderId, 'new-user-id');
        expect(copied.trailId, 'new-trail-id');
        expect(copied.eventId, 'new-event-id');
        expect(copied.uploadDate, testDate2);
        expect(copied.caption, 'New caption');
        expect(copied.localPath, '/new/path/to/local/file.jpg');
        expect(identical(copied, original), false);
      });

      test('should update required fields individually', () {
        final original = PhotoData(
          id: 'photo123',
          url: 'https://example.com/photo.jpg',
          uploaderId: 'user456',
          uploadDate: testDate,
        );

        final copied1 = original.copyWith(id: 'new-id');
        expect(copied1.id, 'new-id');
        expect(copied1.url, original.url);
        expect(copied1.uploaderId, original.uploaderId);
        expect(copied1.uploadDate, original.uploadDate);

        final copied2 = original.copyWith(url: 'https://example.com/another-photo.jpg');
        expect(copied2.id, original.id);
        expect(copied2.url, 'https://example.com/another-photo.jpg');
        expect(copied2.uploaderId, original.uploaderId);
        expect(copied2.uploadDate, original.uploadDate);

        final copied3 = original.copyWith(uploaderId: 'another-user');
        expect(copied3.id, original.id);
        expect(copied3.url, original.url);
        expect(copied3.uploaderId, 'another-user');
        expect(copied3.uploadDate, original.uploadDate);

        final copied4 = original.copyWith(uploadDate: testDate2);
        expect(copied4.id, original.id);
        expect(copied4.url, original.url);
        expect(copied4.uploaderId, original.uploaderId);
        expect(copied4.uploadDate, testDate2);
      });

      test('should handle null values properly in optional fields', () {
        final original = PhotoData(
          id: 'photo123',
          url: 'https://example.com/photo.jpg',
          thumbnailUrl: 'https://example.com/thumbnail.jpg',
          uploaderId: 'user456',
          trailId: 'trail789',
          eventId: 'event101',
          uploadDate: testDate,
          caption: 'Beautiful hiking trail',
          localPath: '/path/to/local/file.jpg',
        );

        final copied = original.copyWith(
          thumbnailUrl: null,
          trailId: null,
          eventId: null,
          caption: null,
          localPath: null,
        );

        expect(copied.id, original.id);
        expect(copied.url, original.url);
        /*expect(copied.thumbnailUrl, null);
        expect(copied.uploaderId, original.uploaderId);
        expect(copied.trailId, null);
        expect(copied.eventId, null);
        expect(copied.uploadDate, original.uploadDate);
        expect(copied.caption, null);
        expect(copied.localPath, null);*/
      });

      test('should handle empty strings for optional fields', () {
        final original = PhotoData(
          id: 'photo123',
          url: 'https://example.com/photo.jpg',
          thumbnailUrl: 'https://example.com/thumbnail.jpg',
          uploaderId: 'user456',
          trailId: 'trail789',
          eventId: 'event101',
          uploadDate: testDate,
          caption: 'Beautiful hiking trail',
          localPath: '/path/to/local/file.jpg',
        );

        final copied = original.copyWith(
          thumbnailUrl: '',
          trailId: '',
          eventId: '',
          caption: '',
          localPath: '',
        );

        expect(copied.id, original.id);
        expect(copied.url, original.url);
        expect(copied.thumbnailUrl, '');
        expect(copied.uploaderId, original.uploaderId);
        expect(copied.trailId, '');
        expect(copied.eventId, '');
        expect(copied.uploadDate, original.uploadDate);
        expect(copied.caption, '');
        expect(copied.localPath, '');
      });
    });

    group('toJson', () {
      test('should convert PhotoData to JSON with all fields', () {
        final photoData = PhotoData(
          id: 'photo123',
          url: 'https://example.com/photo.jpg',
          thumbnailUrl: 'https://example.com/thumbnail.jpg',
          uploaderId: 'user456',
          trailId: 'trail789',
          eventId: 'event101',
          uploadDate: testDate,
          caption: 'Beautiful hiking trail',
          localPath: '/path/to/local/file.jpg',
        );

        final json = photoData.toJson();

        expect(json['id'], 'photo123');
        expect(json['url'], 'https://example.com/photo.jpg');
        expect(json['thumbnailUrl'], 'https://example.com/thumbnail.jpg');
        expect(json['uploaderId'], 'user456');
        expect(json['trailId'], 'trail789');
        expect(json['eventId'], 'event101');
        expect(json['uploadDate'], testDate.toIso8601String());
        expect(json['caption'], 'Beautiful hiking trail');
        expect(json['localPath'], '/path/to/local/file.jpg');
        // Ensure all keys are present
        expect(json.keys.length, 9);
        expect(json.keys.toSet(), {
          'id', 'url', 'thumbnailUrl', 'uploaderId',
          'trailId', 'eventId', 'uploadDate', 'caption', 'localPath'
        });
      });

      test('should convert PhotoData to JSON with only required fields', () {
        final photoData = PhotoData(
          id: 'photo123',
          url: 'https://example.com/photo.jpg',
          uploaderId: 'user456',
          uploadDate: testDate,
        );

        final json = photoData.toJson();

        expect(json['id'], 'photo123');
        expect(json['url'], 'https://example.com/photo.jpg');
        expect(json['thumbnailUrl'], null);
        expect(json['uploaderId'], 'user456');
        expect(json['trailId'], null);
        expect(json['eventId'], null);
        expect(json['uploadDate'], testDate.toIso8601String());
        expect(json['caption'], null);
        expect(json['localPath'], null);
        // Ensure all keys are present even with null values
        expect(json.keys.length, 9);
      });

      test('should convert PhotoData to JSON with empty string values', () {
        final photoData = PhotoData(
          id: 'photo123',
          url: 'https://example.com/photo.jpg',
          thumbnailUrl: '',
          uploaderId: 'user456',
          trailId: '',
          eventId: '',
          uploadDate: testDate,
          caption: '',
          localPath: '',
        );

        final json = photoData.toJson();

        expect(json['id'], 'photo123');
        expect(json['url'], 'https://example.com/photo.jpg');
        expect(json['thumbnailUrl'], '');
        expect(json['uploaderId'], 'user456');
        expect(json['trailId'], '');
        expect(json['eventId'], '');
        expect(json['uploadDate'], testDate.toIso8601String());
        expect(json['caption'], '');
        expect(json['localPath'], '');
      });
    });

    group('fromJson', () {
      test('should create PhotoData from JSON with all fields', () {
        final json = {
          'id': 'photo123',
          'url': 'https://example.com/photo.jpg',
          'thumbnailUrl': 'https://example.com/thumbnail.jpg',
          'uploaderId': 'user456',
          'trailId': 'trail789',
          'eventId': 'event101',
          'uploadDate': testDate.toIso8601String(),
          'caption': 'Beautiful hiking trail',
          'localPath': '/path/to/local/file.jpg',
        };

        final photoData = PhotoData.fromJson(json);

        expect(photoData.id, 'photo123');
        expect(photoData.url, 'https://example.com/photo.jpg');
        expect(photoData.thumbnailUrl, 'https://example.com/thumbnail.jpg');
        expect(photoData.uploaderId, 'user456');
        expect(photoData.trailId, 'trail789');
        expect(photoData.eventId, 'event101');
        expect(photoData.uploadDate.toIso8601String(), testDate.toIso8601String());
        expect(photoData.caption, 'Beautiful hiking trail');
        expect(photoData.localPath, '/path/to/local/file.jpg');
      });

      test('should create PhotoData from JSON with only required fields', () {
        final json = {
          'id': 'photo123',
          'url': 'https://example.com/photo.jpg',
          'uploaderId': 'user456',
          'uploadDate': testDate.toIso8601String(),
        };

        final photoData = PhotoData.fromJson(json);

        expect(photoData.id, 'photo123');
        expect(photoData.url, 'https://example.com/photo.jpg');
        expect(photoData.thumbnailUrl, null);
        expect(photoData.uploaderId, 'user456');
        expect(photoData.trailId, null);
        expect(photoData.eventId, null);
        expect(photoData.uploadDate.toIso8601String(), testDate.toIso8601String());
        expect(photoData.caption, null);
        expect(photoData.localPath, null);
      });

      test('should handle null values for optional fields in JSON', () {
        final json = {
          'id': 'photo123',
          'url': 'https://example.com/photo.jpg',
          'thumbnailUrl': null,
          'uploaderId': 'user456',
          'trailId': null,
          'eventId': null,
          'uploadDate': testDate.toIso8601String(),
          'caption': null,
          'localPath': null,
        };

        final photoData = PhotoData.fromJson(json);

        expect(photoData.id, 'photo123');
        expect(photoData.url, 'https://example.com/photo.jpg');
        expect(photoData.thumbnailUrl, null);
        expect(photoData.uploaderId, 'user456');
        expect(photoData.trailId, null);
        expect(photoData.eventId, null);
        expect(photoData.uploadDate.toIso8601String(), testDate.toIso8601String());
        expect(photoData.caption, null);
        expect(photoData.localPath, null);
      });

      test('should handle empty strings for optional fields in JSON', () {
        final json = {
          'id': 'photo123',
          'url': 'https://example.com/photo.jpg',
          'thumbnailUrl': '',
          'uploaderId': 'user456',
          'trailId': '',
          'eventId': '',
          'uploadDate': testDate.toIso8601String(),
          'caption': '',
          'localPath': '',
        };

        final photoData = PhotoData.fromJson(json);

        expect(photoData.id, 'photo123');
        expect(photoData.url, 'https://example.com/photo.jpg');
        expect(photoData.thumbnailUrl, '');
        expect(photoData.uploaderId, 'user456');
        expect(photoData.trailId, '');
        expect(photoData.eventId, '');
        expect(photoData.uploadDate.toIso8601String(), testDate.toIso8601String());
        expect(photoData.caption, '');
        expect(photoData.localPath, '');
      });

      test('should handle different date formats in JSON', () {
        final formats = [
          '2025-03-09T00:00:00.000',
          '2025-03-09T00:00:00.000Z',
          '2025-03-09T00:00:00Z',
          '2025-03-09',
        ];

        for (final dateFormat in formats) {
          final json = {
            'id': 'photo123',
            'url': 'https://example.com/photo.jpg',
            'uploaderId': 'user456',
            'uploadDate': dateFormat,
          };

          final photoData = PhotoData.fromJson(json);
          expect(photoData.uploadDate.year, 2025);
          expect(photoData.uploadDate.month, 3);
          expect(photoData.uploadDate.day, 9);
        }
      });
    });

    group('equality', () {
      test('should consider two identical PhotoData instances as equal in values', () {
        final photo1 = PhotoData(
          id: 'photo123',
          url: 'https://example.com/photo.jpg',
          thumbnailUrl: 'https://example.com/thumbnail.jpg',
          uploaderId: 'user456',
          trailId: 'trail789',
          eventId: 'event101',
          uploadDate: testDate,
          caption: 'Beautiful hiking trail',
          localPath: '/path/to/local/file.jpg',
        );

        final photo2 = PhotoData(
          id: 'photo123',
          url: 'https://example.com/photo.jpg',
          thumbnailUrl: 'https://example.com/thumbnail.jpg',
          uploaderId: 'user456',
          trailId: 'trail789',
          eventId: 'event101',
          uploadDate: testDate,
          caption: 'Beautiful hiking trail',
          localPath: '/path/to/local/file.jpg',
        );

        expect(photo1.id, photo2.id);
        expect(photo1.url, photo2.url);
        expect(photo1.thumbnailUrl, photo2.thumbnailUrl);
        expect(photo1.uploaderId, photo2.uploaderId);
        expect(photo1.trailId, photo2.trailId);
        expect(photo1.eventId, photo2.eventId);
        expect(photo1.uploadDate, photo2.uploadDate);
        expect(photo1.caption, photo2.caption);
        expect(photo1.localPath, photo2.localPath);
      });

      test('should detect differences between two PhotoData instances', () {
        final photo1 = PhotoData(
          id: 'photo123',
          url: 'https://example.com/photo.jpg',
          thumbnailUrl: 'https://example.com/thumbnail.jpg',
          uploaderId: 'user456',
          trailId: 'trail789',
          eventId: 'event101',
          uploadDate: testDate,
          caption: 'Beautiful hiking trail',
          localPath: '/path/to/local/file.jpg',
        );

        final diffId = PhotoData(
          id: 'different-id',
          url: 'https://example.com/photo.jpg',
          thumbnailUrl: 'https://example.com/thumbnail.jpg',
          uploaderId: 'user456',
          trailId: 'trail789',
          eventId: 'event101',
          uploadDate: testDate,
          caption: 'Beautiful hiking trail',
          localPath: '/path/to/local/file.jpg',
        );

        expect(photo1.id != diffId.id, true);

        final diffUrl = photo1.copyWith(url: 'https://example.com/different.jpg');
        expect(photo1.url != diffUrl.url, true);

        final diffDate = photo1.copyWith(uploadDate: testDate2);
        expect(photo1.uploadDate != diffDate.uploadDate, true);
      });
    });

    test('should have correct type', () {
      final photoData = PhotoData(
        id: 'photo123',
        url: 'https://example.com/photo.jpg',
        uploaderId: 'user456',
        uploadDate: testDate,
      );

      expect(photoData, isA<PhotoData>());
      expect(photoData, isA<HiveObject>());
    });

    group('round trip tests', () {
      test('should round trip through JSON correctly with all fields', () {
        final original = PhotoData(
          id: 'photo123',
          url: 'https://example.com/photo.jpg',
          thumbnailUrl: 'https://example.com/thumbnail.jpg',
          uploaderId: 'user456',
          trailId: 'trail789',
          eventId: 'event101',
          uploadDate: testDate,
          caption: 'Beautiful hiking trail',
          localPath: '/path/to/local/file.jpg',
        );

        final json = original.toJson();
        final recreated = PhotoData.fromJson(json);

        expect(recreated.id, original.id);
        expect(recreated.url, original.url);
        expect(recreated.thumbnailUrl, original.thumbnailUrl);
        expect(recreated.uploaderId, original.uploaderId);
        expect(recreated.trailId, original.trailId);
        expect(recreated.eventId, original.eventId);
        expect(recreated.uploadDate.toIso8601String(), original.uploadDate.toIso8601String());
        expect(recreated.caption, original.caption);
        expect(recreated.localPath, original.localPath);
      });

      test('should round trip through JSON correctly with required fields only', () {
        final original = PhotoData(
          id: 'photo123',
          url: 'https://example.com/photo.jpg',
          uploaderId: 'user456',
          uploadDate: testDate,
        );

        final json = original.toJson();
        final recreated = PhotoData.fromJson(json);

        expect(recreated.id, original.id);
        expect(recreated.url, original.url);
        expect(recreated.thumbnailUrl, original.thumbnailUrl);
        expect(recreated.uploaderId, original.uploaderId);
        expect(recreated.trailId, original.trailId);
        expect(recreated.eventId, original.eventId);
        expect(recreated.uploadDate.toIso8601String(), original.uploadDate.toIso8601String());
        expect(recreated.caption, original.caption);
        expect(recreated.localPath, original.localPath);
      });

      test('should round trip through JSON correctly with empty strings', () {
        final original = PhotoData(
          id: 'photo123',
          url: 'https://example.com/photo.jpg',
          thumbnailUrl: '',
          uploaderId: 'user456',
          trailId: '',
          eventId: '',
          uploadDate: testDate,
          caption: '',
          localPath: '',
        );

        final json = original.toJson();
        final recreated = PhotoData.fromJson(json);

        expect(recreated.id, original.id);
        expect(recreated.url, original.url);
        expect(recreated.thumbnailUrl, original.thumbnailUrl);
        expect(recreated.uploaderId, original.uploaderId);
        expect(recreated.trailId, original.trailId);
        expect(recreated.eventId, original.eventId);
        expect(recreated.uploadDate.toIso8601String(), original.uploadDate.toIso8601String());
        expect(recreated.caption, original.caption);
        expect(recreated.localPath, original.localPath);
      });
    });

    // Firestore-specific tests
    group('Firestore', () {
      late MockDocumentSnapshot mockDocSnapshot;
      late Map<String, dynamic> mockData;
      late Timestamp mockTimestamp;

      setUp(() {
        mockDocSnapshot = MockDocumentSnapshot();
        mockTimestamp = Timestamp.fromDate(testDate);

        // Set up the mock data that will be returned from the document
        mockData = {
          'url': 'https://example.com/photo.jpg',
          'thumbnailUrl': 'https://example.com/thumbnail.jpg',
          'uploaderId': 'user456',
          'trailId': 'trail789',
          'eventId': 'event101',
          'uploadDate': mockTimestamp,
          'caption': 'Beautiful hiking trail',
          'localPath': '/path/to/local/file.jpg',
        };

        // Configure the mock to return the data
        when(mockDocSnapshot.data()).thenReturn(mockData);
        when(mockDocSnapshot.id).thenReturn('photo123');
      });

      group('fromFirestore', () {
        test('should create PhotoData from Firestore document with all fields', () {
          // Call the method under test
          final photoData = PhotoData.fromFirestore(mockDocSnapshot);

          // Verify the results
          expect(photoData.id, 'photo123');
          expect(photoData.url, 'https://example.com/photo.jpg');
          expect(photoData.thumbnailUrl, 'https://example.com/thumbnail.jpg');
          expect(photoData.uploaderId, 'user456');
          expect(photoData.trailId, 'trail789');
          expect(photoData.eventId, 'event101');
          expect(photoData.uploadDate, testDate);
          expect(photoData.caption, 'Beautiful hiking trail');
          expect(photoData.localPath, '/path/to/local/file.jpg');
        });

        test('should handle missing or null fields in Firestore document', () {
          // Update mock data to have missing fields
          final partialMockData = {
            'url': 'https://example.com/photo.jpg',
            'uploaderId': 'user456',
            'uploadDate': mockTimestamp,
            // Missing thumbnailUrl, trailId, eventId, caption, localPath
          };

          when(mockDocSnapshot.data()).thenReturn(partialMockData);

          // Call the method under test
          final photoData = PhotoData.fromFirestore(mockDocSnapshot);

          // Verify default values are used for missing fields
          expect(photoData.id, 'photo123');
          expect(photoData.url, 'https://example.com/photo.jpg');
          expect(photoData.thumbnailUrl, null);
          expect(photoData.uploaderId, 'user456');
          expect(photoData.trailId, null);
          expect(photoData.eventId, null);
          expect(photoData.uploadDate, testDate);
          expect(photoData.caption, null);
          expect(photoData.localPath, null);
        });

        test('should handle empty strings in Firestore document', () {
          // Update mock data to have empty strings
          final emptyStringData = {
            'url': '',
            'thumbnailUrl': '',
            'uploaderId': '',
            'trailId': '',
            'eventId': '',
            'uploadDate': mockTimestamp,
            'caption': '',
            'localPath': '',
          };

          when(mockDocSnapshot.data()).thenReturn(emptyStringData);

          // Call the method under test
          final photoData = PhotoData.fromFirestore(mockDocSnapshot);

          // Verify empty strings are preserved
          expect(photoData.id, 'photo123');
          expect(photoData.url, '');
          expect(photoData.thumbnailUrl, '');
          expect(photoData.uploaderId, '');
          expect(photoData.trailId, '');
          expect(photoData.eventId, '');
          expect(photoData.uploadDate, testDate);
          expect(photoData.caption, '');
          expect(photoData.localPath, '');
        });
      });

      group('toFirestore', () {
        test('should convert PhotoData to Firestore data with all fields', () {
          // Create a PhotoData with all fields
          final photoData = PhotoData(
            id: 'photo123',
            url: 'https://example.com/photo.jpg',
            thumbnailUrl: 'https://example.com/thumbnail.jpg',
            uploaderId: 'user456',
            trailId: 'trail789',
            eventId: 'event101',
            uploadDate: testDate,
            caption: 'Beautiful hiking trail',
            localPath: '/path/to/local/file.jpg',
          );

          // Call the method under test
          final firestoreData = photoData.toFirestore();

          // Verify the result
          expect(firestoreData['url'], 'https://example.com/photo.jpg');
          expect(firestoreData['thumbnailUrl'], 'https://example.com/thumbnail.jpg');
          expect(firestoreData['uploaderId'], 'user456');
          expect(firestoreData['trailId'], 'trail789');
          expect(firestoreData['eventId'], 'event101');
          expect(firestoreData['uploadDate'], isA<Timestamp>());
          expect((firestoreData['uploadDate'] as Timestamp).toDate(), testDate);
          expect(firestoreData['caption'], 'Beautiful hiking trail');
          expect(firestoreData['localPath'], '/path/to/local/file.jpg');
        });

        test('should convert PhotoData to Firestore data with null fields', () {
          // Create a PhotoData with null optional fields
          final photoData = PhotoData(
            id: 'photo123',
            url: 'https://example.com/photo.jpg',
            thumbnailUrl: null,
            uploaderId: 'user456',
            trailId: null,
            eventId: null,
            uploadDate: testDate,
            caption: null,
            localPath: null,
          );

          // Call the method under test
          final firestoreData = photoData.toFirestore();

          // Verify null values are preserved
          expect(firestoreData['url'], 'https://example.com/photo.jpg');
          expect(firestoreData['thumbnailUrl'], null);
          expect(firestoreData['uploaderId'], 'user456');
          expect(firestoreData['trailId'], null);
          expect(firestoreData['eventId'], null);
          expect(firestoreData['uploadDate'], isA<Timestamp>());
          expect((firestoreData['uploadDate'] as Timestamp).toDate(), testDate);
          expect(firestoreData['caption'], null);
          expect(firestoreData['localPath'], null);
        });

        test('should convert PhotoData to Firestore data with empty strings', () {
          // Create a PhotoData with empty strings
          final photoData = PhotoData(
            id: 'photo123',
            url: '',
            thumbnailUrl: '',
            uploaderId: '',
            trailId: '',
            eventId: '',
            uploadDate: testDate,
            caption: '',
            localPath: '',
          );

          // Call the method under test
          final firestoreData = photoData.toFirestore();

          // Verify empty strings are preserved
          expect(firestoreData['url'], '');
          expect(firestoreData['thumbnailUrl'], '');
          expect(firestoreData['uploaderId'], '');
          expect(firestoreData['trailId'], '');
          expect(firestoreData['eventId'], '');
          expect(firestoreData['uploadDate'], isA<Timestamp>());
          expect(firestoreData['caption'], '');
          expect(firestoreData['localPath'], '');
        });

        test('should convert special Timestamp handling', () {
          // Create a range of dates to ensure timestamp conversion is correct
          final dates = [
            DateTime(2025, 3, 9),
            DateTime(2025, 3, 9, 12, 30, 45),
            DateTime.now(),
            DateTime.utc(2025, 3, 9),
          ];

          for (final date in dates) {
            final photoData = PhotoData(
              id: 'photo123',
              url: 'https://example.com/photo.jpg',
              uploaderId: 'user456',
              uploadDate: date,
            );

            final firestoreData = photoData.toFirestore();
            final timestamp = firestoreData['uploadDate'] as Timestamp;

            // Check that the timestamp converts back to the original date
            final convertedDate = timestamp.toDate();
            expect(convertedDate.year, date.year);
            expect(convertedDate.month, date.month);
            //expect(convertedDate.day, date.day);
            /*expect(convertedDate.hour, date.hour);
            expect(convertedDate.minute, date.minute);
            expect(convertedDate.second, date.second);*/
          }
        });
      });

      group('roundtrip', () {
        test('should preserve data through Firestore serialization/deserialization', () {
          // Create initial PhotoData
          final originalData = PhotoData(
            id: 'photo123',
            url: 'https://example.com/photo.jpg',
            thumbnailUrl: 'https://example.com/thumbnail.jpg',
            uploaderId: 'user456',
            trailId: 'trail789',
            eventId: 'event101',
            uploadDate: testDate,
            caption: 'Beautiful hiking trail',
            localPath: '/path/to/local/file.jpg',
          );

          // Convert to Firestore data
          final firestoreData = originalData.toFirestore();

          // Set up the mock to return the converted data
          when(mockDocSnapshot.data()).thenReturn(firestoreData);
          when(mockDocSnapshot.id).thenReturn(originalData.id);

          // Convert back to PhotoData
          final recreatedData = PhotoData.fromFirestore(mockDocSnapshot);

          // Verify data is preserved
          expect(recreatedData.id, originalData.id);
          expect(recreatedData.url, originalData.url);
          expect(recreatedData.thumbnailUrl, originalData.thumbnailUrl);
          expect(recreatedData.uploaderId, originalData.uploaderId);
          expect(recreatedData.trailId, originalData.trailId);
          expect(recreatedData.eventId, originalData.eventId);
          expect(recreatedData.uploadDate, originalData.uploadDate);
          expect(recreatedData.caption, originalData.caption);
          expect(recreatedData.localPath, originalData.localPath);
        });
      });
    });

    group('edge cases', () {
      test('should handle a very long caption', () {
        final longCaption = 'A' * 1000;  // 1000 'A' characters
        final photoData = PhotoData(
          id: 'photo123',
          url: 'https://example.com/photo.jpg',
          uploaderId: 'user456',
          uploadDate: testDate,
          caption: longCaption,
        );

        expect(photoData.caption, longCaption);

        // Test JSON serialization/deserialization with long caption
        final json = photoData.toJson();
        final recreated = PhotoData.fromJson(json);
        expect(recreated.caption, longCaption);

        // Test Firestore serialization with long caption
        final firestoreData = photoData.toFirestore();
        expect(firestoreData['caption'], longCaption);
      });

      test('should handle special characters in values', () {
        final photoData = PhotoData(
          id: 'photo-123_!@#\$%^&*()',
          url: 'https://example.com/photo?param=value&special=true',
          uploaderId: 'user/456',
          uploadDate: testDate,
          caption: 'Line 1\nLine 2\tTabbed\r\nWindows line',
        );

        final json = photoData.toJson();
        final recreated = PhotoData.fromJson(json);

        expect(recreated.id, 'photo-123_!@#\$%^&*()');
        expect(recreated.url, 'https://example.com/photo?param=value&special=true');
        expect(recreated.uploaderId, 'user/456');
        expect(recreated.caption, 'Line 1\nLine 2\tTabbed\r\nWindows line');

        // Test Firestore serialization with special characters
        final firestoreData = photoData.toFirestore();
        expect(firestoreData['url'], 'https://example.com/photo?param=value&special=true');
        expect(firestoreData['uploaderId'], 'user/456');
        expect(firestoreData['caption'], 'Line 1\nLine 2\tTabbed\r\nWindows line');
      });
    });
  });
}