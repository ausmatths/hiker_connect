import 'package:flutter/foundation.dart';
import 'dart:developer' as developer;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event_data.dart';
import '../services/eventbrite_service.dart';

class EventBriteProvider with ChangeNotifier {
  final EventBriteService _eventbriteService;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<EventData> _events = [];
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  bool _hasMoreEvents = true;
  bool _isUsingLocalData = false;
  bool _isInitialized = false;

  // Track the most recent search parameters
  String? _lastLocation;
  String? _lastStartDate;

  EventBriteProvider({EventBriteService? eventbriteService})
      : _eventbriteService = eventbriteService ?? _createDefaultEventBriteService() {
    // Don't auto-fetch here, it can cause the build-time notification error
  }

  /// Create a default EventBriteService with secure token handling
  static EventBriteService _createDefaultEventBriteService() {
    // Get tokens from environment variables without exposing them
    final privateToken = dotenv.env['EVENTBRITE_PRIVATE_TOKEN'];
    final clientSecret = dotenv.env['EVENTBRITE_CLIENT_SECRET'];

    developer.log(
        'EventBriteProvider initialized with tokens from ${dotenv.isInitialized ? '.env file' : 'secure storage'}',
        name: 'EventBriteProvider'
    );

    // Create service with secure token handling
    return EventBriteService(
      privateToken: privateToken,
      clientSecret: clientSecret,
    );
  }

  List<EventData> get events {
    _ensureInitialized();
    return _events;
  }

  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMoreEvents => _hasMoreEvents;
  bool get isUsingLocalData => _isUsingLocalData;

  // Method to ensure the provider is initialized properly
  void _ensureInitialized() {
    if (!_isInitialized) {
      _isInitialized = true;
      // Use Future.microtask to delay the fetch until after the build is complete
      Future.microtask(() => fetchEvents(refresh: true));
    }
  }

  Future<void> fetchEvents({bool refresh = false}) async {
    if (_isLoading || (!_hasMoreEvents && !refresh)) return;

    _isLoading = true;
    if (refresh) {
      _currentPage = 1;
      _hasMoreEvents = true;
      _error = null;
      _isUsingLocalData = false;
    }

    notifyListeners();

    try {
      developer.log('Fetching events from Eventbrite', name: 'EventBriteProvider');

      // Try to get events from EventBrite service (the service will return sample data if API fails)
      final newEvents = await _eventbriteService.searchHikingEvents(
        page: _currentPage,
        location: _lastLocation,
        startDate: _lastStartDate,
      );

      // If we get here, we have events (either real or sample)
      if (refresh) {
        _events = newEvents;
        developer.log('Refreshed events list with ${newEvents.length} items', name: 'EventBriteProvider');
      } else {
        _events.addAll(newEvents);
        developer.log('Added ${newEvents.length} events to list, total: ${_events.length}', name: 'EventBriteProvider');
      }

      // Check if we're getting sample data by looking for sample IDs
      _isUsingLocalData = newEvents.isNotEmpty && newEvents[0].id.startsWith('sample-');
      if (_isUsingLocalData) {
        developer.log('Using sample event data', name: 'EventBriteProvider');
        _hasMoreEvents = false; // No pagination with sample data
        _error = "Using sample event data. Unable to connect to Eventbrite API.";
      } else {
        _hasMoreEvents = newEvents.isNotEmpty;
        if (_hasMoreEvents) {
          _currentPage++;
        }
        _error = null;
      }
    } catch (e) {
      developer.log('Error in EventBriteProvider.fetchEvents: $e', name: 'EventBriteProvider');

      // Try to fetch from Firestore as fallback
      if (_events.isEmpty || refresh) {
        await _fetchLocalEvents();
      } else {
        _error = _extractUserFriendlyError(e);
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _fetchLocalEvents() async {
    try {
      developer.log('Fetching local events from Firestore', name: 'EventBriteProvider');

      // Try to get local events from Firestore
      final eventsCollection = _firestore.collection('events');
      final snapshot = await eventsCollection.limit(20).get();

      if (snapshot.docs.isNotEmpty) {
        final localEvents = snapshot.docs.map((doc) {
          final data = doc.data();
          // Add the document ID to the data
          data['id'] = doc.id;
          // Convert to EventData
          return EventData.fromFirestore(data);
        }).toList();

        _events = localEvents;
        _isUsingLocalData = true;
        _error = "Using local events from database. Unable to connect to Eventbrite API.";
        developer.log('Loaded ${localEvents.length} local events from Firestore', name: 'EventBriteProvider');
      } else {
        // No local events found, let's try to create a test event to display
        await _createTestEventIfNoEvents();
      }
    } catch (e) {
      developer.log('Error fetching local events from Firestore: $e', name: 'EventBriteProvider');

      // If Firestore fails too, use in-memory sample events as final fallback
      _useInMemorySampleEvents();
    }
  }

  // Use in-memory sample events as final fallback when both API and Firestore fail
  void _useInMemorySampleEvents() {
    try {
      developer.log('Using in-memory sample events as final fallback', name: 'EventBriteProvider');

      final now = DateTime.now();

      _events = [
        EventData(
          id: 'memory-1',
          title: 'Weekend Mountain Trek',
          description: 'Join us for a beautiful mountain hike with experienced guides.',
          startDate: now.add(const Duration(days: 5)),
          endDate: now.add(const Duration(days: 5, hours: 4)),
          location: 'Blue Mountain Trail, Boulder, CO',
          participantLimit: 20,
          duration: const Duration(hours: 4),
          imageUrl: 'https://images.unsplash.com/photo-1551632811-561732d1e306',
          organizer: 'Mountain Trekkers Club',
          isFree: false,
          price: 'USD 25.00',
        ),
        EventData(
          id: 'memory-2',
          title: 'Nature Photography Hike',
          description: 'Bring your camera and capture the beauty of spring wildflowers.',
          startDate: now.add(const Duration(days: 12)),
          endDate: now.add(const Duration(days: 12, hours: 3)),
          location: 'Wildflower Ridge Trail, Portland, OR',
          participantLimit: 15,
          duration: const Duration(hours: 3),
          imageUrl: 'https://images.unsplash.com/photo-1542202229-7d93c33f5d07',
          organizer: 'Photography Explorers',
          isFree: true,
        ),
      ];

      _isUsingLocalData = true;
      _hasMoreEvents = false;
      _error = "Using in-memory sample data. Network connection issues detected.";
    } catch (e) {
      developer.log('Error creating in-memory sample events: $e', name: 'EventBriteProvider');
      _error = 'No events available. Please check your connection and try again.';
      _events = [];
    }
  }

  // Create a test event if no events are in the database
  Future<void> _createTestEventIfNoEvents() async {
    try {
      // Check if we already have events
      final snapshot = await _firestore.collection('events').limit(1).get();
      if (snapshot.docs.isNotEmpty) return;

      developer.log('No events found in Firestore, creating a sample event', name: 'EventBriteProvider');

      // Create a sample event
      final now = DateTime.now();
      final sampleEvent = {
        'title': 'Weekend Hiking Trip',
        'description': 'Join us for a beautiful trek through the mountains. Appropriate for all skill levels.',
        'startDate': Timestamp.fromDate(now.add(Duration(days: 3))),
        'endDate': Timestamp.fromDate(now.add(Duration(days: 3, hours: 4))),
        'location': 'Mountain Creek Trail, Park City',
        'imageUrl': 'https://source.unsplash.com/random/?hiking',
        'organizer': 'Adventure Hiking Club',
        'isFree': true,
        'participantLimit': 20,
        'status': 'active'
      };

      // Add to Firestore
      final docRef = await _firestore.collection('events').add(sampleEvent);

      // Get the ID and update the event data
      sampleEvent['id'] = docRef.id;

      // Create EventData object
      final event = EventData.fromFirestore(sampleEvent);

      // Update provider state
      _events = [event];
      _isUsingLocalData = true;
      _error = "Using sample event data in Firestore. Unable to connect to Eventbrite API.";
      developer.log('Created a sample event in Firestore with ID: ${docRef.id}', name: 'EventBriteProvider');
    } catch (e) {
      developer.log('Error creating sample event in Firestore: $e', name: 'EventBriteProvider');

      // If Firestore fails, fall back to in-memory samples
      _useInMemorySampleEvents();
    }
  }

  Future<void> searchEvents({String? location, String? startDate}) async {
    // Store search parameters for pagination
    _lastLocation = location;
    _lastStartDate = startDate;

    _isLoading = true;
    _error = null;
    _currentPage = 1;
    _isUsingLocalData = false;
    notifyListeners();

    try {
      developer.log('Searching events - location: $location, startDate: $startDate', name: 'EventBriteProvider');

      // Try to search events (service will handle API errors with sample data)
      final searchResults = await _eventbriteService.searchHikingEvents(
        location: location,
        startDate: startDate,
        page: _currentPage,
      );

      _events = searchResults;
      developer.log('Search returned ${_events.length} events', name: 'EventBriteProvider');

      // Check if we're getting sample data
      _isUsingLocalData = searchResults.isNotEmpty && searchResults[0].id.startsWith('sample-');
      if (_isUsingLocalData) {
        developer.log('Search is using sample event data', name: 'EventBriteProvider');
        _hasMoreEvents = false;
        _error = "Using sample event data. Unable to connect to Eventbrite API.";
      } else {
        _hasMoreEvents = searchResults.isNotEmpty;
        if (_hasMoreEvents) {
          _currentPage++;
        }
        _error = null;
      }
    } catch (e) {
      developer.log('Error in EventBriteProvider.searchEvents: $e', name: 'EventBriteProvider');

      // Try local search if EventBrite fails
      await _searchLocalEvents(location: location, startDate: startDate);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _searchLocalEvents({String? location, String? startDate}) async {
    try {
      developer.log('Searching local events in Firestore as fallback', name: 'EventBriteProvider');

      // Create a query to search local events
      Query query = _firestore.collection('events');

      // Add filters if provided
      if (location != null && location.isNotEmpty) {
        query = query.where('location', isGreaterThanOrEqualTo: location)
            .where('location', isLessThanOrEqualTo: location + '\uf8ff');
      }

      if (startDate != null && startDate.isNotEmpty) {
        DateTime date;
        try {
          date = DateTime.parse(startDate);
          query = query.where('startDate', isGreaterThanOrEqualTo: Timestamp.fromDate(date));
        } catch (e) {
          developer.log('Invalid date format for search: $startDate', name: 'EventBriteProvider');
        }
      }

      final snapshot = await query.limit(20).get();

      if (snapshot.docs.isNotEmpty) {
        final localEvents = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          return EventData.fromFirestore(data);
        }).toList();

        _events = localEvents;
        _isUsingLocalData = true;
        _error = "Using local events from database. Unable to connect to Eventbrite API.";
        developer.log('Local search returned ${localEvents.length} events', name: 'EventBriteProvider');
      } else {
        // If Firestore search returns no results, use in-memory filtered samples
        _useFilteredInMemorySampleEvents(location, startDate);
      }
    } catch (e) {
      developer.log('Error searching local events in Firestore: $e', name: 'EventBriteProvider');

      // If Firestore search fails, use in-memory filtered samples
      _useFilteredInMemorySampleEvents(location, startDate);
    }
  }

  void _useFilteredInMemorySampleEvents(String? location, String? startDate) {
    try {
      developer.log('Using filtered in-memory sample events', name: 'EventBriteProvider');

      final now = DateTime.now();
      final int? searchMillis = startDate != null && startDate.isNotEmpty
          ? _tryParseDateToMillis(startDate)
          : null;

      // Create base sample events
      final allSamples = [
        EventData(
          id: 'memory-1',
          title: 'Weekend Mountain Trek',
          description: 'Join us for a beautiful mountain hike with experienced guides.',
          startDate: now.add(const Duration(days: 5)),
          endDate: now.add(const Duration(days: 5, hours: 4)),
          location: 'Blue Mountain Trail, Boulder, CO',
          participantLimit: 20,
          duration: const Duration(hours: 4),
          imageUrl: 'https://images.unsplash.com/photo-1551632811-561732d1e306',
          organizer: 'Mountain Trekkers Club',
          isFree: false,
          price: 'USD 25.00',
        ),
        EventData(
          id: 'memory-2',
          title: 'Nature Photography Hike',
          description: 'Bring your camera and capture the beauty of spring wildflowers.',
          startDate: now.add(const Duration(days: 12)),
          endDate: now.add(const Duration(days: 12, hours: 3)),
          location: 'Wildflower Ridge Trail, Portland, OR',
          participantLimit: 15,
          duration: const Duration(hours: 3),
          imageUrl: 'https://images.unsplash.com/photo-1542202229-7d93c33f5d07',
          organizer: 'Photography Explorers',
          isFree: true,
        ),
        EventData(
          id: 'memory-3',
          title: 'Sunset Hiking Adventure',
          description: 'Experience the magic of sunset from a scenic mountain viewpoint.',
          startDate: now.add(const Duration(days: 7)),
          endDate: now.add(const Duration(days: 7, hours: 2, minutes: 30)),
          location: 'Sunset Peak, Malibu, CA',
          participantLimit: 12,
          duration: const Duration(hours: 2, minutes: 30),
          imageUrl: 'https://images.unsplash.com/photo-1508739773434-c26b3d09e071',
          organizer: 'Outdoor Adventures Group',
          isFree: false,
          price: 'USD 15.00',
        ),
      ];

      // Initial list
      List<EventData> filteredEvents = [];

      // Apply both filters at once to avoid intermediate nullable handling
      for (var event in allSamples) {
        bool includeEvent = true;

        // Location filter
        if (location != null && location.isNotEmpty) {
          final eventLocation = event.location;
          if (eventLocation == null ||
              !eventLocation.toLowerCase().contains(location.toLowerCase())) {
            includeEvent = false;
          }
        }

        // Date filter
        if (includeEvent && searchMillis != null) {
          // Get event date as milliseconds to avoid isAfter
          int? eventMillis = _getEventDateMillis(event);
          if (eventMillis == null || eventMillis <= searchMillis) {
            includeEvent = false;
          }
        }

        if (includeEvent) {
          filteredEvents.add(event);
        }
      }

      if (filteredEvents.isEmpty) {
        _events = [];
        _error = "No events found matching your criteria. Please try different search terms.";
      } else {
        _events = filteredEvents;
        _isUsingLocalData = true;
        _error = "Using sample data. Network connection issues detected.";
      }

      _hasMoreEvents = false;
    } catch (e) {
      developer.log('Error creating filtered in-memory sample events: $e', name: 'EventBriteProvider');
      _error = 'No events available. Please check your connection and try again.';
      _events = [];
    }
  }

// Helper method to safely get event date as milliseconds
  int? _getEventDateMillis(EventData event) {
    try {
      // First check if startDate is null
      final date = event.startDate;
      if (date == null) {
        return null;
      }

      // If we get here, date is non-null, so we can safely access millisecondsSinceEpoch
      return date.millisecondsSinceEpoch;
    } catch (e) {
      developer.log('Error getting event milliseconds: $e', name: 'EventBriteProvider');
      return null;
    }
  }

// Helper method to parse date string to milliseconds
  int? _tryParseDateToMillis(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return date.millisecondsSinceEpoch;
    } catch (e) {
      developer.log('Invalid date format: $dateStr', name: 'EventBriteProvider');
      return null;
    }
  }

  Future<EventData?> getEventDetails(String eventId) async {
    try {
      developer.log('Getting event details for ID: $eventId', name: 'EventBriteProvider');

      // Check if this is a sample event ID
      if (eventId.startsWith('sample-') || eventId.startsWith('memory-')) {
        developer.log('Getting sample event details for ID: $eventId', name: 'EventBriteProvider');

        // For sample events, return the matching one from current list if available
        for (var event in _events) {
          if (event.id == eventId) {
            return event;
          }
        }
      }

      // If it's a Firestore ID and we're using local data, try to get from Firestore
      if (_isUsingLocalData && !eventId.startsWith('sample-') && !eventId.startsWith('memory-')) {
        return await _getLocalEventDetails(eventId);
      }

      // Otherwise, try to get from EventBrite
      return await _eventbriteService.getEventDetails(eventId);
    } catch (e) {
      developer.log('Error in EventBriteProvider.getEventDetails: $e', name: 'EventBriteProvider');

      // Try to get local event details if EventBrite fails
      try {
        return await _getLocalEventDetails(eventId);
      } catch (localError) {
        developer.log('Error getting local event details: $localError', name: 'EventBriteProvider');
        _error = _extractUserFriendlyError(e);
        return null;
      }
    }
  }

  Future<EventData?> _getLocalEventDetails(String eventId) async {
    try {
      developer.log('Getting local event details from Firestore for ID: $eventId', name: 'EventBriteProvider');

      final doc = await _firestore.collection('events').doc(eventId).get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        data['id'] = doc.id;
        return EventData.fromFirestore(data);
      }

      throw Exception('Event not found in Firestore');
    } catch (e) {
      developer.log('Error getting local event details from Firestore: $e', name: 'EventBriteProvider');
      throw e; // Let the caller handle this
    }
  }

  // Helper method to extract a user-friendly error message
  String _extractUserFriendlyError(Object error) {
    String errorMessage = 'Failed to load events. Please try again later.';

    if (error.toString().contains('No valid EventBrite OAuth token')) {
      errorMessage = 'Authentication failed. Please check your EventBrite credentials.';
    } else if (error.toString().contains('HTTP Error 429')) {
      errorMessage = 'Too many requests. Please wait and try again.';
    } else if (error.toString().contains('HTTP Error 401')) {
      errorMessage = 'Authentication failed. Please check your API access.';
    } else if (error.toString().contains('SocketException') ||
        error.toString().contains('Connection refused') ||
        error.toString().contains('Network is unreachable')) {
      errorMessage = 'Network connection error. Please check your internet connection.';
    }

    return errorMessage;
  }

  void refresh() {
    // Safe way to trigger a refresh from UI
    Future.microtask(() => fetchEvents(refresh: true));
  }

  @override
  void dispose() {
    try {
      _eventbriteService.dispose();
      developer.log('EventBriteService disposed successfully', name: 'EventBriteProvider');
    } catch (e) {
      developer.log('Error disposing EventBriteService: $e', name: 'EventBriteProvider');
    }
    super.dispose();
  }
}