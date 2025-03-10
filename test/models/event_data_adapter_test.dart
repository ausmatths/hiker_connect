import 'package:flutter_test/flutter_test.dart';
import 'package:hiker_connect/models/event_data.dart';
import 'package:hive/hive.dart';
import 'dart:io';



void main() {
  group('EventData Hive Tests', () {
    late Box<EventData> box;

    setUp(() async {
      final tempDir = await Directory.systemTemp.createTemp('hive_tests');
      Hive.init(tempDir.path);

      // Register the adapter if not already registered
      if (!Hive.isAdapterRegistered(4)) {
        Hive.registerAdapter(EventDataAdapter());
      }

      // Open the box
      box = await Hive.openBox<EventData>('eventBox');
    });

    tearDown(() async {
      await box.clear();
      await box.close();
      await Hive.deleteFromDisk();
    });



    test('Save and load EventData with minimum fields', () async {
      // Create minimal test data
      final eventData = EventData(
        id: 'min-id',
        title: 'Minimal Event',
        eventDate: DateTime.now(),
      );

      // Save to box
      await box.put('key2', eventData);

      // Load from box
      final loadedData = box.get('key2');

      // Verify required fields
      expect(loadedData?.id, eventData.id);
      expect(loadedData?.title, eventData.title);
      expect(loadedData?.eventDate.toIso8601String(), eventData.eventDate.toIso8601String());

      // Verify optional fields are null
      expect(loadedData?.description, null);
      expect(loadedData?.location, null);
      expect(loadedData?.participantLimit, null);
      expect(loadedData?.attendees, null);
    });

    test('Save and load EventData with empty lists', () async {
      // Create test data with empty lists
      final eventData = EventData(
        id: 'empty-list-id',
        title: 'Empty List Event',
        eventDate: DateTime.now(),
        attendees: [],
      );

      // Save to box
      await box.put('key3', eventData);

      // Load from box
      final loadedData = box.get('key3');

      // Verify empty list
      expect(loadedData?.attendees, isNotNull);
      expect(loadedData?.attendees, isEmpty);
    });

    test('Update existing EventData', () async {
      // Create initial data
      final initialData = EventData(
        id: 'update-id',
        title: 'Initial Title',
        eventDate: DateTime.now(),
      );

      // Save initial data
      await box.put('key4', initialData);

      // Create updated data
      final updatedData = EventData(
        id: 'update-id',
        title: 'Updated Title',
        eventDate: DateTime.now(),
        description: 'Added description',
      );

      // Update data
      await box.put('key4', updatedData);

      // Load updated data
      final loadedData = box.get('key4');

      // Verify updates
      expect(loadedData?.id, updatedData.id);
      expect(loadedData?.title, 'Updated Title');
      expect(loadedData?.description, 'Added description');
    });

    test('Store multiple EventData objects', () async {
      // Create multiple events
      final event1 = EventData(
        id: 'id1',
        title: 'Event 1',
        eventDate: DateTime.now(),
        category: 'Category A',
      );

      final event2 = EventData(
        id: 'id2',
        title: 'Event 2',
        eventDate: DateTime.now(),
        category: 'Category B',
      );

      // Save events
      await box.putAll({
        'key5': event1,
        'key6': event2,
      });

      // Load events
      final loadedEvent1 = box.get('key5');
      final loadedEvent2 = box.get('key6');

      // Verify events
      expect(loadedEvent1?.id, 'id1');
      expect(loadedEvent1?.category, 'Category A');

      expect(loadedEvent2?.id, 'id2');
      expect(loadedEvent2?.category, 'Category B');
    });

    // Test adapter properties directly
    test('EventDataAdapter properties', () {
      final adapter = EventDataAdapter();

      expect(adapter.typeId, 4);

      // Test equality operator
      final sameAdapter = EventDataAdapter();
      final differentObject = Object();

      expect(adapter == sameAdapter, true);
      expect(adapter == adapter, true); // identical
      expect(adapter == differentObject, false);

      // Test hashCode
      expect(adapter.hashCode, adapter.typeId.hashCode);
    });
  });
}