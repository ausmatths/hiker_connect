import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

// Import the EventFilter class directly
import 'package:hiker_connect/models/event_filter.dart';

// Import main.dart with a prefix to access its EventFilterAdapter
import 'package:hiker_connect/main.dart' as app_main;

// Generate nice mocks
@GenerateNiceMocks([MockSpec<BinaryReader>(), MockSpec<BinaryWriter>()])
import 'main_event_filter_adapter_test.mocks.dart';

void main() {
  group('EventFilterAdapter from main.dart', () {
    late app_main.EventFilterAdapter adapter;
    late MockBinaryReader mockReader;
    late MockBinaryWriter mockWriter;

    setUp(() {
      adapter = app_main.EventFilterAdapter();
      mockReader = MockBinaryReader();
      mockWriter = MockBinaryWriter();
    });

    test('typeId is correct', () {
      expect(adapter.typeId, 7);
    });

    test('hashCode returns correct value', () {
      expect(adapter.hashCode, adapter.typeId.hashCode);
    });

    test('equality operator works correctly', () {
      final adapter1 = app_main.EventFilterAdapter();
      final adapter2 = app_main.EventFilterAdapter();
      final otherObject = 'not an adapter';

      expect(adapter1 == adapter2, isTrue);
      expect(adapter1 == otherObject, isFalse);
    });

    test('adapter can be instantiated', () {
      expect(adapter, isA<app_main.EventFilterAdapter>());
    });

    test('write method can be called', () {
      // Create a simple EventFilter
      final eventFilter = EventFilter(
        startDate: DateTime(2025, 3, 1),
        categories: ['Hiking'],
      );

      // Just verify that calling write doesn't throw an exception
      expect(() => adapter.write(mockWriter, eventFilter), returnsNormally);
    });

    test('can create default adapter', () {
      final defaultAdapter = app_main.EventFilterAdapter();
      expect(defaultAdapter, isNotNull);
      expect(defaultAdapter.typeId, 7);
    });
  });
}