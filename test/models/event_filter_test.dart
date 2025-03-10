import 'package:flutter_test/flutter_test.dart';

// We're including a copy of your original EventFilter class for complete testing
// This is typically not needed in a real test, but this lets us test without Hive dependencies

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
    });

    // Test copyWith
    test('copyWith method', () {
      final filter = EventFilter(searchQuery: 'original');
      final newFilter = filter.copyWith(searchQuery: 'modified');

      expect(newFilter.searchQuery, equals('modified'));
    });

    // Test resetFilters
    test('resetFilters method', () {
      final filter = EventFilter(searchQuery: 'test', favoritesOnly: true);
      final resetFilter = filter.resetFilters();

      expect(resetFilter.searchQuery, isNull);
      expect(resetFilter.favoritesOnly, isFalse);
    });
  });
}

// A minimal implementation - replace with import to your actual class
class EventFilter {
  final DateTime? startDate;
  final DateTime? endDate;
  final List<String> categories;
  final int? minDifficulty;
  final int? maxDifficulty;
  final String? location;
  final double? maxDistance;
  final double? userLatitude;
  final double? userLongitude;
  final bool favoritesOnly;
  final bool showOnlyFavorites;
  final String? searchQuery;
  final String? category;
  final int? difficultyLevel;
  final String? locationQuery;

  EventFilter({
    this.searchQuery,
    this.startDate,
    this.endDate,
    this.categories = const [],
    this.minDifficulty,
    this.maxDifficulty,
    this.location,
    this.maxDistance,
    this.userLatitude,
    this.userLongitude,
    this.favoritesOnly = false,
    this.showOnlyFavorites = false,
    this.category,
    this.difficultyLevel,
    this.locationQuery,
  });

  EventFilter copyWith({
    String? searchQuery,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? categories,
    int? minDifficulty,
    int? maxDifficulty,
    String? location,
    double? maxDistance,
    double? userLatitude,
    double? userLongitude,
    bool? favoritesOnly,
    bool? showOnlyFavorites,
    String? category,
    int? difficultyLevel,
    String? locationQuery,
  }) {
    return EventFilter(
      searchQuery: searchQuery ?? this.searchQuery,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      categories: categories ?? this.categories,
      minDifficulty: minDifficulty ?? this.minDifficulty,
      maxDifficulty: maxDifficulty ?? this.maxDifficulty,
      location: location ?? this.location,
      maxDistance: maxDistance ?? this.maxDistance,
      userLatitude: userLatitude ?? this.userLatitude,
      userLongitude: userLongitude ?? this.userLongitude,
      favoritesOnly: favoritesOnly ?? this.favoritesOnly,
      showOnlyFavorites: showOnlyFavorites ?? this.showOnlyFavorites,
      category: category ?? this.category,
      difficultyLevel: difficultyLevel ?? this.difficultyLevel,
      locationQuery: locationQuery ?? this.locationQuery,
    );
  }

  EventFilter resetFilters() {
    return EventFilter();
  }
}