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

  /// Create a default EventBriteService with correct tokens from your Eventbrite account
  static EventBriteService _createDefaultEventBriteService() {
    // These are the tokens from your Eventbrite account
    final publicToken = dotenv.env['EVENTBRITE_PUBLIC_TOKEN'] ?? 'V7IFGJ6CYWAWYOZAGN27';
    final privateToken = dotenv.env['EVENTBRITE_PRIVATE_TOKEN'] ?? '5D5NPXG5TIPXU6GLFNCF';

    developer.log(
        'EventBriteProvider using tokens (source: ${dotenv.isInitialized ? '.env file' : 'hardcoded values'})',
        name: 'EventBriteProvider'
    );

    return EventBriteService(
      publicToken: publicToken,
      privateToken: privateToken,
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

      // Debug the token validation process
      final isTokenValid = await _eventbriteService.validateToken();
      developer.log('Token validation result: $isTokenValid', name: 'EventBriteProvider');

      if (!isTokenValid) {
        developer.log('EventBrite token validation failed, will try to use local data',
            name: 'EventBriteProvider');
        throw Exception('No valid EventBrite OAuth token');
      }

      developer.log('Fetching events, page: $_currentPage, refresh: $refresh', name: 'EventBriteProvider');

      final newEvents = await _eventbriteService.searchHikingEvents(
        page: _currentPage,
        location: _lastLocation,
        startDate: _lastStartDate,
      );

      if (refresh) {
        _events = newEvents;
        developer.log('Refreshed events list with ${newEvents.length} items', name: 'EventBriteProvider');
      } else {
        _events.addAll(newEvents);
        developer.log('Added ${newEvents.length} events to list, total: ${_events.length}', name: 'EventBriteProvider');
      }

      _hasMoreEvents = newEvents.isNotEmpty;
      if (_hasMoreEvents) {
        _currentPage++;
      }

      _isUsingLocalData = false;
      _error = null;
    } catch (e) {
      developer.log('Error in EventBriteProvider.fetchEvents: $e', name: 'EventBriteProvider');

      // Try to fetch local events as fallback
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
      developer.log('Fetching local events as fallback', name: 'EventBriteProvider');

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
        _error = "Using local events. Unable to connect to Eventbrite API.";
        developer.log('Loaded ${localEvents.length} local events', name: 'EventBriteProvider');
      } else {
        // No local events found, let's try to create a test event to display
        await _createTestEventIfNoEvents();
      }
    } catch (e) {
      developer.log('Error fetching local events: $e', name: 'EventBriteProvider');
      _error = _extractUserFriendlyError(e);
    }
  }

  // Create a test event if no events are in the database
  Future<void> _createTestEventIfNoEvents() async {
    try {
      // Check if we already have events
      final snapshot = await _firestore.collection('events').limit(1).get();
      if (snapshot.docs.isNotEmpty) return;

      developer.log('No events found, creating a sample event', name: 'EventBriteProvider');

      // Create a sample event
      final sampleEvent = {
        'title': 'Weekend Hiking Trip',
        'description': 'Join us for a beautiful trek through the mountains. Appropriate for all skill levels.',
        'startDate': Timestamp.fromDate(DateTime.now().add(Duration(days: 3))),
        'endDate': Timestamp.fromDate(DateTime.now().add(Duration(days: 3, hours: 4))),
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
      _error = "Using sample event data. Unable to connect to Eventbrite API.";
      developer.log('Created a sample event with ID: ${docRef.id}', name: 'EventBriteProvider');
    } catch (e) {
      developer.log('Error creating sample event: $e', name: 'EventBriteProvider');
      _error = 'No events available. Please check your connection and try again.';
      _events = [];
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
      // Check token validity first
      final isTokenValid = await _eventbriteService.validateToken();
      if (!isTokenValid) {
        developer.log('EventBrite token validation failed during search, will try to use local data',
            name: 'EventBriteProvider');
        throw Exception('No valid EventBrite OAuth token');
      }

      developer.log('Searching events - location: $location, startDate: $startDate', name: 'EventBriteProvider');
      final searchResults = await _eventbriteService.searchHikingEvents(
        location: location,
        startDate: startDate,
        page: _currentPage,
      );

      _events = searchResults;
      developer.log('Search returned ${_events.length} events', name: 'EventBriteProvider');

      _hasMoreEvents = searchResults.isNotEmpty;
      if (_hasMoreEvents) {
        _currentPage++;
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
      developer.log('Searching local events as fallback', name: 'EventBriteProvider');

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
        _error = "Using local events. Unable to connect to Eventbrite API.";
        developer.log('Local search returned ${localEvents.length} events', name: 'EventBriteProvider');
      } else {
        _events = [];
        _isUsingLocalData = true;
        _error = "No events found matching your criteria. Please try different search terms.";
      }
    } catch (e) {
      developer.log('Error searching local events: $e', name: 'EventBriteProvider');
      _error = _extractUserFriendlyError(e);
      _events = [];
    }
  }

  Future<EventData?> getEventDetails(String eventId) async {
    try {
      // Check if we're using local data
      if (_isUsingLocalData) {
        return await _getLocalEventDetails(eventId);
      }

      developer.log('Getting event details for ID: $eventId', name: 'EventBriteProvider');
      return await _eventbriteService.getEventDetails(eventId);
    } catch (e) {
      developer.log('Error in EventBriteProvider.getEventDetails: $e', name: 'EventBriteProvider');

      // Try to get local event details if EventBrite fails
      try {
        return await _getLocalEventDetails(eventId);
      } catch (localError) {
        _error = _extractUserFriendlyError(e);
        // Don't call notifyListeners() here as it might be during a build phase
        return null;
      }
    }
  }

  Future<EventData?> _getLocalEventDetails(String eventId) async {
    try {
      developer.log('Getting local event details for ID: $eventId', name: 'EventBriteProvider');

      final doc = await _firestore.collection('events').doc(eventId).get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        data['id'] = doc.id;
        return EventData.fromFirestore(data);
      }

      return null;
    } catch (e) {
      developer.log('Error getting local event details: $e', name: 'EventBriteProvider');
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