import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hiker_connect/models/event_filter.dart';

void main() {
  group('EventFilter Basic Tests', () {
    // Test creating an instance
    test('Create instance', () {
      final now = DateTime.now();
      final filter = EventFilter(
        searchQuery: 'test',
        startDate: now,
        categories: ['cat1', 'cat2'],
        favoritesOnly: true,
      );

      expect(filter.searchQuery, equals('test'));
      expect(filter.startDate, equals(now));
      expect(filter.categories, equals(['cat1', 'cat2']));
      expect(filter.favoritesOnly, isTrue);
    });

    // Test default values
    test('Default values', () {
      final filter = EventFilter();

      expect(filter.searchQuery, isNull);
      expect(filter.startDate, isNull);
      expect(filter.categories, isEmpty);
      expect(filter.favoritesOnly, isFalse);
      expect(filter.includeGoogleEvents, isFalse);
      expect(filter.includeCurrentEvents, isTrue);
      expect(filter.includeFutureEvents, isTrue);
      expect(filter.includePastEvents, isFalse);
    });

    // Test copyWith
    test('copyWith method', () {
      final filter = EventFilter(searchQuery: 'original');
      final newFilter = filter.copyWith(searchQuery: 'modified');

      expect(newFilter.searchQuery, equals('modified'));
      expect(newFilter.includeGoogleEvents, equals(filter.includeGoogleEvents));
    });

    // Test resetFilters
    test('resetFilters method', () {
      final filter = EventFilter(
          searchQuery: 'test',
          favoritesOnly: true,
          includeGoogleEvents: true,
          includePastEvents: true
      );
      final resetFilter = filter.resetFilters();

      expect(resetFilter.searchQuery, isNull);
      expect(resetFilter.favoritesOnly, isFalse);
      expect(resetFilter.includeGoogleEvents, isFalse);
      expect(resetFilter.includePastEvents, isFalse);
    });

    // New tests for added fields
    test('TimeOfDay fields', () {
      final startTime = TimeOfDay(hour: 9, minute: 0);
      final endTime = TimeOfDay(hour: 17, minute: 30);
      final filter = EventFilter(
        startTime: startTime,
        endTime: endTime,
        timePeriod: 'Morning',
      );

      expect(filter.startTime, equals(startTime));
      expect(filter.endTime, equals(endTime));
      expect(filter.timePeriod, equals('Morning'));
    });

    test('Location fields', () {
      final location = LatLng(47.6062, -122.3321); // Seattle
      final filter = EventFilter(
        searchLocation: location,
        searchRadius: 25.0,
        radiusInKm: 25.0,
      );

      expect(filter.searchLocation, equals(location));
      expect(filter.searchRadius, equals(25.0));
      expect(filter.radiusInKm, equals(25.0));
    });

    test('Event time inclusion flags', () {
      final filter = EventFilter(
        includePastEvents: true,
        includeCurrentEvents: false,
        includeFutureEvents: true,
      );

      expect(filter.includePastEvents, isTrue);
      expect(filter.includeCurrentEvents, isFalse);
      expect(filter.includeFutureEvents, isTrue);
    });

    test('toMap and fromMap', () {
      final now = DateTime.now();
      final original = EventFilter(
        searchQuery: 'hiking',
        startDate: now,
        endDate: now.add(Duration(days: 7)),
        categories: ['Hiking', 'Camping'],
        difficultyLevel: 3,
        location: 'Mountain Range',
        favoritesOnly: true,
        includeGoogleEvents: true,
        radiusInKm: 50.0,
      );

      final map = original.toMap();
      final restored = EventFilter.fromMap(map);

      expect(restored.searchQuery, equals('hiking'));
      expect(restored.startDate?.day, equals(now.day));
      expect(restored.endDate?.day, equals(now.add(Duration(days: 7)).day));
      expect(restored.categories, equals(['Hiking', 'Camping']));
      expect(restored.difficultyLevel, equals(3));
      expect(restored.location, equals('Mountain Range'));
      expect(restored.favoritesOnly, isTrue);
      expect(restored.includeGoogleEvents, isTrue);
      expect(restored.radiusInKm, equals(50.0));
    });

    test('toString includes all fields', () {
      final filter = EventFilter(
        searchQuery: 'test',
        startDate: DateTime(2023, 1, 1),
        includeGoogleEvents: true,
      );

      final stringRepresentation = filter.toString();

      expect(stringRepresentation.contains('searchQuery: test'), isTrue);
      expect(stringRepresentation.contains('startDate: 2023'), isTrue);
      expect(stringRepresentation.contains('includeGoogleEvents: true'), isTrue);
    });

    test('copyWith preserves unmodified fields', () {
      final original = EventFilter(
          searchQuery: 'original',
          startDate: DateTime(2023, 1, 1),
          categories: ['Hiking'],
          difficultyLevel: 2,
          includeGoogleEvents: false
      );

      final modified = original.copyWith(
          searchQuery: 'updated',
          includeGoogleEvents: true
      );

      // Modified fields
      expect(modified.searchQuery, equals('updated'));
      expect(modified.includeGoogleEvents, isTrue);

      // Unmodified fields preserved
      expect(modified.startDate, equals(original.startDate));
      expect(modified.categories, equals(original.categories));
      expect(modified.difficultyLevel, equals(original.difficultyLevel));
    });

    // Additional tests for edge cases

    test('handles null values in toMap and fromMap', () {
      final filter = EventFilter(); // All nullable fields are null
      final map = filter.toMap();
      final restored = EventFilter.fromMap(map);

      // Verify all nullable fields remain null
      expect(restored.searchQuery, isNull);
      expect(restored.startDate, isNull);
      expect(restored.endDate, isNull);
      expect(restored.location, isNull);
      expect(restored.category, isNull);
      expect(restored.locationQuery, isNull);
    });

    test('date/time serialization handles timezone correctly', () {
      final originalDate = DateTime.utc(2023, 6, 15, 10, 30); // UTC time
      final filter = EventFilter(startDate: originalDate);

      final map = filter.toMap();
      final restored = EventFilter.fromMap(map);

      // Verify the date is preserved, including hours and minutes
      expect(restored.startDate?.year, equals(originalDate.year));
      expect(restored.startDate?.month, equals(originalDate.month));
      expect(restored.startDate?.day, equals(originalDate.day));
      expect(restored.startDate?.hour, equals(originalDate.hour));
      expect(restored.startDate?.minute, equals(originalDate.minute));
    });

    test('copyWith handles complex nested objects', () {
      final location = LatLng(42.3601, -71.0589); // Boston
      final original = EventFilter(searchLocation: location);

      // Create a new LatLng
      final newLocation = LatLng(40.7128, -74.0060); // New York
      final modified = original.copyWith(searchLocation: newLocation);

      // Verify the location was updated
      expect(modified.searchLocation?.latitude, equals(40.7128));
      expect(modified.searchLocation?.longitude, equals(-74.0060));
    });
  });
}