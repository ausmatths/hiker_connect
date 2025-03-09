import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hiker_connect/models/trail_data.dart';
import 'package:hiker_connect/models/event_data.dart';
import 'package:hiker_connect/models/event_filter.dart';
import 'package:hiker_connect/utils/logger.dart'; // Using AppLogger directly

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Box<TrailData>? _trailBox;
  static Box<EventData>? _eventBox;
  static Box<String>? _favoritesBox;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth;

  factory DatabaseService({FirebaseAuth? auth}) {
    return _instance;
  }

  DatabaseService._internal() : _auth = FirebaseAuth.instance;

  // Constructor for testing with dependency injection
  DatabaseService.withAuth(this._auth);

  Future<Box<TrailData>> getTrailBox() async {
    return _trailBox ?? await Hive.openBox<TrailData>('trailBox');
  }

  Future<Box<EventData>> getEventBox() async {
    return _eventBox ?? await Hive.openBox<EventData>('eventBox');
  }

  Future<Box<String>> getFavoritesBox() async {
    return _favoritesBox ?? await Hive.openBox<String>('favoritesBox');
  }

  // In DatabaseService
  Future<void> init() async {
    try {
      // Open Hive boxes
      await Hive.openBox<EventData>('events');
      await Hive.openBox<String>('favoriteEvents');

      // Create sample events if box is empty
      final eventsBox = Hive.box<EventData>('events');
      if (eventsBox.isEmpty) {
        await _createSampleEvents(eventsBox);
      }

      AppLogger.info('Hive boxes initialized successfully');
    } catch (e) {
      AppLogger.error('Error initializing database: $e');
    }
  }

  Future<void> _createSampleEvents(Box<EventData> box) async {
    final sampleEvents = _getSampleEvents();
    for (final event in sampleEvents) {
      await box.put(event.id, event);
    }
    AppLogger.info('Created ${sampleEvents.length} sample events');
  }

// Update getAllEvents method
  Future<List<EventData>> getAllEvents() async {
    try {
      // Make sure the box is opened first
      if (!Hive.isBoxOpen('events')) {
        await Hive.openBox<EventData>('events');
      }

      final box = Hive.box<EventData>('events');
      return box.values.toList();
    } catch (e) {
      AppLogger.error('Error fetching events: $e');
      // Return sample events as fallback
      return _getSampleEvents();
    }
  }

  // TRAIL METHODS

  Future<int> insertTrails(TrailData trail) async {
    try {
      final box = await getTrailBox();
      final resultKey = await box.add(trail);

      // Ensure data is actually written to disk
      await box.flush();

      AppLogger.info('Trail inserted successfully: ${trail.trailName} with key $resultKey');

      // Also sync to Firestore
      await syncTrailToFirestore(trail);

      return resultKey;
    } catch (e) {
      AppLogger.error('Failed to insert trail: ${trail.trailName} - ${e.toString()}');
      rethrow;
    }
  }

  Future<List<TrailData>> getTrails() async {
    try {
      final box = _trailBox ?? await Hive.openBox<TrailData>('trailBox');
      final trails = box.values.toList();

      AppLogger.info('Retrieved ${trails.length} trails from Hive');

      // If no local trails, try to fetch from Firestore
      if (trails.isEmpty) {
        return await getTrailsFromFirestore();
      }

      return trails;
    } catch (e) {
      AppLogger.error('Failed to get trails: ${e.toString()}');
      rethrow;
    }
  }

  Future<void> updateTrail(String trailName, TrailData trail) async {
    try {
      final box = _trailBox ?? await Hive.openBox<TrailData>('trailBox');
      int? resultKey;

      for (var i = 0; i < box.length; i++) {
        final existingTrail = box.getAt(i);
        if (existingTrail != null && existingTrail.trailName == trailName) {
          resultKey = box.keyAt(i);
          break;
        }
      }

      if (resultKey != null) {
        await box.put(resultKey, trail);
        await box.flush(); // Ensure data is written to disk

        AppLogger.info('Trail updated successfully: ${trail.trailName}');

        // Also update in Firestore
        await syncTrailToFirestore(trail);
      } else {
        AppLogger.warning('No trail found to update with name: $trailName');
      }
    } catch (e) {
      AppLogger.error('Failed to update trail: $trailName - ${e.toString()}');
      rethrow;
    }
  }

  Future<TrailData?> getTrailByName(String name) async {
    try {
      final box = _trailBox ?? await Hive.openBox<TrailData>('trailBox');

      for (var i = 0; i < box.length; i++) {
        final trail = box.getAt(i);
        if (trail != null && trail.trailName == name) {
          return trail;
        }
      }

      // If not found locally, try to fetch from Firestore
      try {
        final trailFromFirestore = await getTrailByNameFromFirestore(name);
        if (trailFromFirestore != null) {
          return trailFromFirestore;
        }
      } catch (firestoreError) {
        AppLogger.error('Failed to get trail from Firestore: $firestoreError');
      }

      AppLogger.info('No trail found with name: $name');
      return null;
    } catch (e) {
      AppLogger.error('Failed to get trail by name: $name - ${e.toString()}');
      rethrow;
    }
  }

  Future<void> syncTrailToFirestore(TrailData trail) async {
    try {
      final currentUser = _auth.currentUser;

      if (currentUser == null) {
        AppLogger.warning('No authenticated user to sync trail');
        return;
      }

      // Convert trail to Map
      final trailMap = trail.toMap();

      // Add additional metadata for cloud storage
      trailMap['lastUpdated'] = FieldValue.serverTimestamp();
      trailMap['createdBy'] = currentUser.uid;

      // Save to Firestore
      await _firestore.collection('trails').doc(trail.trailId.toString()).set(trailMap);
      AppLogger.info('Trail synced to Firestore: ${trail.trailName}');
    } catch (e) {
      AppLogger.error('Failed to sync trail to Firestore: ${e.toString()}');
      // Don't rethrow here to prevent local operations from failing
    }
  }

  Future<List<TrailData>> getTrailsFromFirestore() async {
    try {
      final snapshot = await _firestore.collection('trails').get();

      if (snapshot.docs.isEmpty) {
        AppLogger.info('No trails found in Firestore');
        return [];
      }

      final trails = <TrailData>[];
      final processingErrors = <String>[];

      for (var doc in snapshot.docs) {
        try {
          // Get the document data as a map
          final data = Map<String, dynamic>.from(doc.data());

          // Ensure trailId is included (use document ID if not present)
          data['trailId'] = int.tryParse(doc.id) ?? 0;

          // Validate and modify problematic fields
          // Ensure trailDuration is converted to int (minutes)
          data['trailDuration'] = _safeConvertToInt(data['trailDuration'], defaultValue: 0);

          // Ensure trailImages is a list
          data['trailImages'] = _safeConvertToList(data['trailImages']);

          // Convert Timestamp to DateTime if needed
          if (data['trailDate'] is Timestamp) {
            data['trailDate'] = (data['trailDate'] as Timestamp).toDate().toIso8601String();
          }

          // Convert all fields to ensure they match the expected types
          final trail = TrailData.fromMap(data);
          trails.add(trail);
        } catch (e) {
          // Log individual document processing errors
          final errorMsg = 'Error processing trail document ${doc.id}: ${e.toString()}';
          AppLogger.error(errorMsg);
          processingErrors.add(errorMsg);
          continue;
        }
      }

      // Log any processing errors
      if (processingErrors.isNotEmpty) {
        AppLogger.warning('Encountered ${processingErrors.length} trail processing errors');
      }

      // Save fetched trails to local storage for offline access
      final box = _trailBox ?? await Hive.openBox<TrailData>('trailBox');
      for (var trail in trails) {
        await box.add(trail);
      }
      await box.flush();

      AppLogger.info('Retrieved ${trails.length} trails from Firestore');
      return trails;
    } catch (e) {
      // More detailed error logging
      AppLogger.error('Failed to get trails from Firestore: ${e.toString()}');
      print('Full error details: ${e.toString()}');
      print('Error stack trace: ${StackTrace.current}');

      // Return an empty list to prevent app crash
      return [];
    }
  }

  Future<TrailData?> getTrailByNameFromFirestore(String name) async {
    try {
      final snapshot = await _firestore.collection('trails')
          .where('trailName', isEqualTo: name)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return null;
      }

      final data = Map<String, dynamic>.from(snapshot.docs.first.data());

      // Ensure trailId is included
      data['trailId'] = int.tryParse(snapshot.docs.first.id) ?? 0;

      final trail = TrailData.fromMap(data);

      // Save to local storage
      final box = _trailBox ?? await Hive.openBox<TrailData>('trailBox');
      await box.add(trail);
      await box.flush();

      return trail;
    } catch (e) {
      AppLogger.error('Failed to get trail by name from Firestore: ${e.toString()}');
      return null;
    }
  }

  Future<void> deleteTrail(int trailId) async {
    try {
      // 1. Delete from local Hive first
      final box = _trailBox ?? await Hive.openBox<TrailData>('trailBox');

      // Find the key for this trailId
      int? keyToDelete;
      for (var i = 0; i < box.length; i++) {
        final existingTrail = box.getAt(i);
        if (existingTrail != null && existingTrail.trailId == trailId) {
          keyToDelete = box.keyAt(i);
          break;
        }
      }

      if (keyToDelete != null) {
        // Delete from Hive
        await box.delete(keyToDelete);
        await box.flush(); // Ensure data is written to disk
        AppLogger.info('Trail deleted successfully from local storage: ID $trailId');
      } else {
        AppLogger.warning('No trail found to delete with ID: $trailId');
      }

      // 2. Delete from Firestore
      await deleteTrailFromFirestore(trailId);

    } catch (e) {
      AppLogger.error('Failed to delete trail: $trailId - ${e.toString()}');
      rethrow;
    }
  }

  Future<void> deleteTrailFromFirestore(int trailId) async {
    try {
      // Delete from Firestore
      await _firestore.collection('trails').doc(trailId.toString()).delete();
      AppLogger.info('Trail deleted from Firestore: ID $trailId');
    } catch (e) {
      AppLogger.error('Failed to delete trail from Firestore: ${e.toString()}');
      // Don't rethrow here to prevent local operations from failing
    }
  }

  // Add this method to your DatabaseService class
  List<EventData> _getSampleEvents() {
    // Current time for reference
    final now = DateTime.now();

    return [
      EventData(
        id: 'sample1',
        title: 'Morning Mountain Trail Hike',
        description: 'Join us for an early morning hike on the beautiful mountain trails. Perfect for beginners!',
        eventDate: DateTime(now.year, now.month, now.day + 3, 8, 0),
        endDate: DateTime(now.year, now.month, now.day + 3, 11, 0),
        duration: Duration(hours: 3),
        location: 'Mountain View Trail, Colorado',
        category: 'Hiking',
        difficulty: 2,
        latitude: 39.7392,
        longitude: -104.9903,
        attendees: ['hiker1@example.com', 'hiker2@example.com'],
        imageUrl: 'https://images.unsplash.com/photo-1551632811-561732d1e306',
      ),
      EventData(
        id: 'sample2',
        title: 'Advanced Alpine Climb',
        description: 'Challenge yourself with this advanced alpine climbing experience. Experienced hikers only.',
        eventDate: DateTime(now.year, now.month, now.day + 7, 7, 30),
        endDate: DateTime(now.year, now.month, now.day + 7, 16, 0),
        duration: Duration(hours: 8, minutes: 30),
        location: 'Alpine Ridge, Boulder, Colorado',
        category: 'Climbing',
        difficulty: 5,
        latitude: 40.0150,
        longitude: -105.2705,
        attendees: ['climber1@example.com', 'climber2@example.com', 'climber3@example.com'],
        imageUrl: 'https://images.unsplash.com/photo-1564769662533-4f00a87b4056',
      ),
      EventData(
        id: 'sample3',
        title: 'Family Nature Walk',
        description: 'A relaxed nature walk perfect for families with children. Learn about local flora and fauna.',
        eventDate: DateTime(now.year, now.month, now.day + 5, 10, 0),
        endDate: DateTime(now.year, now.month, now.day + 5, 12, 0),
        duration: Duration(hours: 2),
        location: 'City Park Nature Trail',
        category: 'Nature Walk',
        difficulty: 1,
        latitude: 39.7508,
        longitude: -104.9490,
        attendees: ['family1@example.com', 'family2@example.com'],
        imageUrl: 'https://images.unsplash.com/photo-1541807360-7b16088fcb28',
      ),
    ];
  }

  // Get all events from Firestore and cache locally
  Future<List<EventData>> getAllEventsFromBox() async {
    try {
      // First check cache for recent data
      final box = await getEventBox();
      final cachedEvents = box.values.toList();

      // Check if we have cached data and it's recent (within last hour)
      final DateTime now = DateTime.now();
      final cacheKey = 'eventsLastFetched';
      final lastFetchString = await Hive.box('settings').get(cacheKey);
      DateTime? lastFetch;

      if (lastFetchString != null) {
        lastFetch = DateTime.tryParse(lastFetchString);
      }

      // If we have recent cached data, return it
      if (cachedEvents.isNotEmpty &&
          lastFetch != null &&
          now.difference(lastFetch).inHours < 1) {
        AppLogger.info('Using cached events data');
        return cachedEvents;
      }

      // Otherwise fetch from Firestore
      AppLogger.info('Fetching events from Firestore');
      final snapshot = await _firestore.collection('events').get();

      // Clear current cache
      await box.clear();

      // Process Firestore data
      List<EventData> events = [];
      for (var doc in snapshot.docs) {
        try {
          final data = doc.data();

          // Convert Firestore Timestamp to DateTime
          if (data['eventDate'] is Timestamp) {
            data['eventDate'] = (data['eventDate'] as Timestamp).toDate();
          }

          // Create event data with proper ID
          final eventData = EventData.fromMap(data);
          // Set the ID using the correct approach
          final eventWithId = eventData.copyWith(id: doc.id);

          events.add(eventWithId);

          // Cache each event
          await box.add(eventWithId);
        } catch (e) {
          AppLogger.error('Error processing event doc ${doc.id}: $e');
        }
      }

      // Update last fetch time
      await Hive.box('settings').put(cacheKey, now.toIso8601String());

      return events;
    } catch (e) {
      AppLogger.error('Error fetching events: $e');

      // Return cached data if available, even if it's stale
      final box = await getEventBox();
      return box.values.toList();
    }
  }

  // Create a new event
  Future<String> createEvent(EventData event) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Create a copy with creator ID
      final eventWithCreator = event.copyWith(createdBy: user.uid);

      // Add to Firestore
      final docRef = await _firestore.collection('events').add(eventWithCreator.toMap());

      // Create a copy with the Firestore ID
      final eventWithId = eventWithCreator.copyWith(id: docRef.id);

      // Cache locally
      final box = await getEventBox();
      await box.add(eventWithId);

      return docRef.id;
    } catch (e) {
      AppLogger.error('Error creating event: $e');
      rethrow;
    }
  }

  // Get an event by ID
  Future<EventData?> getEvent(String eventId) async {
    try {
      // Check cache first
      final box = await getEventBox();
      EventData? cachedEvent;

      for (var i = 0; i < box.length; i++) {
        final event = box.getAt(i);
        if (event != null && event.id == eventId) {
          cachedEvent = event;
          break;
        }
      }

      if (cachedEvent != null) {
        return cachedEvent;
      }

      // Fetch from Firestore if not in cache
      final doc = await _firestore.collection('events').doc(eventId).get();

      if (!doc.exists) {
        return null;
      }

      final data = doc.data()!;

      // Convert Firestore Timestamp to DateTime
      if (data['eventDate'] is Timestamp) {
        data['eventDate'] = (data['eventDate'] as Timestamp).toDate();
      }

      // Create with ID directly
      final event = EventData.fromMap(data).copyWith(id: doc.id);

      // Add to cache
      await box.add(event);

      return event;
    } catch (e) {
      AppLogger.error('Error getting event $eventId: $e');
      return null;
    }
  }

  // Update an existing event
  Future<void> updateEvent(EventData event) async {
    try {
      if (event.id.isEmpty) {
        throw Exception('Event ID is required for update');
      }

      // Update in Firestore
      await _firestore.collection('events').doc(event.id).update(event.toMap());

      // Update in cache
      final box = await getEventBox();
      int? keyToUpdate;

      for (var i = 0; i < box.length; i++) {
        final cachedEvent = box.getAt(i);
        if (cachedEvent != null && cachedEvent.id == event.id) {
          keyToUpdate = box.keyAt(i);
          break;
        }
      }

      if (keyToUpdate != null) {
        await box.put(keyToUpdate, event);
      } else {
        await box.add(event);
      }

      AppLogger.info('Event updated successfully: ${event.title}');
    } catch (e) {
      AppLogger.error('Error updating event: $e');
      rethrow;
    }
  }

  // Delete an event
  Future<void> deleteEvent(String eventId) async {
    try {
      // Delete from Firestore
      await _firestore.collection('events').doc(eventId).delete();

      // Delete from cache
      final box = await getEventBox();
      int? keyToDelete;

      for (var i = 0; i < box.length; i++) {
        final event = box.getAt(i);
        if (event != null && event.id == eventId) {
          keyToDelete = box.keyAt(i);
          break;
        }
      }

      if (keyToDelete != null) {
        await box.delete(keyToDelete);
      }

      AppLogger.info('Event deleted successfully: $eventId');

      // Also remove from any user's favorites
      await _firestore.collection('users')
          .where('favoriteEvents', arrayContains: eventId)
          .get()
          .then((snapshot) {
        for (var doc in snapshot.docs) {
          _firestore.collection('users').doc(doc.id).update({
            'favoriteEvents': FieldValue.arrayRemove([eventId])
          });
        }
      });
    } catch (e) {
      AppLogger.error('Error deleting event: $e');
      rethrow;
    }
  }

  // FAVORITE EVENTS METHODS

  // Get user's favorite events
  Future<List<String>> getUserFavoriteEvents() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return [];
      }

      // First check local cache
      final box = await getFavoritesBox();
      final cachedFavorites = box.values.toList();

      if (cachedFavorites.isNotEmpty) {
        return cachedFavorites;
      }

      // Fetch from Firestore
      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      if (!userDoc.exists) {
        return [];
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      final favorites = userData['favoriteEvents'];

      if (favorites == null) {
        return [];
      }

      // Convert to List<String>
      final List<String> favoritesList = List<String>.from(favorites);

      // Cache locally
      await box.clear();
      for (var eventId in favoritesList) {
        await box.add(eventId);
      }

      return favoritesList;
    } catch (e) {
      AppLogger.error('Error fetching user favorites: $e');
      return [];
    }
  }

  // Add event to favorites
  Future<void> addEventToFavorites(String eventId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Update Firestore
      await _firestore.collection('users').doc(user.uid).update({
        'favoriteEvents': FieldValue.arrayUnion([eventId]),
      });

      // Update local cache
      final box = await getFavoritesBox();

      // Check if already in favorites
      bool alreadyInFavorites = false;
      for (var i = 0; i < box.length; i++) {
        final favoriteId = box.getAt(i);
        if (favoriteId == eventId) {
          alreadyInFavorites = true;
          break;
        }
      }

      if (!alreadyInFavorites) {
        await box.add(eventId);
      }

      AppLogger.info('Event added to favorites: $eventId');
    } catch (e) {
      AppLogger.error('Error adding event to favorites: $e');
      rethrow;
    }
  }

  // Remove event from favorites
  Future<void> removeEventFromFavorites(String eventId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Update Firestore
      await _firestore.collection('users').doc(user.uid).update({
        'favoriteEvents': FieldValue.arrayRemove([eventId]),
      });

      // Update local cache
      final box = await getFavoritesBox();
      int? keyToDelete;

      for (var i = 0; i < box.length; i++) {
        final favoriteId = box.getAt(i);
        if (favoriteId == eventId) {
          keyToDelete = box.keyAt(i);
          break;
        }
      }

      if (keyToDelete != null) {
        await box.delete(keyToDelete);
      }

      AppLogger.info('Event removed from favorites: $eventId');
    } catch (e) {
      AppLogger.error('Error removing event from favorites: $e');
      rethrow;
    }
  }

  // FILTER METHODS

  // Get events by filter criteria
  Future<List<EventData>> getEventsByFilter(EventFilter filter) async {
    try {
      // Start with all events
      List<EventData> allEvents = await getAllEvents();

      // Apply filters in memory for maximum flexibility
      final filteredEvents = allEvents.where((event) {
        // Filter by favorites
        if (filter.showOnlyFavorites) {
          final favBox = Hive.box<String>('favoritesBox');
          final favoriteIds = favBox.values.toList();
          if (!favoriteIds.contains(event.id)) {
            return false;
          }
        }

        // Filter by search query
        if (filter.searchQuery != null && filter.searchQuery!.isNotEmpty) {
          final query = filter.searchQuery!.toLowerCase();
          final title = event.title.toLowerCase();
          final description = event.description?.toLowerCase() ?? '';
          final location = event.location?.toLowerCase() ?? '';

          if (!title.contains(query) &&
              !description.contains(query) &&
              !location.contains(query)) {
            return false;
          }
        }

        // Filter by date range
        if (filter.startDate != null && event.eventDate.isBefore(filter.startDate!)) {
          return false;
        }

        if (filter.endDate != null && event.eventDate.isAfter(filter.endDate!)) {
          return false;
        }

        // Filter by category
        if (filter.category != null && filter.category!.isNotEmpty) {
          if (event.category != filter.category) {
            return false;
          }
        }

        // Filter by difficulty
        if (filter.difficultyLevel != null) {
          if (event.difficulty != filter.difficultyLevel) {
            return false;
          }
        }

        // Filter by location
        if (filter.locationQuery != null && filter.locationQuery!.isNotEmpty) {
          final query = filter.locationQuery!.toLowerCase();
          final location = event.location?.toLowerCase() ?? '';
          if (!location.contains(query)) {
            return false;
          }
        }

        // Filter by distance (if coordinates are provided in the filter)
        if (filter.maxDistance != null &&
            filter.maxDistance! > 0 &&
            filter.userLatitude != null &&
            filter.userLongitude != null &&
            event.latitude != null &&
            event.longitude != null) {

          // Calculate distance using Haversine formula
          final distance = _calculateDistance(
              filter.userLatitude!,
              filter.userLongitude!,
              event.latitude!,
              event.longitude!
          );

          if (distance > filter.maxDistance!) {
            return false;
          }
        }

        return true;
      }).toList();

      // Sort events by date
      filteredEvents.sort((a, b) => a.eventDate.compareTo(b.eventDate));

      return filteredEvents;
    } catch (e) {
      AppLogger.error('Error applying filters: $e');
      rethrow;
    }
  }

  // UTILITY METHODS

  // Calculate distance using Haversine formula (without geolocator dependency)
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // Radius of the earth in km
    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLon = _degreesToRadians(lon2 - lon1);

    final double a =
        _sin(dLat / 2) * _sin(dLat / 2) +
            _sin(dLon / 2) * _sin(dLon / 2) * _cos(lat1) * _cos(lat2);
    final double c = 2 * _asin(_sqrt(a));
    final double distance = earthRadius * c;

    return distance;
  }

  // Basic math implementations to avoid dependencies
  double _degreesToRadians(double degrees) {
    return degrees * (3.141592653589793 / 180);
  }

  double _sin(double x) {
    // Simple sine approximation using Taylor series
    return x - (x*x*x)/6 + (x*x*x*x*x)/120 - (x*x*x*x*x*x*x)/5040;
  }

  double _cos(double x) {
    // Simple cosine approximation using Taylor series
    return 1 - (x*x)/2 + (x*x*x*x)/24 - (x*x*x*x*x*x)/720;
  }

  double _asin(double x) {
    // Simple arcsine approximation
    return x + (x*x*x)/6 + (3*x*x*x*x*x)/40 + (5*x*x*x*x*x*x*x)/112;
  }

  double _sqrt(double x) {
    // Newton's method for square root
    if (x <= 0) return 0;
    double guess = x / 2;
    for (int i = 0; i < 10; i++) {
      guess = (guess + x / guess) / 2;
    }
    return guess;
  }

  // Helper method to safely convert to int
  int _safeConvertToInt(dynamic value, {int defaultValue = 0}) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  // Helper method to safely convert to list
  List<String> _safeConvertToList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value
          .map((e) => e?.toString().trim() ?? '')
          .where((e) => e.isNotEmpty)
          .toList();
    }
    if (value is String && value.isNotEmpty) {
      return [value.trim()];
    }
    return [];
  }
}