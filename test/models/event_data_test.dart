import 'package:flutter_test/flutter_test.dart';
import 'package:hiker_connect/models/event_data.dart'; // Adjust the import path as needed

void main() {
  group('EventData Model Tests', () {
    // Test data
    final DateTime testDate = DateTime(2023, 10, 15);
    final Duration testDuration = Duration(hours: 2);

    // Create a sample EventData object
    final eventData = EventData(
      eventId: 1,
      eventName: 'Hiking Trip',
      eventDescription: 'A fun hiking trip to the mountains.',
      eventDate: testDate,
      eventLocation: 'Mountain Trail',
      evenParticipantNumber: 10,
      eventDuration: testDuration,
    );

    test('Object Initialization', () {
      // Verify that the object is initialized correctly
      expect(eventData.eventId, 1);
      expect(eventData.eventName, 'Hiking Trip');
      expect(eventData.eventDescription, 'A fun hiking trip to the mountains.');
      expect(eventData.eventDate, testDate);
      expect(eventData.eventLocation, 'Mountain Trail');
      expect(eventData.evenParticipantNumber, 10);
      expect(eventData.eventDuration, testDuration);
    });

    test('Equality Check', () {
      // Create another EventData object with the same properties
      final eventData2 = EventData(
        eventId: 1,
        eventName: 'Hiking Trip',
        eventDescription: 'A fun hiking trip to the mountains.',
        eventDate: testDate,
        eventLocation: 'Mountain Trail',
        evenParticipantNumber: 10,
        eventDuration: testDuration,
      );

      // Verify that the two objects are equal
      expect(eventData, eventData);
    });

    test('Inequality Check', () {
      // Create another EventData object with different properties
      final eventData3 = EventData(
        eventId: 2,
        eventName: 'Camping Trip',
        eventDescription: 'A relaxing camping trip.',
        eventDate: DateTime(2023, 11, 20),
        eventLocation: 'Forest Camp',
        evenParticipantNumber: 5,
        eventDuration: Duration(hours: 3),
      );

      // Verify that the two objects are not equal
      expect(eventData, isNot(eventData3));
    });

  });
}