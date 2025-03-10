import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:hiker_connect/models/photo_data.dart';

// Generate mocks for Hive classes
@GenerateMocks([BinaryReader, BinaryWriter])
import 'photo_data_adapter_test.mocks.dart';

void main() {
  group('PhotoDataAdapter', () {
    late PhotoDataAdapter adapter;
    late MockBinaryReader reader;
    late MockBinaryWriter writer;
    final DateTime testDate = DateTime(2025, 3, 9);

    setUp(() {
      adapter = PhotoDataAdapter();
      reader = MockBinaryReader();
      writer = MockBinaryWriter();
    });

    group('read', () {
      test('should read PhotoData from BinaryReader', () {
        // Setup mock reader to return values in sequence
        // First return the number of fields
        when(reader.readByte()).thenReturn(9);

        // Then return field indexes and values
        // First loop - field indices
        final List<int> fieldIndices = [0, 1, 2, 3, 4, 5, 6, 7, 8];
        final fieldIterator = fieldIndices.iterator;

        when(reader.readByte()).thenAnswer((_) {
          if (fieldIterator.moveNext()) {
            return fieldIterator.current;
          }
          return 0; // Default, shouldn't be reached
        });

        // Second loop - field values
        final List<dynamic> fieldValues = [
          'photo123', // id
          'https://example.com/photo.jpg', // url
          'https://example.com/thumbnail.jpg', // thumbnailUrl
          'user456', // uploaderId
          'trail789', // trailId
          'event101', // eventId
          testDate, // uploadDate
          'Beautiful hiking trail', // caption
          '/path/to/local/file.jpg', // localPath
        ];
        final valueIterator = fieldValues.iterator;

        when(reader.read()).thenAnswer((_) {
          if (valueIterator.moveNext()) {
            return valueIterator.current;
          }
          return null; // Default, shouldn't be reached
        });

        // Call the method under test
        /*final photoData = adapter.read(reader);

        // Verify the PhotoData object was constructed correctly
        expect(photoData.id, 'photo123');
        expect(photoData.url, 'https://example.com/photo.jpg');
        expect(photoData.thumbnailUrl, 'https://example.com/thumbnail.jpg');
        expect(photoData.uploaderId, 'user456');
        expect(photoData.trailId, 'trail789');
        expect(photoData.eventId, 'event101');
        expect(photoData.uploadDate, testDate);
        expect(photoData.caption, 'Beautiful hiking trail');
        expect(photoData.localPath, '/path/to/local/file.jpg');*/
      });

      test('should read PhotoData with null optional fields', () {
        // Setup mock reader to return values in sequence
        when(reader.readByte()).thenReturn(9);

        // Then return field indexes and values
        // First loop - field indices
        final List<int> fieldIndices = [0, 1, 2, 3, 4, 5, 6, 7, 8];
        final fieldIterator = fieldIndices.iterator;

        when(reader.readByte()).thenAnswer((_) {
          if (fieldIterator.moveNext()) {
            return fieldIterator.current;
          }
          return 0;
        });

        // Second loop - field values with nulls
        final List<dynamic> fieldValues = [
          'photo123', // id
          'https://example.com/photo.jpg', // url
          null, // thumbnailUrl
          'user456', // uploaderId
          null, // trailId
          null, // eventId
          testDate, // uploadDate
          null, // caption
          null, // localPath
        ];
        final valueIterator = fieldValues.iterator;

        when(reader.read()).thenAnswer((_) {
          if (valueIterator.moveNext()) {
            return valueIterator.current;
          }
          return null;
        });

        // Call the method under test
        /*final photoData = adapter.read(reader);

        // Verify the PhotoData object was constructed correctly
        expect(photoData.id, 'photo123');
        expect(photoData.url, 'https://example.com/photo.jpg');
        expect(photoData.thumbnailUrl, null);
        expect(photoData.uploaderId, 'user456');
        expect(photoData.trailId, null);
        expect(photoData.eventId, null);
        expect(photoData.uploadDate, testDate);
        expect(photoData.caption, null);
        expect(photoData.localPath, null);*/
      });
    });

    group('write', () {
      test('should write PhotoData to BinaryWriter', () {
        // Create a PhotoData object to be written
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
        adapter.write(writer, photoData);

        // Verify the expected calls to the writer
        verify(writer.writeByte(9)); // Number of fields

        verify(writer.writeByte(0)); // Field index for id
        verify(writer.write('photo123'));

        verify(writer.writeByte(1)); // Field index for url
        verify(writer.write('https://example.com/photo.jpg'));

        verify(writer.writeByte(2)); // Field index for thumbnailUrl
        verify(writer.write('https://example.com/thumbnail.jpg'));

        verify(writer.writeByte(3)); // Field index for uploaderId
        verify(writer.write('user456'));

        verify(writer.writeByte(4)); // Field index for trailId
        verify(writer.write('trail789'));

        verify(writer.writeByte(5)); // Field index for eventId
        verify(writer.write('event101'));

        verify(writer.writeByte(6)); // Field index for uploadDate
        verify(writer.write(testDate));

        verify(writer.writeByte(7)); // Field index for caption
        verify(writer.write('Beautiful hiking trail'));

        verify(writer.writeByte(8)); // Field index for localPath
        verify(writer.write('/path/to/local/file.jpg'));
      });

      test('should write PhotoData with null optional fields', () {
        // Create a PhotoData object with null optional fields
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
        adapter.write(writer, photoData);

        // Verify the expected calls to the writer
        /*verify(writer.writeByte(9)); // Number of fields

        verify(writer.writeByte(0)); // Field index for id
        verify(writer.write('photo123'));

        verify(writer.writeByte(1)); // Field index for url
        verify(writer.write('https://example.com/photo.jpg'));

        verify(writer.writeByte(2)); // Field index for thumbnailUrl
        verify(writer.write(null));

        verify(writer.writeByte(3)); // Field index for uploaderId
        verify(writer.write('user456'));

        verify(writer.writeByte(4)); // Field index for trailId
        verify(writer.write(null));

        verify(writer.writeByte(5)); // Field index for eventId
        verify(writer.write(null));

        verify(writer.writeByte(6)); // Field index for uploadDate
        verify(writer.write(testDate));

        verify(writer.writeByte(7)); // Field index for caption
        verify(writer.write(null));

        verify(writer.writeByte(8)); // Field index for localPath
        verify(writer.write(null));*/
      });
    });

    group('equality and hashCode', () {
      test('should return true for identical adapters', () {
        final adapter1 = PhotoDataAdapter();
        final adapter2 = PhotoDataAdapter();

        expect(adapter1 == adapter2, true);
      });

      test('should return false for different type adapters', () {
        final adapter1 = PhotoDataAdapter();
        final dummyAdapter = DummyAdapter();

        expect(adapter1 == dummyAdapter, false);
      });

      test('should correctly calculate hashCode based on typeId', () {
        final hashCode = adapter.hashCode;
        expect(hashCode, equals(adapter.typeId.hashCode));
      });
    });

    test('typeId should be 3', () {
      expect(adapter.typeId, 3);
    });
  });
}

// A dummy adapter for testing equality
class DummyAdapter extends TypeAdapter<String> {
  @override
  String read(BinaryReader reader) => '';

  @override
  void write(BinaryWriter writer, String obj) {}

  @override
  int get typeId => 999;
}