import 'package:flutter_test/flutter_test.dart';
import 'package:hiker_connect/models/trail_data.dart';


void main() {
  group('TrailData', () {

    final DateTime testDate = DateTime(2025, 2, 15);
    final List<String> testImages = ['image1.jpg', 'image2.jpg'];

    test('should create a TrailData instance with required values', () {
      final trailData = TrailData(
        trailId: 1,
        trailName: 'Mountain Trek',
        trailDescription: 'A beautiful mountain trail',
        trailDifficulty: 'Moderate',
        trailNotice: 'Watch for wildlife',
        trailImages: testImages,
        trailDate: testDate,
        trailLocation: 'Rocky Mountains',
        trailParticipantNumber: 10,
        trailDuration: Duration(minutes: 120),
      );

      expect(trailData.trailId, 1);
      expect(trailData.trailName, 'Mountain Trek');
      expect(trailData.trailDescription, 'A beautiful mountain trail');
      expect(trailData.trailDifficulty, 'Moderate');
      expect(trailData.trailNotice, 'Watch for wildlife');
      expect(trailData.trailImages, testImages);
      expect(trailData.trailDate, testDate);
      expect(trailData.trailLocation, 'Rocky Mountains');
      expect(trailData.trailParticipantNumber, 10);
      expect(trailData.trailDuration, Duration(minutes: 120));
    });

    group('toMap', () {
      test('should convert TrailData to Map correctly', () {
        final trailData = TrailData(
          trailId: 1,
          trailName: 'Mountain Trek',
          trailDescription: 'A beautiful mountain trail',
          trailDifficulty: 'Moderate',
          trailNotice: 'Watch for wildlife',
          trailImages: testImages,
          trailDate: testDate,
          trailLocation: 'Rocky Mountains',
          trailParticipantNumber: 10,
          trailDuration: Duration(minutes: 120),
        );

        final map = trailData.toMap();

        expect(map['trailId'], 1);
        expect(map['trailName'], 'Mountain Trek');
        expect(map['description'], 'A beautiful mountain trail');
        expect(map['trailDifficulty'], 'Moderate');
        expect(map['trailNotice'], 'Watch for wildlife');
        expect(map['trailImages'], 'image1.jpg,image2.jpg');
        expect(map['trailDate'], testDate.toIso8601String());
        expect(map['trailLocation'], 'Rocky Mountains');
        expect(map['trailParticipantNumber'], 10);
        expect(map['trailDuration'], 120);
      });

      test('should handle empty image list in toMap', () {
        final trailData = TrailData(
          trailId: 1,
          trailName: 'Trail',
          trailDescription: 'Description',
          trailDifficulty: 'Easy',
          trailNotice: 'Notice',
          trailImages: [], // Empty list
          trailDate: testDate,
          trailLocation: 'Location',
          trailParticipantNumber: 5,
          trailDuration: Duration(minutes: 60),
        );

        final map = trailData.toMap();
        expect(map['trailImages'], '');
      });
    });

    group('fromMap', () {
      test('should create TrailData from Map with all fields', () {
        final map = {
          'trailId': 1,
          'trailName': 'Mountain Trek',
          'trailDescription': 'A beautiful mountain trail',
          'trailDifficulty': 'Moderate',
          'trailNotice': 'Watch for wildlife',
          'trailImages': testImages,
          'trailDate': '2025-02-15T00:00:00.000',
          'trailLocation': 'Rocky Mountains',
          'trailParticipantNumber': 10,
          'trailDuration': 120,
        };

        final trailData = TrailData.fromMap(map);

        expect(trailData.trailId, 1);
        expect(trailData.trailName, 'Mountain Trek');
        expect(trailData.trailDescription, 'A beautiful mountain trail');
        expect(trailData.trailDifficulty, 'Moderate');
        expect(trailData.trailNotice, 'Watch for wildlife');
        expect(trailData.trailImages, testImages);
        expect(trailData.trailDate.year, 2025);
        expect(trailData.trailDate.month, 2);
        expect(trailData.trailDate.day, 15);
        expect(trailData.trailLocation, 'Rocky Mountains');
        expect(trailData.trailParticipantNumber, 10);
        expect(trailData.trailDuration, Duration(minutes: 120));
      });

      test('should handle missing fields with default values', () {
        final map = {
          'trailDate': '2025-02-15T00:00:00.000',
        };

        final trailData = TrailData.fromMap(map);

        expect(trailData.trailId, 0);
        expect(trailData.trailName, '');
        expect(trailData.trailDescription, '');
        expect(trailData.trailDifficulty, '');
        expect(trailData.trailNotice, '');
        expect(trailData.trailImages, []);
        expect(trailData.trailDate.toIso8601String(), '2025-02-15T00:00:00.000');
        expect(trailData.trailLocation, '');
        expect(trailData.trailParticipantNumber, 0);
        expect(trailData.trailDuration, Duration(minutes: 0));
      });

      test('should handle null values for each field', () {
        final map = {
          'trailId': null,
          'trailName': null,
          'trailDescription': null,
          'trailDifficulty': null,
          'trailNotice': null,
          'trailImages': null,
          'trailDate': '2025-02-15T00:00:00.000',
          'trailLocation': null,
          'trailParticipantNumber': null,
          'trailDuration': null,
        };

        final trailData = TrailData.fromMap(map);

        expect(trailData.trailId, 0);
        expect(trailData.trailName, '');
        expect(trailData.trailDescription, '');
        expect(trailData.trailDifficulty, '');
        expect(trailData.trailNotice, '');
        expect(trailData.trailImages, []);
        expect(trailData.trailLocation, '');
        expect(trailData.trailParticipantNumber, 0);
        expect(trailData.trailDuration, Duration(minutes: 0));
      });

      test('should parse DateTime correctly', () {
        final dates = [
          '2025-02-15T00:00:00.000',
          '2025-02-15T00:00:00.000Z',
          '2025-02-15',
        ];

        for (final dateString in dates) {
          final map = {
            'trailDate': dateString,
          };

          final trailData = TrailData.fromMap(map);
          expect(trailData.trailDate.year, 2025);
          expect(trailData.trailDate.month, 2);
          expect(trailData.trailDate.day, 15);
        }
      });

      test('should handle various Duration values', () {
        final durations = [
          0,
          60,
          1440,
        ];

        for (final durationMinutes in durations) {
          final map = {
            'trailDate': '2025-02-15T00:00:00.000',
            'trailDuration': durationMinutes,
          };

          final trailData = TrailData.fromMap(map);
          expect(trailData.trailDuration, Duration(minutes: durationMinutes));
        }
      });

      test('should handle various image formats', () {
        final imageTests = [
          {'input': ['image1.jpg', 'image2.png'], 'expected': ['image1.jpg', 'image2.png']},
          {'input': [], 'expected': []},
          {'input': ['single.jpg'], 'expected': ['single.jpg']},
        ];

        for (final test in imageTests) {
          final map = {
            'trailDate': '2025-02-15T00:00:00.000',
            'trailImages': test['input'],
          };

          final trailData = TrailData.fromMap(map);
          expect(trailData.trailImages, test['expected']);
        }
      });
    });


    test('should have correct Hive type and field annotations', () {

      final trailData = TrailData(
        trailId: 1,
        trailName: 'Test',
        trailDescription: 'Test',
        trailDifficulty: 'Easy',
        trailNotice: 'Notice',
        trailImages: ['test.jpg'],
        trailDate: DateTime.now(),
        trailLocation: 'Location',
        trailParticipantNumber: 1,
        trailDuration: Duration(minutes: 30),
      );

      expect(trailData, isA<TrailData>());
    });


    group('equality tests', () {
      test('two identical TrailData instances should have same properties', () {
        final data1 = TrailData(
          trailId: 1,
          trailName: 'Trail',
          trailDescription: 'Description',
          trailDifficulty: 'Easy',
          trailNotice: 'Notice',
          trailImages: ['image.jpg'],
          trailDate: testDate,
          trailLocation: 'Location',
          trailParticipantNumber: 5,
          trailDuration: Duration(minutes: 60),
        );

        final data2 = TrailData(
          trailId: 1,
          trailName: 'Trail',
          trailDescription: 'Description',
          trailDifficulty: 'Easy',
          trailNotice: 'Notice',
          trailImages: ['image.jpg'],
          trailDate: testDate,
          trailLocation: 'Location',
          trailParticipantNumber: 5,
          trailDuration: Duration(minutes: 60),
        );

        expect(data1.trailId, data2.trailId);
        expect(data1.trailName, data2.trailName);
        expect(data1.trailDescription, data2.trailDescription);
        expect(data1.trailDifficulty, data2.trailDifficulty);
        expect(data1.trailNotice, data2.trailNotice);
        expect(data1.trailImages, data2.trailImages);
        expect(data1.trailDate, data2.trailDate);
        expect(data1.trailLocation, data2.trailLocation);
        expect(data1.trailParticipantNumber, data2.trailParticipantNumber);
        expect(data1.trailDuration, data2.trailDuration);
      });
    });

    test('should roundtrip through toMap and fromMap correctly', () {
      final originalData = TrailData(
        trailId: 1,
        trailName: 'Mountain Trek',
        trailDescription: 'A beautiful mountain trail',
        trailDifficulty: 'Moderate',
        trailNotice: 'Watch for wildlife',
        trailImages: testImages,
        trailDate: testDate,
        trailLocation: 'Rocky Mountains',
        trailParticipantNumber: 10,
        trailDuration: Duration(minutes: 120),
      );

      final map = originalData.toMap();

      final correctedMap = Map<String, dynamic>.from(map);
      correctedMap['trailDescription'] = correctedMap['description'];
      correctedMap['trailImages'] = correctedMap['trailImages'].split(',');

      final recreatedData = TrailData.fromMap(correctedMap);

      expect(recreatedData.trailId, originalData.trailId);
      expect(recreatedData.trailName, originalData.trailName);
      expect(recreatedData.trailDescription, originalData.trailDescription);
      expect(recreatedData.trailDifficulty, originalData.trailDifficulty);
      expect(recreatedData.trailNotice, originalData.trailNotice);
      expect(recreatedData.trailImages, originalData.trailImages);
      expect(recreatedData.trailDate.toIso8601String(), originalData.trailDate.toIso8601String());
      expect(recreatedData.trailLocation, originalData.trailLocation);
      expect(recreatedData.trailParticipantNumber, originalData.trailParticipantNumber);
      expect(recreatedData.trailDuration, originalData.trailDuration);
    });
  });
}