import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hiker_connect/models/photo_data.dart';

void main() {
  group('PhotoData Model Tests', () {
    final testDate = DateTime(2023, 10, 15);

    test('should create PhotoData with required fields', () {
      final photoData = PhotoData(
        id: 'photo123',
        url: 'https://example.com/photo.jpg',
        uploaderId: 'user456',
        uploadDate: testDate,
      );

      expect(photoData.id, 'photo123');
      expect(photoData.url, 'https://example.com/photo.jpg');
      expect(photoData.uploaderId, 'user456');
      expect(photoData.uploadDate, testDate);
      expect(photoData.thumbnailUrl, isNull);
      expect(photoData.caption, isNull);
    });

    test('should create PhotoData with all fields', () {
      final photoData = PhotoData(
        id: 'photo123',
        url: 'https://example.com/photo.jpg',
        thumbnailUrl: 'https://example.com/thumb.jpg',
        uploaderId: 'user456',
        trailId: 'trail789',
        eventId: 'event101',
        uploadDate: testDate,
        caption: 'Beautiful view',
        localPath: '/path/to/local.jpg',
      );

      expect(photoData.id, 'photo123');
      expect(photoData.url, 'https://example.com/photo.jpg');
      expect(photoData.thumbnailUrl, 'https://example.com/thumb.jpg');
      expect(photoData.uploaderId, 'user456');
      expect(photoData.trailId, 'trail789');
      expect(photoData.eventId, 'event101');
      expect(photoData.uploadDate, testDate);
      expect(photoData.caption, 'Beautiful view');
      expect(photoData.localPath, '/path/to/local.jpg');
    });

    test('copyWith should update specific fields', () {
      final original = PhotoData(
        id: 'photo123',
        url: 'https://example.com/photo.jpg',
        uploaderId: 'user456',
        uploadDate: testDate,
      );

      final updated = original.copyWith(
        caption: 'New caption',
        trailId: 'new_trail_id',
      );

      // Original should be unchanged
      expect(original.caption, isNull);
      expect(original.trailId, isNull);

      // Updated should have new values
      expect(updated.id, 'photo123'); // Unchanged
      expect(updated.url, 'https://example.com/photo.jpg'); // Unchanged
      expect(updated.uploaderId, 'user456'); // Unchanged
      expect(updated.uploadDate, testDate); // Unchanged
      expect(updated.caption, 'New caption'); // Updated
      expect(updated.trailId, 'new_trail_id'); // Updated
    });

    test('toJson should convert all fields', () {
      final photoData = PhotoData(
        id: 'photo123',
        url: 'https://example.com/photo.jpg',
        thumbnailUrl: 'https://example.com/thumb.jpg',
        uploaderId: 'user456',
        trailId: 'trail789',
        eventId: 'event101',
        uploadDate: testDate,
        caption: 'Beautiful view',
        localPath: '/path/to/local.jpg',
      );

      final json = photoData.toJson();

      expect(json['id'], 'photo123');
      expect(json['url'], 'https://example.com/photo.jpg');
      expect(json['thumbnailUrl'], 'https://example.com/thumb.jpg');
      expect(json['uploaderId'], 'user456');
      expect(json['trailId'], 'trail789');
      expect(json['eventId'], 'event101');
      expect(json['uploadDate'], testDate.toIso8601String());
      expect(json['caption'], 'Beautiful view');
      expect(json['localPath'], '/path/to/local.jpg');
    });

    test('fromJson should recreate the object correctly', () {
      final json = {
        'id': 'photo123',
        'url': 'https://example.com/photo.jpg',
        'thumbnailUrl': 'https://example.com/thumb.jpg',
        'uploaderId': 'user456',
        'trailId': 'trail789',
        'eventId': 'event101',
        'uploadDate': testDate.toIso8601String(),
        'caption': 'Beautiful view',
        'localPath': '/path/to/local.jpg',
      };

      final photoData = PhotoData.fromJson(json);

      expect(photoData.id, 'photo123');
      expect(photoData.url, 'https://example.com/photo.jpg');
      expect(photoData.thumbnailUrl, 'https://example.com/thumb.jpg');
      expect(photoData.uploaderId, 'user456');
      expect(photoData.trailId, 'trail789');
      expect(photoData.eventId, 'event101');
      expect(photoData.uploadDate, DateTime.parse(testDate.toIso8601String()));
      expect(photoData.caption, 'Beautiful view');
      expect(photoData.localPath, '/path/to/local.jpg');
    });

    test('toFirestore should convert to Firestore format', () {
      final photoData = PhotoData(
        id: 'photo123',
        url: 'https://example.com/photo.jpg',
        uploaderId: 'user456',
        uploadDate: testDate,
        caption: 'Test caption',
      );

      final firestoreData = photoData.toFirestore();

      // ID should not be included in Firestore data
      expect(firestoreData.containsKey('id'), isFalse);

      // Check values
      expect(firestoreData['url'], 'https://example.com/photo.jpg');
      expect(firestoreData['uploaderId'], 'user456');
      expect(firestoreData['caption'], 'Test caption');


      expect(firestoreData['uploadDate'], isA<Timestamp>());
      final timestamp = firestoreData['uploadDate'] as Timestamp;
      final convertedDate = timestamp.toDate();
      expect(convertedDate.year, testDate.year);
      expect(convertedDate.month, testDate.month);
      expect(convertedDate.day, testDate.day);
    });
  });
}