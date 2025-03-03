import 'package:flutter/foundation.dart';
import 'dart:developer' as developer;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/event_data.dart';
import '../services/eventbrite_service.dart';

class EventBriteProvider with ChangeNotifier {
  final EventBriteService _eventbriteService;

  List<EventData> _events = [];
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  bool _hasMoreEvents = true;

  // Track the most recent search parameters
  String? _lastLocation;
  String? _lastStartDate;

  EventBriteProvider({EventBriteService? eventbriteService})
      : _eventbriteService = eventbriteService ?? _createDefaultEventBriteService();

  /// Create a default EventBriteService with hardcoded tokens as fallback
  static EventBriteService _createDefaultEventBriteService() {
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

  List<EventData> get events => _events;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMoreEvents => _hasMoreEvents;

  Future<void> fetchEvents({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _hasMoreEvents = true;
      _error = null;
    }

    if (_isLoading || (!_hasMoreEvents && !refresh)) return;

    _isLoading = true;
    notifyListeners();

    try {
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
    } catch (e) {
      developer.log('Error in EventBriteProvider.fetchEvents: $e', name: 'EventBriteProvider');
      _error = _extractUserFriendlyError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> searchEvents({String? location, String? startDate}) async {
    // Store search parameters for pagination
    _lastLocation = location;
    _lastStartDate = startDate;

    _isLoading = true;
    _error = null;
    _currentPage = 1;
    notifyListeners();

    try {
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
      _error = _extractUserFriendlyError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<EventData?> getEventDetails(String eventId) async {
    try {
      developer.log('Getting event details for ID: $eventId', name: 'EventBriteProvider');
      return await _eventbriteService.getEventDetails(eventId);
    } catch (e) {
      developer.log('Error in EventBriteProvider.getEventDetails: $e', name: 'EventBriteProvider');
      _error = _extractUserFriendlyError(e);
      notifyListeners();
      return null;
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
    }

    return errorMessage;
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