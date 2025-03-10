import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hive/hive.dart';

part 'event_filter.g.dart';

@HiveType(typeId: 7)
class EventFilter {
  @HiveField(0)
  final DateTime? startDate;

  @HiveField(1)
  final DateTime? endDate;

  // Add the new fields needed for events_filter_screen.dart
  final TimeOfDay? startTime;
  final TimeOfDay? endTime;
  final String? timePeriod;
  final LatLng? searchLocation;
  final double? searchRadius;
  final bool includeGoogleEvents;

  @HiveField(2)
  final List<String> categories;

  @HiveField(3)
  final int? minDifficulty;

  @HiveField(4)
  final int? maxDifficulty;

  @HiveField(5)
  final String? location;

  @HiveField(6)
  final double? maxDistance; // in kilometers

  @HiveField(7)
  final double? userLatitude;

  @HiveField(8)
  final double? userLongitude;

  @HiveField(9)
  final bool favoritesOnly;

  @HiveField(10)
  final bool showOnlyFavorites;

  @HiveField(11)
  final String? searchQuery;

  @HiveField(12)
  final String? category;

  @HiveField(13)
  final int? difficultyLevel;

  @HiveField(14)
  final String? locationQuery;

  @HiveField(15)
  final bool includePastEvents;

  @HiveField(16)
  final bool includeCurrentEvents;

  @HiveField(17)
  final bool includeFutureEvents;

  @HiveField(18)
  final double? radiusInKm; // For Google API consistency

  EventFilter({
    this.searchQuery,
    this.startDate,
    this.endDate,
    this.startTime,
    this.endTime,
    this.timePeriod,
    this.searchLocation,
    this.searchRadius,
    this.includeGoogleEvents = false,
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
    this.includePastEvents = false,
    this.includeCurrentEvents = true,
    this.includeFutureEvents = true,
    this.radiusInKm,
  });

  // Create a copy of the filter with some modified fields
  EventFilter copyWith({
    String? searchQuery,
    DateTime? startDate,
    DateTime? endDate,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    String? timePeriod,
    LatLng? searchLocation,
    double? searchRadius,
    bool? includeGoogleEvents,
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
    bool? includePastEvents,
    bool? includeCurrentEvents,
    bool? includeFutureEvents,
    double? radiusInKm,
  }) {
    return EventFilter(
      searchQuery: searchQuery ?? this.searchQuery,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      timePeriod: timePeriod ?? this.timePeriod,
      searchLocation: searchLocation ?? this.searchLocation,
      searchRadius: searchRadius ?? this.searchRadius,
      includeGoogleEvents: includeGoogleEvents ?? this.includeGoogleEvents,
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
      includePastEvents: includePastEvents ?? this.includePastEvents,
      includeCurrentEvents: includeCurrentEvents ?? this.includeCurrentEvents,
      includeFutureEvents: includeFutureEvents ?? this.includeFutureEvents,
      radiusInKm: radiusInKm ?? this.radiusInKm,
    );
  }

  // Reset all filters to default values
  EventFilter resetFilters() {
    return EventFilter();
  }

  // Manual serialization methods instead of using json_annotation
  factory EventFilter.fromMap(Map<String, dynamic> map) {
    return EventFilter(
      searchQuery: map['searchQuery'] as String?,
      startDate: map['startDate'] != null
          ? DateTime.parse(map['startDate'] as String)
          : null,
      endDate: map['endDate'] != null
          ? DateTime.parse(map['endDate'] as String)
          : null,
      categories: map['categories'] != null
          ? List<String>.from(map['categories'] as List)
          : [],
      minDifficulty: map['minDifficulty'] as int?,
      maxDifficulty: map['maxDifficulty'] as int?,
      location: map['location'] as String?,
      maxDistance: map['maxDistance'] as double?,
      userLatitude: map['userLatitude'] as double?,
      userLongitude: map['userLongitude'] as double?,
      favoritesOnly: map['favoritesOnly'] as bool? ?? false,
      showOnlyFavorites: map['showOnlyFavorites'] as bool? ?? false,
      category: map['category'] as String?,
      difficultyLevel: map['difficultyLevel'] as int?,
      locationQuery: map['locationQuery'] as String?,
      includePastEvents: map['includePastEvents'] as bool? ?? false,
      includeCurrentEvents: map['includeCurrentEvents'] as bool? ?? true,
      includeFutureEvents: map['includeFutureEvents'] as bool? ?? true,
      radiusInKm: map['radiusInKm'] as double?,
      includeGoogleEvents: map['includeGoogleEvents'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'searchQuery': searchQuery,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'categories': categories,
      'minDifficulty': minDifficulty,
      'maxDifficulty': maxDifficulty,
      'location': location,
      'maxDistance': maxDistance,
      'userLatitude': userLatitude,
      'userLongitude': userLongitude,
      'favoritesOnly': favoritesOnly,
      'showOnlyFavorites': showOnlyFavorites,
      'category': category,
      'difficultyLevel': difficultyLevel,
      'locationQuery': locationQuery,
      'includePastEvents': includePastEvents,
      'includeCurrentEvents': includeCurrentEvents,
      'includeFutureEvents': includeFutureEvents,
      'radiusInKm': radiusInKm,
      'includeGoogleEvents': includeGoogleEvents,
    };
  }

  @override
  String toString() {
    return 'EventFilter{searchQuery: $searchQuery, startDate: $startDate, endDate: $endDate, categories: $categories, minDifficulty: $minDifficulty, maxDifficulty: $maxDifficulty, location: $location, maxDistance: $maxDistance, userLatitude: $userLatitude, userLongitude: $userLongitude, favoritesOnly: $favoritesOnly, showOnlyFavorites: $showOnlyFavorites, category: $category, difficultyLevel: $difficultyLevel, locationQuery: $locationQuery, includePastEvents: $includePastEvents, includeCurrentEvents: $includeCurrentEvents, includeFutureEvents: $includeFutureEvents, radiusInKm: $radiusInKm, startTime: $startTime, endTime: $endTime, timePeriod: $timePeriod, searchLocation: $searchLocation, searchRadius: $searchRadius, includeGoogleEvents: $includeGoogleEvents}';
  }
}