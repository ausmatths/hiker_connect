// lib/providers/event_browsing_provider.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/event_data.dart';
import '../models/event_filter.dart';
import '../services/databaseservice.dart';

enum EventViewType { list, grid, map }

class EventBrowsingProvider with ChangeNotifier {
  final DatabaseService _databaseService;
  List<EventData> _allEvents = [];
  List<EventData> _filteredEvents = [];
  Set<String> _favoriteEventIds = {};
  EventViewType _currentViewType = EventViewType.list;
  EventFilter _currentFilter = EventFilter();
  bool _isLoading = false;
  String? _errorMessage;

  EventBrowsingProvider({required DatabaseService databaseService})
      : _databaseService = databaseService {
    _initializeEvents();
  }

  // Getters
  List<EventData> get events => _filteredEvents;
  EventViewType get viewType => _currentViewType;
  EventFilter get filter => _currentFilter;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool isEventFavorite(String eventId) => _favoriteEventIds.contains(eventId);

  // Initialize events
  Future<void> _initializeEvents() async {
    _setLoading(true);
    try {
      _allEvents = await _databaseService.getAllEvents();
      _loadFavorites();
      _applyFilters();
    } catch (e) {
      _errorMessage = 'Failed to load events: ${e.toString()}';
    } finally {
      _setLoading(false);
    }
  }

  // Load user favorites
  Future<void> _loadFavorites() async {
    try {
      final userFavorites = await _databaseService.getUserFavoriteEvents();
      _favoriteEventIds = Set.from(userFavorites);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading favorites: $e');
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

  // Apply filters
  void applyFilter(EventFilter filter) {
    _currentFilter = filter;
    _applyFilters();
    notifyListeners();
  }

  // Reset all filters
  void resetFilters() {
    _currentFilter = EventFilter();
    _applyFilters();
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
    _filteredEvents = _allEvents.where((event) {
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
            !(event.description?.toLowerCase() ?? '').contains(query)) {
          return false;
        }
      }

      // Filter by date range
      if (_currentFilter.startDate != null) {
        if (event.eventDate.isBefore(_currentFilter.startDate!)) {
          return false;
        }
      }

      if (_currentFilter.endDate != null) {
        if (event.eventDate.isAfter(_currentFilter.endDate!)) {
          return false;
        }
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

      // Add more filters as needed...

      return true;
    }).toList();

    // Sort events by date
    _filteredEvents.sort((a, b) => a.eventDate.compareTo(b.eventDate));
  }

  // Helper to set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    if (loading) {
      _errorMessage = null;
    }
    notifyListeners();
  }
}