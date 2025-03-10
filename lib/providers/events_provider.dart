import 'package:flutter/foundation.dart';
import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event_data.dart';
import '../models/event_filter.dart';
import '../services/google_events_service.dart';
import '../models/events_view_type.dart';
import '../services/databaseservice.dart';

class EventsProvider with ChangeNotifier {
  final GoogleEventsService _googleEventsService;
  final DatabaseService _databaseService;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<EventData> _events = [];
  List<EventData> _filteredEvents = [];
  EventFilter? _activeFilter;
  bool _isLoading = false;
  String? _error;
  bool _isUsingLocalData = false;
  bool _isInitialized = false;
  bool _isAuthenticated = false;
  List<String> _favoriteEventIds = [];

  // For view state management
  EventsViewType _currentViewType = EventsViewType.list;

  // Track the most recent search parameters
  String? _lastSearchQuery;

  // Pagination properties
  static const int _pageSize = 10;
  bool _hasMoreEvents = true;
  bool _isLoadingMore = false;

  // Add getters for pagination
  bool get hasMoreEvents => _hasMoreEvents;
  bool get isLoadingMore => _isLoadingMore;

  EventsProvider({
    GoogleEventsService? googleEventsService,
    DatabaseService? databaseService,
  }) :
        _googleEventsService = googleEventsService ?? GoogleEventsService(),
        _databaseService = databaseService ?? DatabaseService();

  // Getters
  List<EventData> get events => _filteredEvents.isEmpty && _activeFilter == null
      ? _events
      : _filteredEvents;

  List<EventData> get allEvents => _events;

  // Past events getter
  List<EventData> get pastEvents {
    final now = DateTime.now();
    return events.where((event) {
      final eventEnd = event.endDate ??
          event.eventDate.add(event.duration ?? const Duration(hours: 2));
      return eventEnd.isBefore(now);
    }).toList();
  }

  // Current events getter
  List<EventData> get currentEvents {
    final now = DateTime.now();
    return events.where((event) {
      final eventStart = event.eventDate;
      final eventEnd = event.endDate ??
          event.eventDate.add(event.duration ?? const Duration(hours: 2));
      return eventStart.isBefore(now) && eventEnd.isAfter(now);
    }).toList();
  }

  // Future events getter
  List<EventData> get futureEvents {
    final now = DateTime.now();
    return events.where((event) => event.eventDate.isAfter(now)).toList();
  }

  List<EventData> get favoriteEvents => _events.where((e) => _favoriteEventIds.contains(e.id)).toList();

  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isUsingLocalData => _isUsingLocalData;
  bool get isAuthenticated => _isAuthenticated;
  bool get initialized => _isInitialized;
  EventFilter? get activeFilter => _activeFilter;
  EventsViewType get currentViewType => _currentViewType;

  Future<void> initialize() async {
    if (_isInitialized) return;

    _isInitialized = true;
    _isLoading = true;
    // Don't call notifyListeners() here

    try {
      await _googleEventsService.initialize();
      _isAuthenticated = await _googleEventsService.isAuthenticated();
      await _loadFavorites();

      if (_isAuthenticated) {
        await fetchEvents();
      } else {
        await _fetchLocalEvents();
      }
    } catch (e) {
      developer.log('Error initializing Google Events service: $e', name: 'EventsProvider');
      await _fetchLocalEvents();
    } finally {
      _isLoading = false;
      // It's now safe to call notifyListeners
      notifyListeners();
    }
  }

  // Create event method
  Future<bool> createEvent(EventData event) async {
    try {
      // If user is authenticated, use their ID
      if (_isAuthenticated) {
        final userId = _googleEventsService.currentUserId;
        if (userId != null) {
          // Create a copy with creator ID
          final eventWithCreator = event.copyWith(createdBy: userId);

          // Add to Firestore via DatabaseService
          final eventId = await _databaseService.createEvent(eventWithCreator);

          // Create a copy with the Firestore ID
          final eventWithId = eventWithCreator.copyWith(id: eventId);

          // Add to local events
          _events.add(eventWithId);
          notifyListeners();

          return true;
        }
      }

      // For unauthenticated users or if getting userId fails
      final eventId = await _databaseService.createEvent(event);

      // Create a copy with the Firestore ID
      final eventWithId = event.copyWith(id: eventId);

      // Add to local events
      _events.add(eventWithId);
      notifyListeners();

      return true;
    } catch (e) {
      developer.log('Error creating event: $e', name: 'EventsProvider');
      _setError('Failed to create event: ${e.toString()}');
      return false;
    }
  }

  // Load favorites from local storage
  Future<void> _loadFavorites() async {
    try {
      // Get favorites using DatabaseService
      _favoriteEventIds = await _databaseService.getUserFavoriteEvents();
    } catch (e) {
      developer.log('Error loading favorites: $e', name: 'EventsProvider');
      // Continue without favorites if there's an error
      _favoriteEventIds = [];
    }
  }

  // Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Set error message
  void _setError(String? message) {
    _error = message;
    notifyListeners();
  }

  // Updated fetchEvents method to support time filtering
  Future<void> fetchEvents({bool loadMore = false}) async {
    if (_isLoading) return;
    if (loadMore && (!_hasMoreEvents || _isLoadingMore)) return;

    if (loadMore) {
      _isLoadingMore = true;
      notifyListeners();
    } else {
      _setLoading(true);
      _setError(null);
      _isUsingLocalData = false;
    }

    try {
      developer.log('Fetching events', name: 'EventsProvider');

      // Create a default filter if none exists
      EventFilter filter = _activeFilter ?? EventFilter(
        includePastEvents: true,
        includeCurrentEvents: true,
        includeFutureEvents: true,
      );

      // Fetch events using DatabaseService with filter
      final fetchedEvents = await _databaseService.getFilteredEvents(filter);

      if (loadMore) {
        // Add to existing events
        _events.addAll(fetchedEvents);
      } else {
        // Replace existing events
        _events = fetchedEvents;
      }

      // Update hasMoreEvents flag - we'll assume there are more if we got a full page
      _hasMoreEvents = fetchedEvents.length >= _pageSize;

      _isUsingLocalData = false;
      developer.log('Fetched ${fetchedEvents.length} events', name: 'EventsProvider');
    } catch (e) {
      developer.log('Error fetching events: $e', name: 'EventsProvider');
      _setError('Failed to load events. Using local data instead.');

      // Try to fetch local events as fallback
      if (!loadMore) {
        await _fetchLocalEvents();
      }
    } finally {
      if (loadMore) {
        _isLoadingMore = false;
      } else {
        _setLoading(false);
      }
      notifyListeners();
    }
  }

  // Fetch events for a specific time period
  Future<void> fetchEventsByTimePeriod(bool includePast, bool includeCurrent, bool includeFuture) async {
    try {
      _setLoading(true);
      _setError(null);

      // Create filter for time period
      final filter = EventFilter(
        includePastEvents: includePast,
        includeCurrentEvents: includeCurrent,
        includeFutureEvents: includeFuture,
      );

      // Save as active filter
      _activeFilter = filter;

      // Fetch events with the filter
      final filteredEvents = await _databaseService.getFilteredEvents(filter);

      _events = filteredEvents;
      _filteredEvents = [];
      _hasMoreEvents = false; // Time-filtered results don't support pagination currently

      developer.log('Fetched ${filteredEvents.length} events for time period', name: 'EventsProvider');
    } catch (e) {
      developer.log('Error fetching events by time period: $e', name: 'EventsProvider');
      _setError('Failed to load events for selected time period');
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  // Get nearby events from Google Places API
  Future<void> fetchNearbyEvents({
    required double latitude,
    required double longitude,
    required double radiusInKm,
    String? keyword,
  }) async {
    try {
      _setLoading(true);
      _setError(null);

      developer.log('Fetching nearby events', name: 'EventsProvider');

      // Fetch nearby events/places using GoogleEventsService
      final nearbyEvents = await _googleEventsService.getNearbyEvents(
        latitude: latitude,
        longitude: longitude,
        radiusInKm: radiusInKm,
        keyword: keyword,
      );

      _events = nearbyEvents;
      _filteredEvents = [];
      _activeFilter = null;
      _hasMoreEvents = false; // Nearby results don't support pagination
      _isUsingLocalData = false;

      developer.log('Fetched ${nearbyEvents.length} nearby events', name: 'EventsProvider');
    } catch (e) {
      developer.log('Error fetching nearby events: $e', name: 'EventsProvider');
      _setError('Failed to load nearby events');

      // Try to fetch regular events as fallback
      await _fetchLocalEvents();
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  // Fetch local events using the DatabaseService
  Future<void> _fetchLocalEvents() async {
    try {
      developer.log('Fetching local events', name: 'EventsProvider');

      // Create a default filter for local events
      final filter = EventFilter(
        includePastEvents: true,
        includeCurrentEvents: true,
        includeFutureEvents: true,
      );

      // Get events from database service
      final localEvents = await _databaseService.getFilteredEvents(filter);

      if (localEvents.isNotEmpty) {
        _events = localEvents;
        _filteredEvents = [];
        _activeFilter = null;
        _hasMoreEvents = localEvents.length >= _pageSize;
        _isUsingLocalData = true;

        developer.log('Loaded ${localEvents.length} local events', name: 'EventsProvider');
      } else {
        // No local events found, try sample events
        _useInMemorySampleEvents();
      }
    } catch (e) {
      developer.log('Error fetching local events: $e', name: 'EventsProvider');

      // Use in-memory sample events as final fallback
      _useInMemorySampleEvents();
    }
  }

  // Use in-memory sample events as final fallback
  void _useInMemorySampleEvents() {
    try {
      developer.log('Using in-memory sample events', name: 'EventsProvider');

      final now = DateTime.now();

      _events = [
        EventData(
          id: 'sample-1',
          title: 'Morning Mountain Trek',
          description: 'Start your day with an energizing mountain trek guided by experienced hikers.',
          eventDate: now.add(const Duration(days: 3, hours: 8)),
          endDate: now.add(const Duration(days: 3, hours: 11)),
          location: 'Blue Mountain Trail',
          imageUrl: 'https://images.unsplash.com/photo-1551632811-561732d1e306',
          category: 'Hiking',
          difficulty: 3,
          duration: const Duration(hours: 3),
          participantLimit: 12,
          attendees: ['hiker1@example.com', 'hiker2@example.com'],
          latitude: 40.0150,
          longitude: -105.2705,
          organizer: 'Mountain Trekkers Club',
          isFree: false,
          price: '\$15',
        ),
        EventData(
          id: 'sample-2',
          title: 'Family Nature Walk',
          description: 'A gentle walk through the forest perfect for families with children of all ages.',
          eventDate: now.add(const Duration(days: 5, hours: 10)),
          endDate: now.add(const Duration(days: 5, hours: 12)),
          location: 'Forest Nature Reserve',
          imageUrl: 'https://images.unsplash.com/photo-1542202229-7d93c33f5d07',
          category: 'Nature Walk',
          difficulty: 1,
          duration: const Duration(hours: 2),
          participantLimit: 20,
          attendees: ['family1@example.com'],
          latitude: 39.7392,
          longitude: -104.9903,
          organizer: 'Nature Guides',
          isFree: true,
        ),
        EventData(
          id: 'sample-3',
          title: 'Advanced Alpine Climb',
          description: 'Challenge yourself with this difficult alpine climbing experience. For experienced climbers only.',
          eventDate: now.add(const Duration(days: 10, hours: 6)),
          endDate: now.add(const Duration(days: 10, hours: 14)),
          location: 'Alpine Ridge',
          imageUrl: 'https://images.unsplash.com/photo-1564769662533-4f00a87b4056',
          category: 'Climbing',
          difficulty: 5,
          duration: const Duration(hours: 8),
          participantLimit: 8,
          attendees: ['climber1@example.com', 'climber2@example.com'],
          latitude: 39.6333,
          longitude: -105.3172,
          organizer: 'Alpine Climbers',
          isFree: false,
          price: '\$45',
        ),
        EventData(
          id: 'sample-4',
          title: 'Weekend Backpacking Trip',
          description: 'A weekend-long backpacking adventure through pristine wilderness. Experience required.',
          eventDate: now.add(const Duration(days: 1)),
          endDate: now.add(const Duration(days: 3)),
          location: 'Rocky Mountain National Park',
          imageUrl: 'https://images.unsplash.com/photo-1504280390367-361c6d9f38f4',
          category: 'Backpacking',
          difficulty: 4,
          duration: const Duration(hours: 48),
          participantLimit: 10,
          attendees: ['hiker3@example.com', 'hiker4@example.com'],
          latitude: 40.3428,
          longitude: -105.6836,
          organizer: 'Wilderness Explorers',
          isFree: false,
          price: '\$120',
        ),
        EventData(
          id: 'sample-5',
          title: 'Sunset Photography Hike',
          description: 'Capture breathtaking sunset photos from a scenic mountain viewpoint.',
          eventDate: now.subtract(const Duration(days: 2, hours: 17)),
          endDate: now.subtract(const Duration(days: 2, hours: 14)),
          location: 'Eagle View Summit',
          imageUrl: 'https://images.unsplash.com/photo-1518020382113-a7e8fc38eac9',
          category: 'Photography',
          difficulty: 2,
          duration: const Duration(hours: 3),
          participantLimit: 15,
          attendees: ['photo1@example.com', 'photo2@example.com'],
          latitude: 39.5501,
          longitude: -105.1097,
          organizer: 'Nature Photographers Guild',
          isFree: true,
        ),
      ];

      // Since these are sample events, no more are available
      _hasMoreEvents = false;

      // Apply any active filter to the new events
      if (_activeFilter != null) {
        applyFilter(_activeFilter!);
      } else {
        _filteredEvents = [];
      }

      _isUsingLocalData = true;
      _setError('Using sample data. Sign in with Google to see real events.');
    } catch (e) {
      developer.log('Error creating in-memory sample events: $e', name: 'EventsProvider');
      _setError('Unable to load events. Please check your connection and try again.');
      _events = [];
      _filteredEvents = [];
      _hasMoreEvents = false;
    }
  }

  // Search for events
  Future<void> searchEvents(String query) async {
    if (_isLoading) return;

    _lastSearchQuery = query;
    _setLoading(true);
    _setError(null);

    try {
      developer.log('Searching for events with query: $query', name: 'EventsProvider');

      // Reset any active filter when searching
      _activeFilter = null;
      _filteredEvents = [];

      // If we're authenticated, search with Google Events API
      if (_isAuthenticated) {
        final searchResults = await _googleEventsService.searchEvents(query);

        _events = searchResults;
        // No pagination for search results
        _hasMoreEvents = false;
        _isUsingLocalData = false;
        developer.log('Found ${searchResults.length} events matching query', name: 'EventsProvider');
      } else {
        // If not authenticated, search local events via DatabaseService
        final filter = EventFilter(searchQuery: query);
        final localResults = await _databaseService.getFilteredEvents(filter);

        _events = localResults;
        _hasMoreEvents = false;
        _isUsingLocalData = true;
        developer.log('Found ${localResults.length} local events matching query', name: 'EventsProvider');
      }
    } catch (e) {
      developer.log('Error searching events: $e', name: 'EventsProvider');
      _setError('Search failed. Using local results instead.');

      // Try local search as fallback via filter
      final filter = EventFilter(searchQuery: query);
      try {
        final localResults = await _databaseService.getFilteredEvents(filter);
        _events = localResults;
      } catch (e2) {
        developer.log('Error with fallback search: $e2', name: 'EventsProvider');
        _useFilteredInMemorySampleEvents(query);
      }
    } finally {
      _setLoading(false);
    }
  }

  // Apply a filter to the events
  Future<void> applyFilter(EventFilter filter) async {
    if (_isLoading) return;

    _setLoading(true);
    _activeFilter = filter;

    try {
      developer.log('Applying filter: ${filter.toString()}', name: 'EventsProvider');

      // Use DatabaseService to apply filter
      final filteredEvents = await _databaseService.getFilteredEvents(filter);

      _events = filteredEvents;
      _filteredEvents = [];
      _hasMoreEvents = false; // Filtered results don't support pagination currently

      developer.log('Filter applied, ${filteredEvents.length} events match the criteria', name: 'EventsProvider');
    } catch (e) {
      developer.log('Error applying filter: $e', name: 'EventsProvider');
      _setError('Error applying filter');

      // Apply filter in memory as fallback
      _applyFilterLocally(filter);
    } finally {
      _setLoading(false);
    }
  }

  // Apply filter locally in memory as a fallback
  void _applyFilterLocally(EventFilter filter) {
    try {
      List<EventData> filtered = List.from(_events);
      final now = DateTime.now();

      // Apply time-based filtering
      filtered = filtered.where((event) {
        final isPast = event.endDate != null
            ? event.endDate!.isBefore(now)
            : event.eventDate.add(event.duration ?? const Duration(hours: 2)).isBefore(now);

        final isCurrent = event.eventDate.isBefore(now) &&
            (event.endDate != null
                ? event.endDate!.isAfter(now)
                : event.eventDate.add(event.duration ?? const Duration(hours: 2)).isAfter(now));

        final isFuture = event.eventDate.isAfter(now);

        return (isPast && filter.includePastEvents) ||
            (isCurrent && filter.includeCurrentEvents) ||
            (isFuture && filter.includeFutureEvents);
      }).toList();

      // Apply date range filters
      if (filter.startDate != null) {
        filtered = filtered.where((event) =>
        event.eventDate.isAfter(filter.startDate!) ||
            event.eventDate.isAtSameMomentAs(filter.startDate!)).toList();
      }

      if (filter.endDate != null) {
        filtered = filtered.where((event) =>
        event.eventDate.isBefore(filter.endDate!) ||
            event.eventDate.isAtSameMomentAs(filter.endDate!)).toList();
      }

      // Apply category filter
      if (filter.categories.isNotEmpty) {
        filtered = filtered.where((event) =>
        event.category != null &&
            filter.categories.contains(event.category!.toLowerCase())).toList();
      }

      // Apply difficulty filter
      if (filter.minDifficulty != null) {
        filtered = filtered.where((event) =>
        event.difficulty != null &&
            event.difficulty! >= filter.minDifficulty!).toList();
      }

      if (filter.maxDifficulty != null) {
        filtered = filtered.where((event) =>
        event.difficulty != null &&
            event.difficulty! <= filter.maxDifficulty!).toList();
      }

      // Apply location text filter
      if (filter.locationQuery != null && filter.locationQuery!.isNotEmpty) {
        final locationLower = filter.locationQuery!.toLowerCase();
        filtered = filtered.where((event) =>
        event.location != null &&
            event.location!.toLowerCase().contains(locationLower)).toList();
      }

      // Apply distance filter
      if (filter.userLatitude != null && filter.userLongitude != null &&
          (filter.maxDistance != null || filter.radiusInKm != null)) {
        final maxDistance = filter.maxDistance ?? filter.radiusInKm;
        if (maxDistance != null) {
          filtered = filtered.where((event) {
            if (event.latitude == null || event.longitude == null) return false;

            // Calculate distance using Haversine formula
            final distance = _calculateDistance(
                filter.userLatitude!,
                filter.userLongitude!,
                event.latitude!,
                event.longitude!
            );

            return distance <= maxDistance;
          }).toList();
        }
      }

      // Apply favorites filter
      if (filter.favoritesOnly || filter.showOnlyFavorites) {
        filtered = filtered.where((event) =>
            _favoriteEventIds.contains(event.id)).toList();
      }

      _filteredEvents = filtered;
    } catch (e) {
      developer.log('Error applying filter locally: $e', name: 'EventsProvider');
      _filteredEvents = _events;
    }
  }

  // Clear all filters
  void clearFilters() {
    _activeFilter = null;
    _filteredEvents = [];
    // Restore pagination state based on current events list
    _hasMoreEvents = _events.length >= _pageSize;
    notifyListeners();
  }

  // Set the current view type
  void setViewType(EventsViewType viewType) {
    _currentViewType = viewType;
    notifyListeners();
  }

  // Calculate distance between two coordinates using Haversine formula
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const int earthRadius = 6371; // Radius of the Earth in kilometers

    // Convert degrees to radians
    final double lat1Rad = lat1 * (3.141592653589793 / 180);
    final double lon1Rad = lon1 * (3.141592653589793 / 180);
    final double lat2Rad = lat2 * (3.141592653589793 / 180);
    final double lon2Rad = lon2 * (3.141592653589793 / 180);

    // Haversine formula
    final double dLat = lat2Rad - lat1Rad;
    final double dLon = lon2Rad - lon1Rad;

    final double a =
        (1 - _cos(dLat)) / 2 +
            _cos(lat1Rad) * _cos(lat2Rad) * (1 - _cos(dLon)) / 2;

    final double c = 2 * _atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c; // Distance in kilometers
  }

  // Math helper functions
  double _cos(double x) => (x * x / 2 - x * x * x * x / 24 + x * x * x * x * x * x / 720).abs() < 0.5 ? 1 - x * x / 2 + x * x * x * x / 24 - x * x * x * x * x * x / 720 : ((x + 3.141592653589793).abs() < 0.5 ? -1 - x * x / 2 + x * x * x * x / 24 - x * x * x * x * x * x / 720 : _cos(x - 6.283185307179586 * (x / 6.283185307179586).floor()));
  double _atan2(double y, double x) => x > 0 ? _atan(y / x) : (x < 0 && y >= 0 ? _atan(y / x) + 3.141592653589793 : (x < 0 && y < 0 ? _atan(y / x) - 3.141592653589793 : (y > 0 ? 1.5707963267948966 : -1.5707963267948966)));
  double _atan(double x) => x.abs() < 1 ? _atanUnder1(x) : (x > 0 ? 1.5707963267948966 - _atanUnder1(1 / x) : -1.5707963267948966 - _atanUnder1(1 / x));
  double _atanUnder1(double x) => x * (1 - 0.33333333333333 * x * x + 0.2 * x * x * x * x - 0.14285714285714 * x * x * x * x * x * x);
  double sqrt(double x) => x <= 0 ? 0 : _sqrt(x, 1);
  double _sqrt(double x, double guess) => (guess * guess - x).abs() < 0.0001 ? guess : _sqrt(x, (guess + x / guess) / 2);

  // Use filtered in-memory sample events as a fallback
  void _useFilteredInMemorySampleEvents(String query) {
    try {
      developer.log('Using filtered in-memory sample events', name: 'EventsProvider');

      final now = DateTime.now();
      final queryLower = query.toLowerCase();

      // Create sample events
      final allSamples = [
        EventData(
          id: 'sample-1',
          title: 'Morning Mountain Trek',
          description: 'Start your day with an energizing mountain trek guided by experienced hikers.',
          eventDate: now.add(const Duration(days: 3, hours: 8)),
          endDate: now.add(const Duration(days: 3, hours: 11)),
          location: 'Blue Mountain Trail',
          imageUrl: 'https://images.unsplash.com/photo-1551632811-561732d1e306',
          category: 'Hiking',
          difficulty: 3,
          duration: const Duration(hours: 3),
          participantLimit: 12,
          latitude: 40.0150,
          longitude: -105.2705,
          organizer: 'Mountain Trekkers Club',
          isFree: false,
          price: '\$15',
        ),
        EventData(
          id: 'sample-2',
          title: 'Family Nature Walk',
          description: 'A gentle walk through the forest perfect for families with children of all ages.',
          eventDate: now.add(const Duration(days: 5, hours: 10)),
          endDate: now.add(const Duration(days: 5, hours: 12)),
          location: 'Forest Nature Reserve',
          imageUrl: 'https://images.unsplash.com/photo-1542202229-7d93c33f5d07',
          category: 'Nature Walk',
          difficulty: 1,
          duration: const Duration(hours: 2),
          participantLimit: 20,
          latitude: 39.7392,
          longitude: -104.9903,
          organizer: 'Nature Guides',
          isFree: true,
        ),
        EventData(
          id: 'sample-3',
          title: 'Advanced Alpine Climb',
          description: 'Challenge yourself with this difficult alpine climbing experience. For experienced climbers only.',
          eventDate: now.add(const Duration(days: 10, hours: 6)),
          endDate: now.add(const Duration(days: 10, hours: 14)),
          location: 'Alpine Ridge',
          imageUrl: 'https://images.unsplash.com/photo-1564769662533-4f00a87b4056',
          category: 'Climbing',
          difficulty: 5,
          duration: const Duration(hours: 8),
          participantLimit: 8,
          latitude: 39.6333,
          longitude: -105.3172,
          organizer: 'Alpine Climbers',
          isFree: false,
          price: '\$45',
        ),
      ];

      // Filter events that match the query
      final filteredEvents = allSamples
          .where((event) =>
      event.title.toLowerCase().contains(queryLower) ||
          (event.description?.toLowerCase().contains(queryLower) ?? false) ||
          (event.location?.toLowerCase().contains(queryLower) ?? false) ||
          (event.category?.toLowerCase().contains(queryLower) ?? false)
      )
          .toList();

      if (filteredEvents.isEmpty) {
        _events = [];
        _filteredEvents = [];
        _activeFilter = null;
        _hasMoreEvents = false;
        _setError('No events found matching "$query". Try another search term.');
      } else {
        _events = filteredEvents;
        _filteredEvents = [];
        _activeFilter = null;
        _hasMoreEvents = false; // No pagination for search results
        _isUsingLocalData = true;
        _setError('Using sample data. Sign in with Google to see real events.');
      }
    } catch (e) {
      developer.log('Error creating filtered in-memory sample events: $e', name: 'EventsProvider');
      _setError('Search failed. Please try again.');
      _events = [];
      _filteredEvents = [];
      _hasMoreEvents = false;
    }
  }

  // Get event details by ID
  Future<EventData?> getEventDetails(String eventId) async {
    try {
      developer.log('Getting event details for ID: $eventId', name: 'EventsProvider');

      // First check in current events list
      for (var event in _events) {
        if (event.id == eventId) {
          return event;
        }
      }

      // If not found in current list, use the DatabaseService
      if (!eventId.startsWith('sample-')) {
        final event = await _databaseService.getEvent(eventId);
        if (event != null) {
          return event;
        }
      }

      // If we get here, event wasn't found
      _setError('Event not found');
      return null;
    } catch (e) {
      developer.log('Error getting event details: $e', name: 'EventsProvider');
      _setError('Failed to load event details');
      return null;
    }
  }

  // Google Sign-in methods
  Future<bool> signIn() async {
    if (_isLoading) return false;

    _setLoading(true);
    _setError(null); // Clear any previous errors

    try {
      developer.log('Signing in to Google', name: 'EventsProvider');

      // Add a delay to ensure UI updates
      await Future.delayed(const Duration(milliseconds: 300));

      final success = await _googleEventsService.signIn();

      if (success) {
        _isAuthenticated = true;

        // Load favorites after sign-in
        await _loadFavorites();

        // After successful sign-in, fetch events from Google
        await fetchEvents();

        developer.log('Successfully signed in to Google', name: 'EventsProvider');
        return true;
      } else {
        _setError('Google sign-in was canceled or failed');
        developer.log('Google sign-in failed or was canceled', name: 'EventsProvider');

        // Automatically fall back to local data
        await _fetchLocalEvents();

        return false;
      }
    } catch (e) {
      developer.log('Error during Google sign-in: $e', name: 'EventsProvider');
      _setError('Failed to sign in with Google. Please try again.');

      // Automatically fall back to local data
      await _fetchLocalEvents();

      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    try {
      developer.log('Signing out from Google', name: 'EventsProvider');

      await _googleEventsService.signOut();
      _isAuthenticated = false;

      // Clear favorites when signing out
      _favoriteEventIds = [];

      // Fetch local events after sign-out
      await _fetchLocalEvents();

      developer.log('Successfully signed out from Google', name: 'EventsProvider');
    } catch (e) {
      developer.log('Error signing out from Google: $e', name: 'EventsProvider');
      _setError('Error signing out: ${e.toString()}');
    }
  }

  // Favorite events methods
  bool isFavorite(String eventId) {
    return _favoriteEventIds.contains(eventId);
  }

  Future<void> toggleFavorite(String eventId) async {
    try {
      if (_favoriteEventIds.contains(eventId)) {
        await _databaseService.removeEventFromFavorites(eventId);
        _favoriteEventIds.remove(eventId);
      } else {
        await _databaseService.addEventToFavorites(eventId);
        _favoriteEventIds.add(eventId);
      }

      // If we have an active filter for favorites only, update the filtered events
      if (_activeFilter != null && (_activeFilter!.favoritesOnly || _activeFilter!.showOnlyFavorites)) {
        await applyFilter(_activeFilter!);
      }

      notifyListeners();
    } catch (e) {
      developer.log('Error toggling favorite: $e', name: 'EventsProvider');
      // Revert the change if there was an error
      if (_favoriteEventIds.contains(eventId)) {
        _favoriteEventIds.remove(eventId);
      } else {
        _favoriteEventIds.add(eventId);
      }
      notifyListeners();
    }
  }

  // Add an event to favorites
  Future<void> addToFavorites(String eventId) async {
    if (!_favoriteEventIds.contains(eventId)) {
      await toggleFavorite(eventId);
    }
  }

  // Remove an event from favorites
  Future<void> removeFromFavorites(String eventId) async {
    if (_favoriteEventIds.contains(eventId)) {
      await toggleFavorite(eventId);
    }
  }

  // Get all categories from events
  List<String> getAllCategories() {
    final categories = <String>{};
    for (final event in _events) {
      if (event.category != null && event.category!.isNotEmpty) {
        categories.add(event.category!.toLowerCase());
      }
    }
    return categories.toList()..sort();
  }

  // Get difficulty levels
  List<int> getAllDifficultyLevels() {
    final difficulties = <int>{};
    for (final event in _events) {
      if (event.difficulty != null) {
        difficulties.add(event.difficulty!);
      }
    }
    return difficulties.toList()..sort();
  }

  // Register for an event
  Future<bool> registerForEvent(String eventId) async {
    try {
      // Find the event
      final eventIndex = _events.indexWhere((e) => e.id == eventId);
      if (eventIndex < 0) return false;

      final event = _events[eventIndex];

      // Check if the event is already full
      if (event.attendees != null &&
          event.participantLimit != null &&
          event.attendees!.length >= event.participantLimit!) {
        _setError('This event is already full.');
        return false;
      }

      // Get current user
      final userId = _googleEventsService.currentUserId;
      if (userId == null) {
        _setError('You must be signed in to register for events.');
        return false;
      }

      // Check if already registered
      if (event.attendees != null && event.attendees!.contains(userId)) {
        _setError('You are already registered for this event.');
        return false;
      }

      // Update Firestore
      if (!eventId.startsWith('sample-')) {
        await _firestore.collection('events').doc(eventId).update({
          'attendees': FieldValue.arrayUnion([userId]),
        });
      }

      // Update local state
      final updatedEvent = _events[eventIndex].copyWith(
        attendees: [...(event.attendees ?? []), userId],
      );

      _events[eventIndex] = updatedEvent;

      // Update filtered events if needed
      if (_filteredEvents.isNotEmpty) {
        final filteredIndex = _filteredEvents.indexWhere((e) => e.id == eventId);
        if (filteredIndex >= 0) {
          _filteredEvents[filteredIndex] = updatedEvent;
        }
      }

      notifyListeners();
      return true;
    } catch (e) {
      developer.log('Error registering for event: $e', name: 'EventsProvider');
      _setError('Failed to register for event. Please try again.');
      return false;
    }
  }

  // Unregister from an event
  Future<bool> unregisterFromEvent(String eventId) async {
    try {
      // Find the event
      final eventIndex = _events.indexWhere((e) => e.id == eventId);
      if (eventIndex < 0) return false;

      final event = _events[eventIndex];

      // Get current user
      final userId = _googleEventsService.currentUserId;
      if (userId == null) {
        _setError('You must be signed in to unregister from events.');
        return false;
      }

      // Check if actually registered
      if (event.attendees == null || !event.attendees!.contains(userId)) {
        _setError('You are not registered for this event.');
        return false;
      }

      // Update Firestore
      if (!eventId.startsWith('sample-')) {
        await _firestore.collection('events').doc(eventId).update({
          'attendees': FieldValue.arrayRemove([userId]),
        });
      }

      // Update local state
      final updatedAttendees = event.attendees!.where((id) => id != userId).toList();
      final updatedEvent = _events[eventIndex].copyWith(
        attendees: updatedAttendees,
      );

      _events[eventIndex] = updatedEvent;

      // Update filtered events if needed
      if (_filteredEvents.isNotEmpty) {
        final filteredIndex = _filteredEvents.indexWhere((e) => e.id == eventId);
        if (filteredIndex >= 0) {
          _filteredEvents[filteredIndex] = updatedEvent;
        }
      }

      notifyListeners();
      return true;
    } catch (e) {
      developer.log('Error unregistering from event: $e', name: 'EventsProvider');
      _setError('Failed to unregister from event. Please try again.');
      return false;
    }
  }

  // Check if user is registered for an event
  bool isRegisteredForEvent(String eventId) {
    final userId = _googleEventsService.currentUserId;
    if (userId == null) return false;

    final eventIndex = _events.indexWhere((e) => e.id == eventId);
    if (eventIndex < 0) return false;

    final event = _events[eventIndex];
    return event.attendees != null && event.attendees!.contains(userId);
  }

  // Refresh events
  void refresh() {
    if (_isAuthenticated) {
      fetchEvents();
    } else {
      _fetchLocalEvents();
    }
  }

  @override
  void dispose() {
    try {
      // Clean up resources
      _googleEventsService.dispose();
      developer.log('Resources disposed successfully', name: 'EventsProvider');
    } catch (e) {
      developer.log('Error disposing resources: $e', name: 'EventsProvider');
    }
    super.dispose();
  }
}