import 'package:flutter_test/flutter_test.dart';
import 'package:hiker_connect/models/event_data.dart';

void main() {
  group('EventData Model Tests', () {
    // Test data
    final DateTime testDate = DateTime(2023, 10, 15);
    final Duration testDuration = Duration(hours: 2);

    // Create a sample EventData object using the legacy constructor
    final eventData = EventData.legacy(
      eventId: 1,
      eventName: 'Hiking Trip',
      eventDescription: 'A fun hiking trip to the mountains.',
      eventDate: testDate,
      eventLocation: 'Mountain Trail',
      evenParticipantNumber: 10,
      eventDuration: testDuration,
    );

    test('Object Initialization with Legacy Constructor', () {
      // Verify that the object is initialized correctly with the legacy constructor
      expect(eventData.id, '1');
      expect(eventData.title, 'Hiking Trip');
      expect(eventData.description, 'A fun hiking trip to the mountains.');
      expect(eventData.startDate, testDate);
      expect(eventData.location, 'Mountain Trail');
      expect(eventData.participantLimit, 10);
      expect(eventData.duration, testDuration);
    });

    test('Direct Initialization with New Field Names', () {
      // Create EventData object with the new field names
      final directEventData = EventData(
        id: '1',
        title: 'Hiking Trip',
        description: 'A fun hiking trip to the mountains.',
        startDate: testDate,
        location: 'Mountain Trail',
        participantLimit: 10,
        duration: testDuration,
      );

      // Verify direct initialization works
      expect(directEventData.id, '1');
      expect(directEventData.title, 'Hiking Trip');
      expect(directEventData.description, 'A fun hiking trip to the mountains.');
      expect(directEventData.startDate, testDate);
      expect(directEventData.location, 'Mountain Trail');
      expect(directEventData.participantLimit, 10);
      expect(directEventData.duration, testDuration);
    });

    test('Equality Check', () {
      // Create another EventData object with the same properties
      final eventData2 = EventData.legacy(
        eventId: 1,
        eventName: 'Hiking Trip',
        eventDescription: 'A fun hiking trip to the mountains.',
        eventDate: testDate,
        eventLocation: 'Mountain Trail',
        evenParticipantNumber: 10,
        eventDuration: testDuration,
      );

      // Verify that the two objects are equal
      expect(eventData, eventData2);
    });

    test('Inequality Check', () {
      // Create another EventData object with different properties
      final eventData3 = EventData.legacy(
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

    test('EventBrite Constructor', () {
      // Sample JSON response from EventBrite
      final Map<String, dynamic> eventbriteJson = {
        'id': '12345',
        'name': {'text': 'Mountain Hiking Adventure'},
        'description': {'text': 'Experience the beautiful mountain trails'},
        'start': {'utc': '2023-10-15T09:00:00Z'},
        'end': {'utc': '2023-10-15T11:00:00Z'},
        'venue': {
          'id': 'venue123',
          'address': {
            'address_1': '123 Mountain View',
            'city': 'Boulder',
            'region': 'CO',
            'postal_code': '80302'
          }
        },
        'organizer': {
          'id': 'org123',
          'name': 'Mountain Hikers Club'
        },
        'is_free': true,
        'url': 'https://eventbrite.com/event/12345'
      };

      // Create EventData using the EventBrite constructor
      final eventbriteData = EventData.fromEventBrite(eventbriteJson);

      // Verify EventBrite initialization
      expect(eventbriteData.id, '12345');
      expect(eventbriteData.title, 'Mountain Hiking Adventure');
      expect(eventbriteData.description, 'Experience the beautiful mountain trails');
      expect(eventbriteData.isFree, true);
      expect(eventbriteData.url, 'https://eventbrite.com/event/12345');
      expect(eventbriteData.venueId, 'venue123');
      expect(eventbriteData.organizerId, 'org123');
      expect(eventbriteData.organizer, 'Mountain Hikers Club');

      // Check location formatting
      expect(eventbriteData.location, contains('Boulder'));
      expect(eventbriteData.location, contains('CO'));
    });

    test('Formatting Methods', () {
      // Create a sample event with start and end date
      final eventWithDates = EventData(
        id: '1',
        title: 'Test Event',
        startDate: DateTime(2023, 10, 15, 10, 0),
        endDate: DateTime(2023, 10, 15, 12, 0),
        duration: const Duration(hours: 2),
      );

      // Test date formatting
      expect(eventWithDates.getFormattedStartDate(), contains('Oct 15, 2023'));

      // Test date range formatting (same day)
      expect(eventWithDates.getFormattedDateRange(), contains('10:00 AM - 12:00 PM'));

      // Test duration formatting
      expect(eventWithDates.getFormattedDuration(), equals('2 hours'));
    });
  });
}