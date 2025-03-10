import 'package:flutter_test/flutter_test.dart';
import 'package:hiker_connect/main.dart';
import 'package:hive/hive.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

// Import the actual EventFilter class

import 'event_filter_test.dart';
import 'photo_data_adapter_test.mocks.dart';

// Generate mocks
@GenerateMocks([BinaryReader, BinaryWriter])
void main() {
  group('EventFilterAdapter', () {
    late EventFilterAdapter adapter;

    setUp(() {
      adapter = EventFilterAdapter();
    });

    test('typeId is correct', () {
      expect(adapter.typeId, 7);
    });

    test('read method handles full data correctly', () {
      // Create a mock BinaryReader
      final mockReader = MockBinaryReader();

      // Prepare test data
      final testDateTime = DateTime.now();
      final testCategories = ['Category1', 'Category2'];

      // Stub the method calls to simulate reading
      when(mockReader.readByte()).thenReturn(19); // Number of fields

      // Stub reading each field with test values
      /*when(mockReader.read()).thenReturn(// endDate
          testCategories,   // categories
          1,                // minDifficulty
          5,                // maxDifficulty
          'Test Location',  // location
          10.0,             // maxDistance
          40.7128,          // userLatitude
          74.0060,          // userLongitude
          true,             // favoritesOnly
          false,            // showOnlyFavorites
          'Search Query',   // searchQuery
          'Category',       // category
          3,                // difficultyLevel
          'Location Query', // locationQuery
          true,             // includePastEvents
          false,            // includeCurrentEvents
          true,             // includeFutureEvents
          15.0              // radiusInKm
      );*/

      // Perform the read operation
      final eventFilter = adapter.read(mockReader);

      // Verify the read values
      expect(eventFilter.startDate, testDateTime);
      expect(eventFilter.endDate, testDateTime);
      expect(eventFilter.categories, testCategories);
      expect(eventFilter.minDifficulty, 1);
      expect(eventFilter.maxDifficulty, 5);
      expect(eventFilter.location, 'Test Location');
      expect(eventFilter.maxDistance, 10.0);
      expect(eventFilter.userLatitude, 40.7128);
      expect(eventFilter.userLongitude, 74.0060);
      expect(eventFilter.favoritesOnly, isTrue);
      expect(eventFilter.showOnlyFavorites, isFalse);
      expect(eventFilter.searchQuery, 'Search Query');
      expect(eventFilter.category, 'Category');
      expect(eventFilter.difficultyLevel, 3);
      expect(eventFilter.locationQuery, 'Location Query');
      expect(eventFilter.includePastEvents, isTrue);
      expect(eventFilter.includeCurrentEvents, isFalse);
      expect(eventFilter.includeFutureEvents, isTrue);
      expect(eventFilter.radiusInKm, 15.0);
    });

    test('write method writes all fields correctly', () {
      // Create a mock BinaryWriter
      final mockWriter = MockBinaryWriter();

      // Create an EventFilter with test data
      final eventFilter = EventFilter(
          startDate: DateTime.now(),
          endDate: DateTime.now(),
          categories: ['Category1', 'Category2'],
          minDifficulty: 1,
          maxDifficulty: 5,
          location: 'Test Location',
          maxDistance: 10.0,
          userLatitude: 40.7128,
          userLongitude: 74.0060,
          favoritesOnly: true,
          showOnlyFavorites: false,
          searchQuery: 'Search Query',
          category: 'Category',
          difficultyLevel: 3,
          locationQuery: 'Location Query',
      );

      // Perform write operation
      //adapter.write(mockWriter, eventFilter);

      // Verify write method calls
      verify(mockWriter.writeByte(19)).called(1);  // Total number of fields
      verify(mockWriter.writeByte(0)).called(1);   // First field index
    });

    test('hashCode returns correct value', () {
      expect(adapter.hashCode, adapter.typeId.hashCode);
    });

    test('equality operator works correctly', () {
      final adapter1 = EventFilterAdapter();
      final adapter2 = EventFilterAdapter();

      expect(adapter1 == adapter2, isTrue);
      expect(adapter1 == 'not an adapter', isFalse);
    });

    test('read method handles minimal fields', () {
      // Create a mock BinaryReader
      final mockReader = MockBinaryReader();

      // Stub minimal field reading
      when(mockReader.readByte()).thenReturn(1);  // Single field
      when(mockReader.read()).thenReturn(null);

      // Perform read operation
      final eventFilter = adapter.read(mockReader);

      // Verify default values
      expect(eventFilter.categories, isEmpty);
      expect(eventFilter.favoritesOnly, isFalse);
      expect(eventFilter.showOnlyFavorites, isFalse);
      expect(eventFilter.includePastEvents, isFalse);
      expect(eventFilter.includeCurrentEvents, isFalse);
      expect(eventFilter.includeFutureEvents, isFalse);
    });
  });
}