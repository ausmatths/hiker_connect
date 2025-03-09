import 'package:flutter/foundation.dart';
import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event_data.dart';
import '../models/event_filter.dart';
import '../services/google_events_service.dart';
import '../models/events_view_type.dart';

class EventsProvider with ChangeNotifier {
  final GoogleEventsService _googleEventsService;
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

  EventsProvider({GoogleEventsService? googleEventsService})
      : _googleEventsService = googleEventsService ?? GoogleEventsService();

  // Getters
  List<EventData> get events => _filteredEvents.isEmpty && _activeFilter == null
      ? _events
      : _filteredEvents;

  List<EventData> get allEvents => _events;
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

  // Add to EventsProvider
  Future<bool> createEvent(EventData event) async {
    try {
      // If user is authenticated, use their ID
      if (_isAuthenticated) {
        final userId = _googleEventsService.currentUserId;
        if (userId != null) {
          // Create a copy with creator ID
          final eventWithCreator = event.copyWith(createdBy: userId);

          // Add to Firestore
          final docRef = await _firestore.collection('events').add(eventWithCreator.toMap());

          // Create a copy with the Firestore ID
          final eventWithId = eventWithCreator.copyWith(id: docRef.id);

          // Add to local events
          _events.add(eventWithId);
          notifyListeners();

          return true;
        }
      }

      // For unauthenticated users or if getting userId fails
      // Add to Firestore without user ID
      final docRef = await _firestore.collection('events').add(event.toMap());

      // Create a copy with the Firestore ID
      final eventWithId = event.copyWith(id: docRef.id);

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
      // Try to load favorites from Firestore if user is authenticated
      if (_isAuthenticated) {
        final userId = _googleEventsService.currentUserId;
        if (userId != null) {
          final doc = await _firestore.collection('users').doc(userId).get();
          if (doc.exists && doc.data() != null) {
            final data = doc.data()!;
            if (data.containsKey('favoriteEvents') && data['favoriteEvents'] is List) {
              _favoriteEventIds = List<String>.from(data['favoriteEvents']);
            }
          }
        }
      }
    } catch (e) {
      developer.log('Error loading favorites: $e', name: 'EventsProvider');
      // Continue without favorites if there's an error
    }
  }

  // Save favorites to local storage
  Future<void> _saveFavorites() async {
    try {
      // Save favorites to Firestore if user is authenticated
      if (_isAuthenticated) {
        final userId = _googleEventsService.currentUserId;
        if (userId != null) {
          await _firestore.collection('users').doc(userId).set({
            'favoriteEvents': _favoriteEventIds,
          }, SetOptions(merge: true));
        }
      }
    } catch (e) {
      developer.log('Error saving favorites: $e', name: 'EventsProvider');
      // Continue without saving if there's an error
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

  // Updated fetchEvents method to support pagination
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
      developer.log('Fetching events from Google Events API', name: 'EventsProvider');

      // Check authentication status
      if (!_isAuthenticated) {
        developer.log('Not authenticated, attempting to sign in', name: 'EventsProvider');
        final authSuccess = await signIn();
        if (!authSuccess) {
          developer.log('Authentication failed', name: 'EventsProvider');
          // If authentication fails, try local events
          await _fetchLocalEvents();
          return;
        }
      }

      // Calculate what page we're on
      final currentPage = loadMore ? (_events.length / _pageSize).floor() : 0;

      // Add a short delay to ensure authentication is fully processed
      await Future.delayed(const Duration(milliseconds: 300));

      // Fetch events using the pagination method
      final newEvents = await _fetchEventsPage(currentPage);

      // Update hasMoreEvents flag
      _hasMoreEvents = newEvents.length >= _pageSize;

      if (loadMore) {
        // Add to existing events
        _events.addAll(newEvents);
      } else {
        // Replace existing events
        _events = newEvents;
      }

      // Apply any active filter to the new events
      if (_activeFilter != null) {
        await applyFilter(_activeFilter!);
      } else {
        _filteredEvents = [];
      }

      _isUsingLocalData = false;
      developer.log('Fetched ${newEvents.length} events from Google Events API', name: 'EventsProvider');
    } catch (e) {
      developer.log('Error fetching events from Google Events API: $e', name: 'EventsProvider');
      _setError('Failed to load events from Google. Using local data instead.');

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

  // Add this new method to fetch a specific page of events
  Future<List<EventData>> _fetchEventsPage(int page) async {
    // If authenticated, fetch from Google
    if (_isAuthenticated) {
      try {
        // Check if GoogleEventsService supports pagination parameters
        if (page == 0) {
          // For first page, just use regular fetching
          return await _googleEventsService.fetchEvents(limit: _pageSize);
        } else {
          // For subsequent pages, we'll need to handle pagination differently
          // Since offset isn't directly supported, we'll use the existing events as a reference
          // and filter out any duplicates
          final newEvents = await _googleEventsService.fetchEvents(limit: _pageSize * 2);
          final existingIds = _events.map((e) => e.id).toSet();

          // Filter out events we already have
          final filteredEvents = newEvents
              .where((event) => !existingIds.contains(event.id))
              .take(_pageSize)
              .toList();

          return filteredEvents;
        }
      } catch (e) {
        developer.log('Error fetching from Google: $e', name: 'EventsProvider');
        throw e;
      }
    } else {
      // Otherwise fetch from Firestore
      try {
        final query = _firestore.collection('events')
            .orderBy('eventDate')
            .limit(_pageSize);

        // Add startAfter for pagination if not the first page
        final QuerySnapshot snapshot;
        if (page > 0 && _events.isNotEmpty) {
          // Get the last document from the previous page
          final lastEventDate = _events.last.eventDate;
          snapshot = await query.startAfter([Timestamp.fromDate(lastEventDate)]).get();
        } else {
          snapshot = await query.get();
        }

        return snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          return EventData.fromMap(data);
        }).toList();
      } catch (e) {
        developer.log('Error fetching from Firestore: $e', name: 'EventsProvider');
        throw e;
      }
    }
  }

  // Fetch events from local Firestore database
  Future<void> _fetchLocalEvents() async {
    try {
      developer.log('Fetching local events from Firestore', name: 'EventsProvider');

      // Check if we already have events
      final snapshot = await _firestore.collection('events').limit(_pageSize).get();

      if (snapshot.docs.isNotEmpty) {
        // We have local events, use them
        final localEvents = snapshot.docs.map((doc) {
          final data = doc.data();
          // Add the document ID to the data
          data['id'] = doc.id;
          // Convert to EventData
          return EventData.fromMap(data);
        }).toList();

        _events = localEvents;
        // Set pagination state
        _hasMoreEvents = localEvents.length >= _pageSize;

        // Apply any active filter to the new events
        if (_activeFilter != null) {
          await applyFilter(_activeFilter!);
        } else {
          _filteredEvents = [];
        }

        _isUsingLocalData = true;
        developer.log('Loaded ${localEvents.length} local events from Firestore', name: 'EventsProvider');
      } else {
        // No local events found, let's try to create a test event
        await _createTestEventIfNoEvents();
      }
    } catch (e) {
      developer.log('Error fetching local events: $e', name: 'EventsProvider');

      // Use in-memory sample events as final fallback
      _useInMemorySampleEvents();
    }
  }

  // Create a test event in Firestore if none exist
  Future<void> _createTestEventIfNoEvents() async {
    try {
      developer.log('Creating test event in Firestore', name: 'EventsProvider');

      // Create a sample event
      final now = DateTime.now();
      final sampleEvent = {
        'title': 'Mountain Trail Hike',
        'description': 'Join us for a beautiful morning hike on the scenic mountain trails. Perfect for all experience levels!',
        'eventDate': Timestamp.fromDate(now.add(const Duration(days: 3))),
        'endDate': Timestamp.fromDate(now.add(const Duration(days: 3, hours: 3))),
        'location': 'Mountain Trail Park',
        'imageUrl': 'https://images.unsplash.com/photo-1551632811-561732d1e306',
        'organizer': 'Hiking Adventures Club',
        'category': 'Hiking',
        'difficulty': 2,
        'participantLimit': 15,
        'duration': 180, // in minutes
        'latitude': 40.0150,
        'longitude': -105.2705,
        'attendees': [],
        'createdBy': 'system',
        'isFree': true,
      };

      // Add to Firestore
      final docRef = await _firestore.collection('events').add(sampleEvent);

      // Get the ID and update the event data
      sampleEvent['id'] = docRef.id;

      // Create EventData object
      final event = EventData.fromMap(sampleEvent);

      // Update provider state
      _events = [event];
      _filteredEvents = [];
      _hasMoreEvents = false; // Only one sample event
      _isUsingLocalData = true;
      _setError('Using local events. Sign in with Google to see more events.');
      developer.log('Created test event in Firestore with ID: ${docRef.id}', name: 'EventsProvider');
    } catch (e) {
      developer.log('Error creating test event: $e', name: 'EventsProvider');

      // Use in-memory sample events if Firestore fails
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
        // If not authenticated, search local events
        await _searchLocalEvents(query);
      }
    } catch (e) {
      developer.log('Error searching events: $e', name: 'EventsProvider');
      _setError('Search failed. Using local results instead.');

      // Try local search as fallback
      await _searchLocalEvents(query);
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

      List<EventData> filtered = List.from(_events);

      // Filter by date range
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

      // Filter by category
      if (filter.categories.isNotEmpty) {
        filtered = filtered.where((event) =>
        event.category != null &&
            filter.categories.contains(event.category!.toLowerCase())).toList();
      }

      // Filter by difficulty
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

      // Filter by location text
      if (filter.location != null && filter.location!.isNotEmpty) {
        final locationLower = filter.location!.toLowerCase();
        filtered = filtered.where((event) =>
        event.location != null &&
            event.location!.toLowerCase().contains(locationLower)).toList();
      }

      // Filter by distance (need user location)
      if (filter.maxDistance != null && filter.userLatitude != null && filter.userLongitude != null) {
        filtered = filtered.where((event) {
          if (event.latitude == null || event.longitude == null) return false;

          // Calculate distance using Haversine formula
          final distance = _calculateDistance(
              filter.userLatitude!,
              filter.userLongitude!,
              event.latitude!,
              event.longitude!
          );

          return distance <= filter.maxDistance!;
        }).toList();
      }

      // Filter by favorites
      if (filter.favoritesOnly) {
        filtered = filtered.where((event) =>
            _favoriteEventIds.contains(event.id)).toList();
      }

      _filteredEvents = filtered;
      // No pagination for filtered results
      _hasMoreEvents = false;
      developer.log('Filter applied, ${filtered.length} events match the criteria', name: 'EventsProvider');
    } catch (e) {
      developer.log('Error applying filter: $e', name: 'EventsProvider');
      _setError('Error applying filter');
      _filteredEvents = _events;
    } finally {
      _setLoading(false);
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

  // Add the setViewType method here
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

  // Search local events in Firestore
  Future<void> _searchLocalEvents(String query) async {
    try {
      developer.log('Searching local events in Firestore', name: 'EventsProvider');

      if (query.isEmpty) {
        // If empty query, just load all local events
        await _fetchLocalEvents();
        return;
      }

      // Create a query for case-insensitive search
      // Note: Firestore doesn't support real text search, so this is a simple approach
      final queryLower = query.toLowerCase();

      // Get all events and filter in memory (not efficient for large datasets)
      final snapshot = await _firestore.collection('events').get();

      if (snapshot.docs.isNotEmpty) {
        // Filter events that match the query in title, description, or location
        final filteredEvents = snapshot.docs
            .map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return EventData.fromMap(data);
        })
            .where((event) =>
        event.title.toLowerCase().contains(queryLower) ||
            (event.description?.toLowerCase().contains(queryLower) ?? false) ||
            (event.location?.toLowerCase().contains(queryLower) ?? false) ||
            (event.category?.toLowerCase().contains(queryLower) ?? false)
        )
            .toList();

        if (filteredEvents.isNotEmpty) {
          _events = filteredEvents;
          _filteredEvents = [];
          _activeFilter = null;
          _hasMoreEvents = false; // No pagination for search results
          _isUsingLocalData = true;
          developer.log('Found ${filteredEvents.length} local events matching query', name: 'EventsProvider');
        } else {
          // If no matches in Firestore, use filtered in-memory samples
          _useFilteredInMemorySampleEvents(query);
        }
      } else {
        // If no events in Firestore, use filtered in-memory samples
        _useFilteredInMemorySampleEvents(query);
      }
    } catch (e) {
      developer.log('Error searching local events: $e', name: 'EventsProvider');

      // Use filtered in-memory samples as fallback
      _useFilteredInMemorySampleEvents(query);
    }
  }

  // Use filtered in-memory sample events
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

      // If not in current list and not a sample event, try to get from Firestore
      if (!eventId.startsWith('sample-')) {
        final doc = await _firestore.collection('events').doc(eventId).get();

        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          data['id'] = doc.id;
          return EventData.fromMap(data);
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
        _favoriteEventIds.remove(eventId);
      } else {
        _favoriteEventIds.add(eventId);
      }

      // If we have an active filter for favorites only, update the filtered events
      if (_activeFilter != null && _activeFilter!.favoritesOnly) {
        await applyFilter(_activeFilter!);
      }

      // Save favorites to storage
      notifyListeners();
      await _saveFavorites();
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