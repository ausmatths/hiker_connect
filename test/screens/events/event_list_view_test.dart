import 'package:flutter_test/flutter_test.dart';
import 'package:googleapis/calendar/v3.dart';
//import 'package:your_package_name/models/event.dart'; // Adjust the import path

void main() {
  group('EventSource Tests', () {
    test('should create EventSource with given values', () {
      final source = EventSource(title: 'Google Calendar', url: 'https://calendar.google.com');

      expect(source.title, 'Google Calendar');
      expect(source.url, 'https://calendar.google.com');
    });

    test('should serialize EventSource to JSON', () {
      final source = EventSource(title: 'Google Calendar', url: 'https://calendar.google.com');
      final json = source.toJson();

      expect(json, {
        'title': 'Google Calendar',
        'url': 'https://calendar.google.com',
      });
    });

    test('should deserialize JSON to EventSource', () {
      final json = {'title': 'Google Calendar', 'url': 'https://calendar.google.com'};
      final source = EventSource.fromJson(json);

      expect(source.title, 'Google Calendar');
      expect(source.url, 'https://calendar.google.com');
    });

    test('should handle null values correctly', () {
      final json = {};
      final source = EventSource.fromJson(json);

      expect(source.title, isNull);
      expect(source.url, isNull);
    });
  });

  group('Event Tests', () {
    test('should create an Event with given values', () {
      final event = Event(
        summary: 'Meeting',
        location: 'New York',
        status: 'confirmed',
        start: EventDateTime(dateTime: DateTime(2025, 3, 10)),
        end: EventDateTime(dateTime: DateTime(2025, 3, 10, 14, 30)),
      );

      expect(event.summary, 'Meeting');
      expect(event.location, 'New York');
      expect(event.status, 'confirmed');
      expect(event.start?.dateTime, DateTime(2025, 3, 10));
      expect(event.end?.dateTime, DateTime(2025, 3, 10, 14, 30));
    });

    test('should serialize Event to JSON', () {
      final event = Event(
        summary: 'Meeting',
        location: 'New York',
        status: 'confirmed',
        start: EventDateTime(dateTime: DateTime(2025, 3, 10)),
        end: EventDateTime(dateTime: DateTime(2025, 3, 10, 14, 30)),
      );

      final json = event.toJson();

      expect(json['summary'], 'Meeting');
      expect(json['location'], 'New York');
      expect(json['status'], 'confirmed');
      expect(json['start'], isNotNull);
      expect(json['end'], isNotNull);
    });

    test('should deserialize JSON to Event', () {
      final json = {
        'summary': 'Meeting',
        'location': 'New York',
        'status': 'confirmed',
        'start': {'dateTime': '2025-03-10T00:00:00.000'},
        'end': {'dateTime': '2025-03-10T14:30:00.000'},
      };

      final event = Event.fromJson(json);

      expect(event.summary, 'Meeting');
      expect(event.location, 'New York');
      expect(event.status, 'confirmed');
      expect(event.start?.dateTime, DateTime.parse('2025-03-10T00:00:00.000'));
      expect(event.end?.dateTime, DateTime.parse('2025-03-10T14:30:00.000'));
    });

    test('should handle null values correctly in Event', () {
      final json = {};
      final event = Event.fromJson(json);

      expect(event.summary, isNull);
      expect(event.location, isNull);
      expect(event.status, isNull);
      expect(event.start, isNull);
      expect(event.end, isNull);
    });
  });
}
