// lib/providers/event_browsing_provider.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import '../models/event_data.dart';
import '../models/event_filter.dart';
import '../services/databaseservice.dart';
import '../services/google_events_service.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

enum EventViewType { list, grid, map }
enum EventSortOption { dateAsc, dateDesc, popularity, distance }
enum EventTimeOption { past, current, future, all }

class EventBrowsingProvider with ChangeNotifier {
  final DatabaseService _databaseService;
  final GoogleEventsService? _googleEventsService;

  List<EventData> _allEvents = [];
  List<EventData> _filteredEvents = [];
  List<EventData> _googleEvents = [];
  Set<String> _favoriteEventIds = {};

  EventViewType _currentViewType = EventViewType.list;
  EventSortOption _sortOption = EventSortOption.dateAsc;
  EventTimeOption _timeOption = EventTimeOption.all;

  EventFilter _currentFilter = EventFilter();
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMoreEvents = false;
  bool _showTimeSince = false;
  bool _showCompactView = false;

  int _page = 1;
  final int _pageSize = 20;
  String? _errorMessage;

  LatLng? _userLocation;

  EventBrowsingProvider({
    required DatabaseService databaseService,
    GoogleEventsService? googleEventsService,
    LatLng? initialUserLocation,
  }) :
        _databaseService = databaseService,
        _googleEventsService = googleEventsService,
        _userLocation = initialUserLocation {
    _initializeEvents();
  }

  // Getters
  List<EventData> get events => _filteredEvents;
  EventViewType get viewType => _currentViewType;
  EventFilter get filter => _currentFilter;
  EventSortOption get sortOption => _sortOption;
  EventTimeOption get timeOption => _timeOption;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMoreEvents => _hasMoreEvents;
  bool get showTimeSince => _showTimeSince;
  bool get showCompactView => _showCompactView;
  String? get errorMessage => _errorMessage;
  LatLng? get userLocation => _userLocation;

  bool isFavorite(String eventId) => _favoriteEventIds.contains(eventId);

  // Initialize events
  Future<void> _initializeEvents() async {
    _setLoading(true);
    try {
      await Future.wait([
        _loadLocalEvents(),
        _loadFavorites(),
        if (_currentFilter.includeGoogleEvents) _loadGoogleEvents(),
      ]);

      _applyFilters();
      _hasMoreEvents = _allEvents.length > _pageSize;
    } catch (e) {
      _errorMessage = 'Failed to load events: ${e.toString()}';
    } finally {
      _setLoading(false);
    }
  }

  // Load local events from database
  Future<void> _loadLocalEvents() async {
    try {
      _page = 1;
      // Call getAllEvents without the extra parameters that don't exist
      _allEvents = await _databaseService.getAllEvents();

      // Apply filtering in memory instead
      _filterEventsByCurrentFilter();
    } catch (e) {
      debugPrint('Error loading local events: $e');
      rethrow;
    }
  }

  // Load Google events if enabled
  Future<void> _loadGoogleEvents() async {
    if (_googleEventsService == null) return;

    try {
      final location = _currentFilter.searchLocation ?? _userLocation;
      final radius = _currentFilter.searchRadius ?? 10.0;

      if (location != null) {
        // Adjust parameters based on what the service actually accepts
        _googleEvents = await _googleEventsService!.getNearbyEvents(
          latitude: location.latitude,
          longitude: location.longitude,
          radiusInKm: radius,
          keyword: _currentFilter.searchQuery,
          // Remove category parameter if it doesn't exist
        );
      }
    } catch (e) {
      debugPrint('Error loading Google events: $e');
      // Don't rethrow - we can still show local events
    }
  }

  // Load user favorites
  Future<void> _loadFavorites() async {
    try {
      final userFavorites = await _databaseService.getUserFavoriteEvents();
      _favoriteEventIds = Set.from(userFavorites);
    } catch (e) {
      debugPrint('Error loading favorites: $e');
    }
  }

  // Filter events based on the current filter in memory
  void _filterEventsByCurrentFilter() {
    // This is a helper method to filter events in memory
    // when direct database filtering is not available
  }

  // Load more events (pagination)
  Future<void> loadMoreEvents() async {
    if (_isLoadingMore || !_hasMoreEvents) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      _page++;
      // Since pagination parameters aren't supported, we'll simulate
      // pagination by loading all events and then filtering in memory
      final allEvents = await _databaseService.getAllEvents();

      // Only add new events that aren't already in our list
      final existingIds = _allEvents.map((e) => e.id).toSet();
      final moreEvents = allEvents
          .where((event) => !existingIds.contains(event.id))
          .take(_pageSize)
          .toList();

      if (moreEvents.isNotEmpty) {
        _allEvents.addAll(moreEvents);
        _applyFilters();
      }

      _hasMoreEvents = moreEvents.length >= _pageSize;
    } catch (e) {
      _errorMessage = 'Failed to load more events: ${e.toString()}';
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  // Refresh events
  Future<void> refreshEvents() async {
    await _initializeEvents();
  }

  // Toggle view type (list, grid, map)
  void setViewType(EventViewType viewType) {
    _currentViewType = viewType;
    notifyListeners();
  }

  // Set sort option
  void setSortOption(EventSortOption option) {
    _sortOption = option;
    _applyFilters(); // Re-sort the events
    notifyListeners();
  }

  // Set time filter option
  void setTimeOption(EventTimeOption option) {
    _timeOption = option;
    _applyFilters(); // Re-filter by time
    notifyListeners();
  }

  // Toggle showing time since
  void toggleTimeSince() {
    _showTimeSince = !_showTimeSince;
    notifyListeners();
  }

  // Toggle compact view
  void toggleCompactView() {
    _showCompactView = !_showCompactView;
    notifyListeners();
  }

  // Update user location
  void updateUserLocation(LatLng location) {
    _userLocation = location;
    if (_sortOption == EventSortOption.distance) {
      _applyFilters(); // Re-sort by distance
    }
    notifyListeners();
  }

  // Apply filters
  void applyFilter(EventFilter filter) {
    _currentFilter = filter;

    // If we're changing whether to include Google events, reload
    if (filter.includeGoogleEvents != _currentFilter.includeGoogleEvents) {
      _initializeEvents();
    } else {
      _applyFilters();
    }

    notifyListeners();
  }

  // Reset all filters
  void resetFilters() {
    final wasIncludingGoogleEvents = _currentFilter.includeGoogleEvents;
    _currentFilter = EventFilter();

    if (wasIncludingGoogleEvents != _currentFilter.includeGoogleEvents) {
      _initializeEvents();
    } else {
      _applyFilters();
    }

    notifyListeners();
  }

  // Toggle favorite status
  Future<void> toggleFavorite(String eventId) async {
    try {
      if (_favoriteEventIds.contains(eventId)) {
        await _databaseService.removeEventFromFavorites(eventId);
        _favoriteEventIds.remove(eventId);
      } else {
        await _databaseService.addEventToFavorites(eventId);
        _favoriteEventIds.add(eventId);
      }

      // If showing only favorites, we need to reapply filters
      if (_currentFilter.showOnlyFavorites) {
        _applyFilters();
      }

      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to update favorite: ${e.toString()}';
      notifyListeners();
    }
  }

  // Helper method to apply current filters
  void _applyFilters() {
    // Combine all events from database and Google (if enabled)
    var allSourceEvents = [..._allEvents];
    if (_currentFilter.includeGoogleEvents) {
      allSourceEvents.addAll(_googleEvents);
    }

    _filteredEvents = allSourceEvents.where((event) {
      // Filter by favorites if enabled
      if (_currentFilter.showOnlyFavorites &&
          !_favoriteEventIds.contains(event.id)) {
        return false;
      }

      // Filter by search query
      if (_currentFilter.searchQuery != null &&
          _currentFilter.searchQuery!.isNotEmpty) {
        final query = _currentFilter.searchQuery!.toLowerCase();
        if (!event.title.toLowerCase().contains(query) &&
            !(event.description?.toLowerCase() ?? '').contains(query) &&
            !(event.location?.toLowerCase() ?? '').contains(query)) {
          return false;
        }
      }

      // Filter by date range
      if (_currentFilter.startDate != null) {
        final DateTime startDateTime = _combineDateTime(
          _currentFilter.startDate!,
          _currentFilter.startTime,
        );
        if (event.eventDate.isBefore(startDateTime)) {
          return false;
        }
      }

      if (_currentFilter.endDate != null) {
        final DateTime endDateTime = _combineDateTime(
          _currentFilter.endDate!,
          _currentFilter.endTime,
          isEndTime: true,
        );
        if (event.eventDate.isAfter(endDateTime)) {
          return false;
        }
      }

      // Filter by time period
      if (_currentFilter.timePeriod != null) {
        final eventTime = TimeOfDay.fromDateTime(event.eventDate);

        switch (_currentFilter.timePeriod) {
          case 'Morning':
            if (eventTime.hour < 6 || eventTime.hour >= 12) {
              return false;
            }
            break;
          case 'Afternoon':
            if (eventTime.hour < 12 || eventTime.hour >= 17) {
              return false;
            }
            break;
          case 'Evening':
            if (eventTime.hour < 17 || eventTime.hour >= 23) {
              return false;
            }
            break;
        }
      }

      // Filter by event time option (past, current, future)
      final now = DateTime.now();

      switch (_timeOption) {
        case EventTimeOption.past:
          if (!event.eventDate.isBefore(now)) {
            return false;
          }
          break;
        case EventTimeOption.current:
          final isToday = event.eventDate.year == now.year &&
              event.eventDate.month == now.month &&
              event.eventDate.day == now.day;
          if (!isToday) {
            return false;
          }
          break;
        case EventTimeOption.future:
          if (!event.eventDate.isAfter(now)) {
            return false;
          }
          break;
        case EventTimeOption.all:
        // Show all if not explicitly set to include past events
          if (!_currentFilter.includePastEvents && event.eventDate.isBefore(now)) {
            return false;
          }
          break;
      }

      // Filter by category
      if (_currentFilter.category != null &&
          _currentFilter.category!.isNotEmpty) {
        if (event.category != _currentFilter.category) {
          return false;
        }
      }

      // Filter by difficulty level
      if (_currentFilter.difficultyLevel != null) {
        if (event.difficulty != _currentFilter.difficultyLevel) {
          return false;
        }
      }

      // Filter by location search
      if (_currentFilter.locationQuery != null &&
          _currentFilter.locationQuery!.isNotEmpty) {
        if (event.location == null ||
            !event.location!.toLowerCase().contains(_currentFilter.locationQuery!.toLowerCase())) {
          return false;
        }
      }

      // Filter by radius search
      if (_currentFilter.searchLocation != null &&
          _currentFilter.searchRadius != null &&
          event.latitude != null &&
          event.longitude != null) {
        final distance = _calculateDistance(
          _currentFilter.searchLocation!.latitude,
          _currentFilter.searchLocation!.longitude,
          event.latitude!,
          event.longitude!,
        );

        if (distance > _currentFilter.searchRadius!) {
          return false;
        }
      }

      // Filter by maximum distance from user
      if (_userLocation != null &&
          _currentFilter.maxDistance != null &&
          event.latitude != null &&
          event.longitude != null) {
        final distance = _calculateDistance(
          _userLocation!.latitude,
          _userLocation!.longitude,
          event.latitude!,
          event.longitude!,
        );

        if (distance > _currentFilter.maxDistance!) {
          return false;
        }
      }

      return true;
    }).toList();

    // Apply sorting
    switch (_sortOption) {
      case EventSortOption.dateAsc:
        _filteredEvents.sort((a, b) => a.eventDate.compareTo(b.eventDate));
        break;
      case EventSortOption.dateDesc:
        _filteredEvents.sort((a, b) => b.eventDate.compareTo(a.eventDate));
        break;
      case EventSortOption.popularity:
        _filteredEvents.sort((a, b) =>
            (b.attendees?.length ?? 0).compareTo(a.attendees?.length ?? 0));
        break;
      case EventSortOption.distance:
        if (_userLocation != null) {
          _filteredEvents.sort((a, b) {
            if (a.latitude == null || a.longitude == null) return 1;
            if (b.latitude == null || b.longitude == null) return -1;

            final distanceA = _calculateDistance(
              _userLocation!.latitude,
              _userLocation!.longitude,
              a.latitude!,
              a.longitude!,
            );
            final distanceB = _calculateDistance(
              _userLocation!.latitude,
              _userLocation!.longitude,
              b.latitude!,
              b.longitude!,
            );

            return distanceA.compareTo(distanceB);
          });
        }
        break;
    }
  }

  // Helper to set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    if (loading) {
      _errorMessage = null;
    }
    notifyListeners();
  }

  // Helper to combine date and time
  DateTime _combineDateTime(DateTime date, TimeOfDay? time, {bool isEndTime = false}) {
    if (time == null) {
      // If no time provided, use start or end of day
      return isEndTime
          ? DateTime(date.year, date.month, date.day, 23, 59, 59)
          : DateTime(date.year, date.month, date.day);
    }
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  // Calculate distance between two coordinates (Haversine formula)
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371.0; // Earth radius in kilometers
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a =
        sin(dLat / 2) * sin(dLat / 2) +
            cos(_toRadians(lat1)) * cos(_toRadians(lat2)) *
                sin(dLon / 2) * sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c; // Distance in km
  }

  double _toRadians(double degree) {
    return degree * (pi / 180);
  }
}