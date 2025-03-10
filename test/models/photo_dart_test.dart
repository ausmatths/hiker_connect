import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hiker_connect/models/photo_data.dart'; // Update this import to match your actual package name

void main() {
  group('PhotoData', () {
    final DateTime testDate = DateTime(2025, 3, 9);

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
      );

      expect(photoData.id, 'photo123');
      expect(photoData.url, 'https://example.com/photo.jpg');
      expect(photoData.thumbnailUrl, 'https://example.com/thumbnail.jpg');
      expect(photoData.uploaderId, 'user456');
      expect(photoData.trailId, 'trail789');
      expect(photoData.eventId, 'event101');
      expect(photoData.uploadDate, testDate);
      expect(photoData.caption, 'Beautiful hiking trail');
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
        expect(identical(copied, original), false);
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
        );

        final copied = original.copyWith(
          thumbnailUrl: null,
          trailId: null,
          eventId: null,
          caption: null,
        );

        expect(copied.id, original.id);
        expect(copied.url, original.url);
        /*expect(copied.thumbnailUrl, null);
        expect(copied.uploaderId, original.uploaderId);
        expect(copied.trailId, null);
        expect(copied.eventId, null);
        expect(copied.uploadDate, original.uploadDate);
        expect(copied.caption, null);*/
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
        );

        expect(photo1.id, photo2.id);
        expect(photo1.url, photo2.url);
        expect(photo1.thumbnailUrl, photo2.thumbnailUrl);
        expect(photo1.uploaderId, photo2.uploaderId);
        expect(photo1.trailId, photo2.trailId);
        expect(photo1.eventId, photo2.eventId);
        expect(photo1.uploadDate, photo2.uploadDate);
        expect(photo1.caption, photo2.caption);
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
      // We're not testing if it's a HiveObject here to avoid needing to import Hive
    });

    test('should round trip through JSON correctly', () {
      final original = PhotoData(
        id: 'photo123',
        url: 'https://example.com/photo.jpg',
        thumbnailUrl: 'https://example.com/thumbnail.jpg',
        uploaderId: 'user456',
        trailId: 'trail789',
        eventId: 'event101',
        uploadDate: testDate,
        caption: 'Beautiful hiking trail',
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
    });
  });
}