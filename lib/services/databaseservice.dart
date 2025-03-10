import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:image/image.dart' as img;
import 'package:uuid/uuid.dart';
import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:hiker_connect/models/trail_data.dart';
import 'package:hiker_connect/models/event_data.dart';
import 'package:hiker_connect/models/event_filter.dart';
import 'package:hiker_connect/models/photo_data.dart';
import 'package:hiker_connect/utils/logger.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Box<TrailData>? _trailBox;
  static Box<EventData>? _eventBox;
  static Box<String>? _favoritesBox;
  static Box<PhotoData>? _photoBox;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
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

  Future<Box<PhotoData>> getPhotoBox() async {
    try {
      if (!Hive.isBoxOpen('photoBox')) {
        _photoBox = await Hive.openBox<PhotoData>('photoBox');
        return _photoBox!;
      }
      return _photoBox ?? await Hive.openBox<PhotoData>('photoBox');
    } catch (e) {
      // If there's an error opening the box, try to delete and recreate it
      AppLogger.error('Error opening photoBox: $e');
      try {
        if (Hive.isBoxOpen('photoBox')) {
          await Hive.box<PhotoData>('photoBox').close();
        }
        await Hive.deleteBoxFromDisk('photoBox');
        _photoBox = await Hive.openBox<PhotoData>('photoBox');
        return _photoBox!;
      } catch (e2) {
        AppLogger.error('Failed to recreate photoBox: $e2');
        throw e2;
      }
    }
  }


  Future<void> init() async {
    try {
      // Open Hive boxes
      await Hive.openBox<EventData>('events');
      await Hive.openBox<String>('favoriteEvents');
      await getPhotoBox();
      await dotenv.load();

      // Create sample events if box is empty
      final eventsBox = Hive.box<EventData>('events');
      if (eventsBox.isEmpty) {
        await _createSampleEvents(eventsBox);
      }

      // Ensure Firestore indexes exist for photos
      await ensurePhotoIndexExists();

      // Attempt to recover any unsynced photos
      await recoverUnsyncedPhotos();

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

      // 3. Clean up associated photos
      await deletePhotosForTrail(trailId.toString());

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

      // Clean up associated photos
      await deletePhotosForEvent(eventId);
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

  // PHOTO METHODS

  // Enhanced photo upload method with local storage and thumbnails
  Future<PhotoData> uploadPhoto(File file, {
    String? caption,
    String? trailId,
    String? eventId,
    bool generateThumbnail = true
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Generate a unique ID for the photo
      final photoId = const Uuid().v4();
      final timestamp = DateTime.now();

      // Step 1: Save locally first (reliable storage before network operations)
      final directory = await getApplicationDocumentsDirectory();
      final photosDir = path.join(directory.path, 'photos');

      // Ensure the photos directory exists
      final photosDirectory = Directory(photosDir);
      if (!await photosDirectory.exists()) {
        await photosDirectory.create(recursive: true);
      }

      // Create a local file path for the full-size image
      final filename = 'photo_$photoId${path.extension(file.path)}';
      final localPath = path.join(photosDir, filename);

      // Copy the file to local storage
      await file.copy(localPath);

      String? thumbnailLocalPath;
      Uint8List? thumbnailData;

      // Step 2: Generate thumbnail if requested
      if (generateThumbnail) {
        try {
          // Create thumbnails directory if it doesn't exist
          final thumbsDir = path.join(photosDir, 'thumbnails');
          final thumbsDirectory = Directory(thumbsDir);
          if (!await thumbsDirectory.exists()) {
            await thumbsDirectory.create(recursive: true);
          }

          // Create thumbnail
          final bytes = await file.readAsBytes();
          final image = img.decodeImage(bytes);

          if (image != null) {
            // Resize to thumbnail size (preserving aspect ratio)
            final thumbnail = img.copyResize(
              image,
              width: 300,
              interpolation: img.Interpolation.average,
            );

            thumbnailData = Uint8List.fromList(img.encodeJpg(thumbnail, quality: 80));

            // Save thumbnail locally
            final thumbnailFilename = 'thumb_$photoId${path.extension(file.path)}';
            thumbnailLocalPath = path.join(thumbsDir, thumbnailFilename);
            await File(thumbnailLocalPath).writeAsBytes(thumbnailData);
          }
        } catch (e) {
          AppLogger.warning('Error generating thumbnail (continuing with upload): $e');
          // Continue without thumbnail if generation fails
        }
      }

      // Step 3: Upload to Firebase Storage with retry mechanism
      String url = '';
      String? thumbnailUrl;

      try {
        // Create the storage path based on content type
        String storagePath;
        if (trailId != null) {
          storagePath = 'trails/$trailId/photos/$filename';
        } else if (eventId != null) {
          storagePath = 'events/$eventId/photos/$filename';
        } else {
          storagePath = 'users/${user.uid}/photos/$filename';
        }

        // Create storage reference
        final photoRef = _storage.ref().child(storagePath);

        // Add metadata
        final metadata = SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'uploaderId': user.uid,
            'timestamp': timestamp.toIso8601String(),
            if (trailId != null) 'trailId': trailId,
            if (eventId != null) 'eventId': eventId,
            if (caption != null) 'caption': caption,
          },
        );

        // Upload main photo with retry mechanism
        int retryCount = 0;
        bool uploadSuccess = false;
        Exception? lastError;

        while (retryCount < 3 && !uploadSuccess) {
          try {
            // Upload the file
            final uploadTask = photoRef.putFile(file, metadata);
            await uploadTask.whenComplete(() {});

            // Get download URL
            url = await photoRef.getDownloadURL();
            uploadSuccess = true;
          } catch (e) {
            lastError = e is Exception ? e : Exception(e.toString());
            retryCount++;
            await Future.delayed(Duration(seconds: 2 * retryCount)); // Exponential backoff
          }
        }

        if (!uploadSuccess) {
          throw lastError ?? Exception('Failed to upload photo after multiple attempts');
        }

        // Upload thumbnail if available
        if (thumbnailData != null) {
          final thumbnailFilename = 'thumb_$photoId${path.extension(file.path)}';
          String thumbnailStoragePath;

          if (trailId != null) {
            thumbnailStoragePath = 'trails/$trailId/thumbnails/$thumbnailFilename';
          } else if (eventId != null) {
            thumbnailStoragePath = 'events/$eventId/thumbnails/$thumbnailFilename';
          } else {
            thumbnailStoragePath = 'users/${user.uid}/thumbnails/$thumbnailFilename';
          }

          final thumbnailRef = _storage.ref().child(thumbnailStoragePath);

          try {
            final thumbUploadTask = thumbnailRef.putData(thumbnailData, metadata);
            await thumbUploadTask.whenComplete(() {});
            thumbnailUrl = await thumbnailRef.getDownloadURL();
          } catch (e) {
            AppLogger.warning('Error uploading thumbnail (non-fatal): $e');
            // Continue without thumbnail URL if upload fails
            // We'll still have the local thumbnail and the main image URL
          }
        }
      } catch (e) {
        AppLogger.error('Error in Firebase Storage operations: $e');
        // If remote storage fails but we have local copies, create record with local paths only
        if (localPath.isNotEmpty) {
          final photoData = PhotoData(
            id: photoId,
            url: localPath,
            thumbnailUrl: thumbnailLocalPath,
            uploaderId: user.uid,
            trailId: trailId,
            eventId: eventId,
            uploadDate: timestamp,
            caption: caption,
          );

          // Save to local DB only
          final box = await getPhotoBox();
          await box.add(photoData);

          // Mark for later sync
          try {
            Box syncBox = await Hive.openBox('syncQueue');
            await syncBox.add({
              'type': 'photo',
              'id': photoId,
              'path': localPath,
              'action': 'upload',
              'timestamp': timestamp.millisecondsSinceEpoch,
            });
          } catch (syncError) {
            AppLogger.error('Failed to add to sync queue: $syncError');
          }

          return photoData;
        } else {
          // If we don't even have local copies, rethrow
          rethrow;
        }
      }

      // Step 4: Create PhotoData object
      final photoData = PhotoData(
        id: photoId,
        url: url,
        thumbnailUrl: thumbnailUrl,
        uploaderId: user.uid,
        trailId: trailId,
        eventId: eventId,
        uploadDate: timestamp,
        caption: caption,
      );

      // Step 5: Save to Firestore with retry
      try {
        await _firestore.collection('photos').doc(photoId).set(photoData.toJson());
      } catch (e) {
        AppLogger.error('Error saving photo to Firestore: $e');
        // If Firestore fails, we still have the image in Storage and locally
      }

      // Step 6: Save to local database
      try {
        final box = await getPhotoBox();
        await box.add(photoData);
      } catch (e) {
        AppLogger.error('Error saving photo to local database: $e');
        // Non-fatal, as we already have it in Firestore
      }

      AppLogger.info('Photo upload complete. ID: $photoId, URL: $url');
      return photoData;
    } catch (e) {
      AppLogger.error('Error in uploadPhoto: $e');
      rethrow;
    }
  }

  // Get photos for a trail with improved caching and sync
  Future<List<PhotoData>> getPhotosForTrail(String trailId) async {
    try {
      final now = DateTime.now();
      final cacheKey = 'trailPhotosLastFetched_$trailId';
      List<PhotoData> result = [];
      bool shouldFetchRemote = true;

      // Try cache first
      try {
        final box = await getPhotoBox();
        final List<PhotoData> cachedPhotos = [];

        for (var i = 0; i < box.length; i++) {
          final photo = box.getAt(i);
          if (photo != null && photo.trailId == trailId) {
            cachedPhotos.add(photo);
          }
        }

        // If cache has items and they're recent (15 mins), use them
        final lastFetchString = await Hive.box('settings').get(cacheKey);
        DateTime? lastFetch;

        if (lastFetchString != null) {
          lastFetch = DateTime.tryParse(lastFetchString);
        }

        if (cachedPhotos.isNotEmpty &&
            lastFetch != null &&
            now.difference(lastFetch).inMinutes < 15) {
          shouldFetchRemote = false;
          result = cachedPhotos;
        }
      } catch (e) {
        AppLogger.error('Error accessing photo cache: $e');
        // Continue to remote fetch if cache fails
      }

      // Fetch from Firestore if needed
      if (shouldFetchRemote) {
        try {
          final snapshot = await _firestore.collection('photos')
              .where('trailId', isEqualTo: trailId)
              .orderBy('uploadDate', descending: true)
              .get();

          // Process results
          final List<PhotoData> remotePhotos = [];
          final box = await getPhotoBox();

          for (var doc in snapshot.docs) {
            try {
              final data = doc.data();

              // Convert Firestore Timestamp to DateTime
              if (data['uploadDate'] is Timestamp) {
                data['uploadDate'] = (data['uploadDate'] as Timestamp).toDate();
              }

              // Parse photo data
              final photo = PhotoData.fromJson(data);
              remotePhotos.add(photo);

              // Save to cache, replacing any existing with same ID
              int? existingKey;
              for (var i = 0; i < box.length; i++) {
                final existing = box.getAt(i);
                if (existing != null && existing.id == photo.id) {
                  existingKey = box.keyAt(i);
                  break;
                }
              }

              if (existingKey != null) {
                await box.put(existingKey, photo);
              } else {
                await box.add(photo);
              }
            } catch (e) {
              AppLogger.error('Error processing photo doc ${doc.id}: $e');
            }
          }

          // Update last fetch time
          await Hive.box('settings').put(cacheKey, now.toIso8601String());

          result = remotePhotos;
        } catch (e) {
          AppLogger.error('Error fetching photos from Firestore: $e');
          // If remote fetch fails but we have cache, return cached results
          if (result.isEmpty) {
            // Try one more time to get cache if we haven't already
            final box = await getPhotoBox();
            for (var i = 0; i < box.length; i++) {
              final photo = box.getAt(i);
              if (photo != null && photo.trailId == trailId) {
                result.add(photo);
              }
            }
          }
        }
      }

      // Sort by date (newest first)
      result.sort((a, b) => b.uploadDate.compareTo(a.uploadDate));
      return result;
    } catch (e) {
      AppLogger.error('Error in getPhotosForTrail: $e');
      return [];
    }
  }

  // Get photos for an event with improved caching
  Future<List<PhotoData>> getPhotosForEvent(String eventId) async {
    try {
      final now = DateTime.now();
      final cacheKey = 'eventPhotosLastFetched_$eventId';
      List<PhotoData> result = [];
      bool shouldFetchRemote = true;

      // Try cache first
      try {
        final box = await getPhotoBox();
        final List<PhotoData> cachedPhotos = [];

        for (var i = 0; i < box.length; i++) {
          final photo = box.getAt(i);
          if (photo != null && photo.eventId == eventId) {
            cachedPhotos.add(photo);
          }
        }

        // If cache has items and they're recent (15 mins), use them
        final lastFetchString = await Hive.box('settings').get(cacheKey);
        DateTime? lastFetch;

        if (lastFetchString != null) {
          lastFetch = DateTime.tryParse(lastFetchString);
        }

        if (cachedPhotos.isNotEmpty &&
            lastFetch != null &&
            now.difference(lastFetch).inMinutes < 15) {
          shouldFetchRemote = false;
          result = cachedPhotos;
        }
      } catch (e) {
        AppLogger.error('Error accessing photo cache: $e');
        // Continue to remote fetch if cache fails
      }

      // Fetch from Firestore if needed
      if (shouldFetchRemote) {
        try {
          final snapshot = await _firestore.collection('photos')
              .where('eventId', isEqualTo: eventId)
              .orderBy('uploadDate', descending: true)
              .get();

          // Process results
          final List<PhotoData> remotePhotos = [];
          final box = await getPhotoBox();

          for (var doc in snapshot.docs) {
            try {
              final data = doc.data();

              // Convert Firestore Timestamp to DateTime
              if (data['uploadDate'] is Timestamp) {
                data['uploadDate'] = (data['uploadDate'] as Timestamp).toDate();
              }

              // Parse photo data
              final photo = PhotoData.fromJson(data);
              remotePhotos.add(photo);

              // Save to cache, replacing any existing with same ID
              int? existingKey;
              for (var i = 0; i < box.length; i++) {
                final existing = box.getAt(i);
                if (existing != null && existing.id == photo.id) {
                  existingKey = box.keyAt(i);
                  break;
                }
              }

              if (existingKey != null) {
                await box.put(existingKey, photo);
              } else {
                await box.add(photo);
              }
            } catch (e) {
              AppLogger.error('Error processing photo doc ${doc.id}: $e');
            }
          }

          // Update last fetch time
          await Hive.box('settings').put(cacheKey, now.toIso8601String());

          result = remotePhotos;
        } catch (e) {
          AppLogger.error('Error fetching photos from Firestore: $e');
          // If remote fetch fails but we have cache, return cached results
          if (result.isEmpty) {
            // Try one more time to get cache if we haven't already
            final box = await getPhotoBox();
            for (var i = 0; i < box.length; i++) {
              final photo = box.getAt(i);
              if (photo != null && photo.eventId == eventId) {
                result.add(photo);
              }
            }
          }
        }
      }

      // Sort by date (newest first)
      result.sort((a, b) => b.uploadDate.compareTo(a.uploadDate));
      return result;
    } catch (e) {
      AppLogger.error('Error in getPhotosForEvent: $e');
      return [];
    }
  }

  // Get user's uploaded photos with pagination support
  Future<List<PhotoData>> getUserPhotos(String? userId, {int limit = 20, PhotoData? lastPhoto}) async {
    try {
      final String targetUserId = userId ?? _auth.currentUser?.uid ?? '';

      if (targetUserId.isEmpty) {
        throw Exception('User ID is required');
      }

      final now = DateTime.now();
      final cacheKey = 'userPhotosLastFetched_$targetUserId';
      List<PhotoData> result = [];
      bool shouldFetchRemote = true;

      // Try cache first for non-paginated requests
      if (lastPhoto == null) {
        try {
          final box = await getPhotoBox();
          final List<PhotoData> cachedPhotos = [];

          for (var i = 0; i < box.length; i++) {
            final photo = box.getAt(i);
            if (photo != null && photo.uploaderId == targetUserId) {
              cachedPhotos.add(photo);
            }
          }

          // Sort by date (newest first)
          cachedPhotos.sort((a, b) => b.uploadDate.compareTo(a.uploadDate));

          // If cache has items and they're recent (15 mins), use them
          final lastFetchString = await Hive.box('settings').get(cacheKey);
          DateTime? lastFetch;

          if (lastFetchString != null) {
            lastFetch = DateTime.tryParse(lastFetchString);
          }

          if (cachedPhotos.isNotEmpty &&
              lastFetch != null &&
              now.difference(lastFetch).inMinutes < 15) {
            shouldFetchRemote = false;
            result = cachedPhotos.take(limit).toList();
          }
        } catch (e) {
          AppLogger.error('Error accessing photo cache: $e');
          // Continue to remote fetch if cache fails
        }
      }

      // Fetch from Firestore if needed or for pagination
      if (shouldFetchRemote) {
        try {
          // Start with basic query
          Query query = _firestore.collection('photos')
              .where('uploaderId', isEqualTo: targetUserId)
              .orderBy('uploadDate', descending: true);

          // Add pagination if lastPhoto is provided
          if (lastPhoto != null) {
            query = query.startAfter([Timestamp.fromDate(lastPhoto.uploadDate)]);
          }

          // Add limit
          query = query.limit(limit);

          // Execute query
          final snapshot = await query.get();

          // Process results
          final List<PhotoData> remotePhotos = [];
          final box = await getPhotoBox();

          for (var doc in snapshot.docs) {
            try {
              // Safely extract data as Map<String, dynamic>
              final Map<String, dynamic> data;
              try {
                data = doc.data() as Map<String, dynamic>;
              } catch (e) {
                AppLogger.error('Failed to cast document data to Map<String, dynamic>: $e');
                continue;
              }

              // Convert Firestore Timestamp to DateTime
              var uploadDate = data['uploadDate'];
              if (uploadDate is Timestamp) {
                data['uploadDate'] = uploadDate.toDate();
              }

              // Parse photo data
              final photo = PhotoData.fromJson(data);
              remotePhotos.add(photo);

              // Save to cache, replacing any existing with same ID
              int? existingKey;
              for (var i = 0; i < box.length; i++) {
                final existing = box.getAt(i);
                if (existing != null && existing.id == photo.id) {
                  existingKey = box.keyAt(i);
                  break;
                }
              }

              if (existingKey != null) {
                await box.put(existingKey, photo);
              } else {
                await box.add(photo);
              }
            } catch (e) {
              AppLogger.error('Error processing photo doc ${doc.id}: $e');
            }
          }

          // Update last fetch time only for non-paginated requests
          if (lastPhoto == null) {
            await Hive.box('settings').put(cacheKey, now.toIso8601String());
          }

          result = remotePhotos;
        } catch (e) {
          AppLogger.error('Error fetching photos from Firestore: $e');
          // If remote fetch fails but we need data, try local cache
          if (result.isEmpty) {
            final box = await getPhotoBox();
            final List<PhotoData> cachedPhotos = [];

            for (var i = 0; i < box.length; i++) {
              final photo = box.getAt(i);
              if (photo != null && photo.uploaderId == targetUserId) {
                cachedPhotos.add(photo);
              }
            }

            // Sort by date (newest first)
            cachedPhotos.sort((a, b) => b.uploadDate.compareTo(a.uploadDate));

            // Handle pagination locally
            if (lastPhoto != null) {
              final lastIndex = cachedPhotos.indexWhere((p) => p.id == lastPhoto.id);
              if (lastIndex != -1 && lastIndex + 1 < cachedPhotos.length) {
                result = cachedPhotos.sublist(lastIndex + 1,
                    (lastIndex + 1 + limit) > cachedPhotos.length
                        ? cachedPhotos.length
                        : (lastIndex + 1 + limit));
              }
            } else {
              result = cachedPhotos.take(limit).toList();
            }
          }
        }
      }

      return result;
    } catch (e) {
      AppLogger.error('Error in getUserPhotos: $e');
      return [];
    }
  }

  // Delete a photo with improved robustness
  Future<bool> deletePhoto(String photoId) async {
    try {
      // Get the photo document first to have all needed info
      PhotoData? photoData;

      // Try local first
      final box = await getPhotoBox();
      for (var i = 0; i < box.length; i++) {
        final photo = box.getAt(i);
        if (photo != null && photo.id == photoId) {
          photoData = photo;
          break;
        }
      }

      // If not found locally, try Firestore
      if (photoData == null) {
        final doc = await _firestore.collection('photos').doc(photoId).get();
        if (doc.exists) {
          final data = doc.data()!;
          if (data['uploadDate'] is Timestamp) {
            data['uploadDate'] = (data['uploadDate'] as Timestamp).toDate();
          }
          photoData = PhotoData.fromJson(data);
        } else {
          throw Exception('Photo not found: $photoId');
        }
      }

      // Now that we have photo data, delete from all locations
      List<Future> deleteTasks = [];

      // 1. Delete from Firebase Storage if URL exists
      if (photoData.url.startsWith('http')) {
        try {
          final ref = _storage.refFromURL(photoData.url);
          deleteTasks.add(ref.delete().catchError((e) {
            AppLogger.warning('Non-fatal error deleting photo file: $e');
          }));
        } catch (e) {
          AppLogger.warning('Error getting storage reference: $e');
        }
      }

      // 2. Delete thumbnail from Firebase Storage if exists
      if (photoData.thumbnailUrl != null &&
          photoData.thumbnailUrl!.startsWith('http') &&
          photoData.thumbnailUrl != photoData.url) {
        try {
          final thumbRef = _storage.refFromURL(photoData.thumbnailUrl!);
          deleteTasks.add(thumbRef.delete().catchError((e) {
            AppLogger.warning('Non-fatal error deleting thumbnail file: $e');
          }));
        } catch (e) {
          AppLogger.warning('Error getting thumbnail reference: $e');
        }
      }

      // 3. Delete from Firestore
      deleteTasks.add(_firestore.collection('photos').doc(photoId).delete());

      // 4. Delete local files if paths are known (reconstruct paths if needed)
      final directory = await getApplicationDocumentsDirectory();
      final photosDir = path.join(directory.path, 'photos');

      // Try to find local file paths
      List<String> possiblePaths = [
        path.join(photosDir, 'photo_$photoId.jpg'),
        path.join(photosDir, 'photo_$photoId.png'),
        path.join(photosDir, 'photo_$photoId.jpeg'),
      ];

      for (final filePath in possiblePaths) {
        final file = File(filePath);
        if (await file.exists()) {
          deleteTasks.add(file.delete().catchError((e) {
            AppLogger.warning('Non-fatal error deleting local file: $e');
          }));
        }
      }

      // Try to find local thumbnail paths
      List<String> possibleThumbPaths = [
        path.join(photosDir, 'thumbnails', 'thumb_$photoId.jpg'),
        path.join(photosDir, 'thumbnails', 'thumb_$photoId.png'),
        path.join(photosDir, 'thumbnails', 'thumb_$photoId.jpeg'),
      ];

      for (final filePath in possibleThumbPaths) {
        final file = File(filePath);
        if (await file.exists()) {
          deleteTasks.add(file.delete().catchError((e) {
            AppLogger.warning('Non-fatal error deleting local thumbnail: $e');
          }));
        }
      }

      // 5. Delete from local database
      int? keyToDelete;
      for (var i = 0; i < box.length; i++) {
        final photo = box.getAt(i);
        if (photo != null && photo.id == photoId) {
          keyToDelete = box.keyAt(i);
          break;
        }
      }

      if (keyToDelete != null) {
        await box.delete(keyToDelete);
      }

      // Wait for all delete operations to complete
      await Future.wait(deleteTasks);

      AppLogger.info('Photo deleted successfully: $photoId');
      return true;
    } catch (e) {
      AppLogger.error('Error deleting photo: $e');
      return false;
    }
  }

  // Delete all photos for a trail
  Future<void> deletePhotosForTrail(String trailId) async {
    try {
      // Get all photos for this trail
      final photos = await getPhotosForTrail(trailId);

      // Delete each photo
      int successCount = 0;
      for (var photo in photos) {
        final success = await deletePhoto(photo.id);
        if (success) successCount++;
      }

      AppLogger.info('Deleted $successCount/${photos.length} photos for trail $trailId');
    } catch (e) {
      AppLogger.error('Error deleting photos for trail $trailId: $e');
      // Continue with other operations
    }
  }

  // Delete all photos for an event
  Future<void> deletePhotosForEvent(String eventId) async {
    try {
      // Get all photos for this event
      final photos = await getPhotosForEvent(eventId);

      // Delete each photo
      int successCount = 0;
      for (var photo in photos) {
        final success = await deletePhoto(photo.id);
        if (success) successCount++;
      }

      AppLogger.info('Deleted $successCount/${photos.length} photos for event $eventId');
    } catch (e) {
      AppLogger.error('Error deleting photos for event $eventId: $e');
      // Continue with other operations
    }
  }

  // Update photo caption and metadata
  Future<bool> updatePhotoMetadata(String photoId, {
    String? caption,
    String? trailId,
    String? eventId,
  }) async {
    try {
      // Get current photo data
      PhotoData? photoData;

      // Try local first
      final box = await getPhotoBox();
      int? keyToUpdate;

      for (var i = 0; i < box.length; i++) {
        final photo = box.getAt(i);
        if (photo != null && photo.id == photoId) {
          photoData = photo;
          keyToUpdate = box.keyAt(i);
          break;
        }
      }

      // If not found locally, try Firestore
      if (photoData == null) {
        final doc = await _firestore.collection('photos').doc(photoId).get();
        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          if (data['uploadDate'] is Timestamp) {
            data['uploadDate'] = (data['uploadDate'] as Timestamp).toDate();
          }
          photoData = PhotoData.fromJson(data);
        } else {
          throw Exception('Photo not found: $photoId');
        }
      }

      // Create updated photo
      final updatedPhoto = photoData.copyWith(
        caption: caption ?? photoData.caption,
        trailId: trailId ?? photoData.trailId,
        eventId: eventId ?? photoData.eventId,
      );

      // Update in Firestore
      await _firestore.collection('photos').doc(photoId).update({
        if (caption != null) 'caption': caption,
        if (trailId != null) 'trailId': trailId,
        if (eventId != null) 'eventId': eventId,
      });

      // Update local cache
      if (keyToUpdate != null) {
        await box.put(keyToUpdate, updatedPhoto);
      } else {
        await box.add(updatedPhoto);
      }

      AppLogger.info('Photo metadata updated successfully: $photoId');
      return true;
    } catch (e) {
      AppLogger.error('Error updating photo metadata: $e');
      return false;
    }
  }

// Add the wrapper method for updatePhotoCaption
  Future<bool> updatePhotoCaption(String photoId, String caption) async {
    return updatePhotoMetadata(photoId, caption: caption);
  }

  // Get a single photo by ID
  Future<PhotoData?> getPhotoById(String photoId) async {
    try {
      // Check cache first
      final box = await getPhotoBox();

      for (var i = 0; i < box.length; i++) {
        final photo = box.getAt(i);
        if (photo != null && photo.id == photoId) {
          return photo;
        }
      }

      // Not found in cache, try Firestore
      final doc = await _firestore.collection('photos').doc(photoId).get();

      if (!doc.exists || doc.data() == null) {
        return null;
      }

      final data = doc.data()!;

      // Convert Timestamp to DateTime
      if (data['uploadDate'] is Timestamp) {
        data['uploadDate'] = (data['uploadDate'] as Timestamp).toDate();
      }

      // Create photo object
      final photo = PhotoData.fromJson(data);

      // Save to cache
      await box.add(photo);

      return photo;
    } catch (e) {
      AppLogger.error('Error getting photo $photoId: $e');
      return null;
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

  // Helper method to ensure Firebase index exists
  Future<void> ensurePhotoIndexExists() async {
    try {
      // This method just logs a reminder for creating the necessary index
      // Actual index creation happens in the Firebase console
      AppLogger.info('Checking if necessary Firestore indexes exist for photos...');

      // Test a query that requires the index
      try {
        await _firestore.collection('photos')
            .where('uploaderId', isEqualTo: 'test')
            .orderBy('uploadDate', descending: true)
            .limit(1)
            .get();
        AppLogger.info('Photo index appears to be properly configured.');
      } catch (e) {
        // The error message will contain a URL to create the index
        String errorMessage = e.toString();
        if (errorMessage.contains('https://console.firebase.google.com')) {
          // Extract the URL
          final regex = RegExp(r'https:\/\/console\.firebase\.google\.com[^"^\s]+');
          final match = regex.firstMatch(errorMessage);
          if (match != null) {
            final indexUrl = match.group(0);
            AppLogger.warning('Photo queries require an index. Create it here: $indexUrl');
          } else {
            AppLogger.warning('Photo queries require an index. Check Firebase console.');
          }
        } else {
          AppLogger.warning('Photos index test failed: $e');
        }
      }
    } catch (e) {
      AppLogger.error('Error checking photo indexes: $e');
    }
  }

  // Method to check local storage and recover any unsaved photos
  Future<void> recoverUnsyncedPhotos() async {
    try {
      // Get sync queue if it exists
      if (!Hive.isBoxOpen('syncQueue')) {
        await Hive.openBox('syncQueue');
      }

      final syncBox = Hive.box('syncQueue');
      if (syncBox.isEmpty) return;

      // Process any pending uploads
      for (var i = 0; i < syncBox.length; i++) {
        final item = syncBox.getAt(i);
        if (item != null &&
            item is Map &&
            item['type'] == 'photo' &&
            item['action'] == 'upload') {
          final String photoId = item['id'] as String;
          final String localPath = item['path'] as String;

          // Check if the file exists
          final file = File(localPath);
          if (await file.exists()) {
            try {
              // Get the photo from the photos box
              final photosBox = await getPhotoBox();
              PhotoData? photoData;

              for (var j = 0; j < photosBox.length; j++) {
                final photo = photosBox.getAt(j);
                if (photo != null && photo.id == photoId) {
                  photoData = photo;
                  break;
                }
              }

              if (photoData != null) {
                // Try to re-upload to Firebase Storage
                final storageRef = _storage.ref().child('photos/recovered/$photoId${path.extension(localPath)}');
                final uploadTask = storageRef.putFile(file);
                await uploadTask.whenComplete(() {});
                final url = await storageRef.getDownloadURL();

                // Update the photo data
                final updatedPhoto = photoData.copyWith(url: url);

                // Save to Firestore
                await _firestore.collection('photos').doc(photoId).set(updatedPhoto.toJson());

                // Update local cache
                for (var j = 0; j < photosBox.length; j++) {
                  final photo = photosBox.getAt(j);
                  if (photo != null && photo.id == photoId) {
                    await photosBox.putAt(j, updatedPhoto);
                    break;
                  }
                }

                // Remove from sync queue
                await syncBox.deleteAt(i);
                i--; // Adjust index since we removed an item

                AppLogger.info('Recovered unsync photo: $photoId');
              }
            } catch (e) {
              AppLogger.error('Error recovering photo $photoId: $e');
            }
          } else {
            // File no longer exists, remove from queue
            await syncBox.deleteAt(i);
            i--; // Adjust index
          }
        }
      }
    } catch (e) {
      AppLogger.error('Error in recoverUnsyncedPhotos: $e');
    }
  }

  // Enhanced method to get events by filter criteria with time-based filtering
  Future<List<EventData>> getFilteredEvents(EventFilter filter) async {
    try {
      // Start with a Firestore query
      Query query = _firestore.collection('events');

      // Apply initial database-level filters
      final now = DateTime.now();

      // Apply date range filters if specified
      if (filter.startDate != null) {
        // Events ending after this start date
        query = query.where('endDate', isGreaterThanOrEqualTo: filter.startDate!.millisecondsSinceEpoch);
      }

      if (filter.endDate != null) {
        // Events starting before this end date
        query = query.where('eventDate', isLessThanOrEqualTo: filter.endDate!.millisecondsSinceEpoch);
      }

      // Apply category filter if a single category specified
      if (filter.category != null && filter.category!.isNotEmpty) {
        query = query.where('category', isEqualTo: filter.category);
      }

      // Apply difficulty level filter if specified
      if (filter.difficultyLevel != null) {
        query = query.where('difficulty', isEqualTo: filter.difficultyLevel);
      } else {
        // Apply min/max difficulty if specified
        if (filter.minDifficulty != null) {
          query = query.where('difficulty', isGreaterThanOrEqualTo: filter.minDifficulty);
        }

        if (filter.maxDifficulty != null) {
          query = query.where('difficulty', isLessThanOrEqualTo: filter.maxDifficulty);
        }
      }

      // Execute the query
      final snapshot = await query.get();

      // Convert results to EventData objects
      List<EventData> allEvents = snapshot.docs
          .map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        // Ensure the ID is set correctly
        if (data['id'] == null || data['id'].isEmpty) {
          data['id'] = doc.id;
        }

        // Handle timestamp conversions
        if (data['eventDate'] is Timestamp) {
          data['eventDate'] = (data['eventDate'] as Timestamp).toDate();
        }
        if (data['endDate'] is Timestamp) {
          data['endDate'] = (data['endDate'] as Timestamp).toDate();
        }

        return EventData.fromMap(data);
      })
          .toList();

      // Apply additional in-memory filters
      return allEvents.where((event) {
        // Apply time-based filters
        final isPast = event.endDate != null
            ? event.endDate!.isBefore(now)
            : event.eventDate.add(event.duration ?? const Duration(hours: 2)).isBefore(now);

        final isCurrent = event.eventDate.isBefore(now) &&
            (event.endDate != null
                ? event.endDate!.isAfter(now)
                : event.eventDate.add(event.duration ?? const Duration(hours: 2)).isAfter(now));

        final isFuture = event.eventDate.isAfter(now);

        bool passesTimeFilter = (isPast && filter.includePastEvents) ||
            (isCurrent && filter.includeCurrentEvents) ||
            (isFuture && filter.includeFutureEvents);

        if (!passesTimeFilter) return false;

        // Apply location filters if specified
        if (filter.userLatitude != null && filter.userLongitude != null) {
          if (event.latitude == null || event.longitude == null) return false;

          // Calculate distance using Haversine formula
          final distance = _calculateDistance(
              filter.userLatitude!, filter.userLongitude!,
              event.latitude!, event.longitude!
          );

          // Use either maxDistance or radiusInKm (for consistency)
          final maxDistanceKm = filter.maxDistance ?? filter.radiusInKm;
          if (maxDistanceKm != null && distance > maxDistanceKm) return false;
        }

        // Apply location text search if specified
        if (filter.locationQuery != null && filter.locationQuery!.isNotEmpty) {
          final locationQuery = filter.locationQuery!.toLowerCase();
          if (!((event.location ?? '').toLowerCase().contains(locationQuery))) {
            return false;
          }
        }

        // Apply categories filter (for multiple categories)
        if (filter.categories.isNotEmpty) {
          if (event.category == null || !filter.categories.contains(event.category)) {
            return false;
          }
        }

        // Apply search query if specified
        if (filter.searchQuery != null && filter.searchQuery!.isNotEmpty) {
          final query = filter.searchQuery!.toLowerCase();
          if (!event.title.toLowerCase().contains(query) &&
              !(event.description?.toLowerCase().contains(query) ?? false)) {
            return false;
          }
        }

        // Apply favorites filter
        if (filter.favoritesOnly || filter.showOnlyFavorites) {
          final user = _auth.currentUser;
          if (user != null) {
            // Check if we have favorites in memory
            bool isInFavorites = false;
            try {
              final favBox = Hive.box<String>('favoriteEvents');
              isInFavorites = favBox.values.contains(event.id);
            } catch (e) {
              AppLogger.error('Error checking favorites: $e');
            }
            if (!isInFavorites) return false;
          } else {
            return false;
          }
        }

        return true;
      }).toList();
    } catch (e) {
      AppLogger.error('Error applying filters: $e');
      // Return empty list or fallback to local cache
      try {
        final box = await getEventBox();
        final events = box.values.toList();
        AppLogger.info('Using cached events as fallback after filter error');
        return events;
      } catch (e2) {
        AppLogger.error('Failed to get cached events: $e2');
        return [];
      }
    }
  }

  // Get upcoming events (events that start in the future)
  Future<List<EventData>> getUpcomingEvents({int limit = 10}) async {
    try {
      final now = DateTime.now();

      // Query Firestore
      final snapshot = await _firestore.collection('events')
          .where('eventDate', isGreaterThan: Timestamp.fromDate(now))
          .orderBy('eventDate')
          .limit(limit)
          .get();

      // Convert to EventData objects
      List<EventData> events = snapshot.docs
          .map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        // Ensure ID is set
        if (data['id'] == null || data['id'].isEmpty) {
          data['id'] = doc.id;
        }

        // Handle timestamp conversions
        if (data['eventDate'] is Timestamp) {
          data['eventDate'] = (data['eventDate'] as Timestamp).toDate();
        }
        if (data['endDate'] is Timestamp) {
          data['endDate'] = (data['endDate'] as Timestamp).toDate();
        }

        return EventData.fromMap(data);
      })
          .toList();

      // Cache these events
      final box = await getEventBox();
      for (var event in events) {
        // Check if already in cache
        bool found = false;
        for (var i = 0; i < box.length; i++) {
          final existingEvent = box.getAt(i);
          if (existingEvent != null && existingEvent.id == event.id) {
            found = true;
            await box.putAt(i, event); // Update with latest data
            break;
          }
        }

        if (!found) {
          await box.add(event); // Add if not in cache
        }
      }

      return events;
    } catch (e) {
      AppLogger.error('Error getting upcoming events: $e');

      // Try to get from cache as fallback
      try {
        final now = DateTime.now();
        final box = await getEventBox();
        final allEvents = box.values.toList();

        // Filter to upcoming events
        final upcomingEvents = allEvents
            .where((event) => event.eventDate.isAfter(now))
            .toList();

        // Sort by date
        upcomingEvents.sort((a, b) => a.eventDate.compareTo(b.eventDate));

        // Apply limit
        if (upcomingEvents.length > limit) {
          return upcomingEvents.sublist(0, limit);
        }

        return upcomingEvents;
      } catch (e2) {
        AppLogger.error('Failed to get cached upcoming events: $e2');
        return [];
      }
    }
  }

  // Get ongoing events (events happening now)
  Future<List<EventData>> getOngoingEvents() async {
    try {
      final now = DateTime.now();

      // This query is more complex and may require multiple Firestore calls
      // First, get events that have started but haven't ended
      final snapshot = await _firestore.collection('events')
          .where('eventDate', isLessThanOrEqualTo: Timestamp.fromDate(now))
          .get();

      // Process and filter client-side
      List<EventData> events = [];

      for (var doc in snapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          // Ensure ID is set
          if (data['id'] == null || data['id'].isEmpty) {
            data['id'] = doc.id;
          }

          // Handle timestamp conversions
          DateTime eventDate;
          if (data['eventDate'] is Timestamp) {
            eventDate = (data['eventDate'] as Timestamp).toDate();
          } else if (data['eventDate'] is DateTime) {
            eventDate = data['eventDate'];
          } else {
            continue; // Skip if we can't determine event date
          }

          // Handle end date
          DateTime endDate;
          if (data['endDate'] is Timestamp) {
            endDate = (data['endDate'] as Timestamp).toDate();
          } else if (data['endDate'] is DateTime) {
            endDate = data['endDate'];
          } else {
            Duration duration;
            if (data['duration'] is int) {
              duration = Duration(minutes: data['duration']);
            } else if (data['duration'] is Duration) {
              duration = data['duration'];
            } else {
              duration = const Duration(hours: 2);
            }
            endDate = eventDate.add(duration);
          }

          // Check if event is still ongoing
          if (endDate.isAfter(now)) {
            events.add(EventData.fromMap(data));
          }
        } catch (e) {
          AppLogger.error('Error processing ongoing event doc: $e');
        }
      }

      // Cache these events
      final box = await getEventBox();
      for (var event in events) {
        // Check if already in cache
        bool found = false;
        for (var i = 0; i < box.length; i++) {
          final existingEvent = box.getAt(i);
          if (existingEvent != null && existingEvent.id == event.id) {
            found = true;
            await box.putAt(i, event); // Update with latest data
            break;
          }
        }

        if (!found) {
          await box.add(event); // Add if not in cache
        }
      }

      return events;
    } catch (e) {
      AppLogger.error('Error getting ongoing events: $e');

      // Try to get from cache as fallback
      try {
        final now = DateTime.now();
        final box = await getEventBox();
        final allEvents = box.values.toList();

        // Filter to ongoing events
        return allEvents.where((event) {
          final eventEnd = event.endDate ??
              event.eventDate.add(event.duration ?? const Duration(hours: 2));
          return event.eventDate.isBefore(now) && eventEnd.isAfter(now);
        }).toList();
      } catch (e2) {
        AppLogger.error('Failed to get cached ongoing events: $e2');
        return [];
      }
    }
  }

  // Get past events (events that have already ended)
  Future<List<EventData>> getPastEvents({int limit = 20}) async {
    try {
      final now = DateTime.now();

      // This query requires additional client-side filtering
      // We'll fetch events with end dates in the past
      final snapshot = await _firestore.collection('events')
          .orderBy('eventDate', descending: true)
          .get();

      // Process and filter client-side
      List<EventData> events = [];

      for (var doc in snapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          // Ensure ID is set
          if (data['id'] == null || data['id'].isEmpty) {
            data['id'] = doc.id;
          }

          // Handle timestamp conversions
          DateTime eventDate;
          if (data['eventDate'] is Timestamp) {
            eventDate = (data['eventDate'] as Timestamp).toDate();
          } else if (data['eventDate'] is DateTime) {
            eventDate = data['eventDate'];
          } else {
            continue; // Skip if we can't determine event date
          }

          // Handle end date
          DateTime endDate;
          if (data['endDate'] is Timestamp) {
            endDate = (data['endDate'] as Timestamp).toDate();
          } else if (data['endDate'] is DateTime) {
            endDate = data['endDate'];
          } else {
            Duration duration;
            if (data['duration'] is int) {
              duration = Duration(minutes: data['duration']);
            } else if (data['duration'] is Duration) {
              duration = data['duration'];
            } else {
              duration = const Duration(hours: 2);
            }
            endDate = eventDate.add(duration);
          }

          // Check if event has ended
          if (endDate.isBefore(now)) {
            events.add(EventData.fromMap(data));

            // Apply limit
            if (events.length >= limit) break;
          }
        } catch (e) {
          AppLogger.error('Error processing past event doc: $e');
        }
      }

      // Cache these events
      final box = await getEventBox();
      for (var event in events) {
        // Check if already in cache
        bool found = false;
        for (var i = 0; i < box.length; i++) {
          final existingEvent = box.getAt(i);
          if (existingEvent != null && existingEvent.id == event.id) {
            found = true;
            await box.putAt(i, event); // Update with latest data
            break;
          }
        }

        if (!found) {
          await box.add(event); // Add if not in cache
        }
      }

      return events;
    } catch (e) {
      AppLogger.error('Error getting past events: $e');

      // Try to get from cache as fallback
      try {
        final now = DateTime.now();
        final box = await getEventBox();
        final allEvents = box.values.toList();

        // Filter to past events
        final pastEvents = allEvents.where((event) {
          final eventEnd = event.endDate ??
              event.eventDate.add(event.duration ?? const Duration(hours: 2));
          return eventEnd.isBefore(now);
        }).toList();

        // Sort by date (most recent first)
        pastEvents.sort((a, b) => b.eventDate.compareTo(a.eventDate));

        // Apply limit
        if (pastEvents.length > limit) {
          return pastEvents.sublist(0, limit);
        }

        return pastEvents;
      } catch (e2) {
        AppLogger.error('Failed to get cached past events: $e2');
        return [];
      }
    }
  }

  // Get nearby events from Google Places API
  Future<List<EventData>> getGoogleEvents({
    required double latitude,
    required double longitude,
    required double radiusInKm,
    String? keyword,
  }) async {
    final apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';

    try {
      // Build the Google Places API URL
      final url = Uri.https(
        'maps.googleapis.com',
        '/maps/api/place/nearbysearch/json',
        {
          'location': '$latitude,$longitude',
          'radius': '${(radiusInKm * 1000).round()}', // Convert to meters
          'type': 'point_of_interest',
          'keyword': keyword ?? 'hiking trail nature outdoor',
          'key': apiKey,
        },
      );

      // Make the API request
      final client = http.Client();
      try {
        final response = await client.get(url);

        if (response.statusCode != 200) {
          AppLogger.error('Google Places API error: ${response.statusCode} ${response.body}');
          return [];
        }

        // Parse the response
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        if (data['status'] != 'OK') {
          AppLogger.error('Google Places API error: ${data['status']}');
          return [];
        }

        final results = data['results'] as List;
        List<EventData> events = [];

        for (var place in results) {
          try {
            // Get place details for more information
            final detailsResponse = await _getPlaceDetails(place['place_id'], apiKey);

            if (detailsResponse == null) continue;

            final now = DateTime.now();

            // Create an event from place data
            final event = EventData(
              id: 'google_${place['place_id']}',
              title: place['name'] as String,
              description: detailsResponse['formatted_address'] as String? ??
                  place['vicinity'] as String? ??
                  'No description available',
              eventDate: now, // Current date as placeholder
              endDate: now.add(const Duration(days: 7)), // One week as placeholder
              duration: const Duration(hours: 2), // Default duration
              location: place['vicinity'] as String? ?? '',
              category: _determineCategoryFromTypes(place['types'] as List? ?? []),
              difficulty: _determineDifficultyFromRating(place['rating'] as double? ?? 3.0),
              latitude: place['geometry']['location']['lat'] as double,
              longitude: place['geometry']['location']['lng'] as double,
              // Use photos if available
              imageUrl: _getPhotoUrlFromPlace(place, detailsResponse, apiKey),
              // Mark as external source
              createdBy: 'Google',
            );

            events.add(event);
          } catch (e) {
            AppLogger.error('Error processing Google Places result: $e');
          }
        }

        // Cache these Google events temporarily
        try {
          // Use a separate box for Google events to avoid conflicts
          if (!Hive.isBoxOpen('googleEventsBox')) {
            await Hive.openBox<EventData>('googleEventsBox');
          }

          final box = Hive.box<EventData>('googleEventsBox');
          await box.clear(); // Clear old results

          for (var event in events) {
            await box.add(event);
          }
        } catch (e) {
          AppLogger.error('Error caching Google events: $e');
        }

        return events;
      } finally {
        client.close();
      }
    } catch (e) {
      AppLogger.error('Error fetching Google events: $e');
      return [];
    }
  }

  String _determineCategoryFromTypes(List types) {
    if (types.contains('campground')) return 'Camping';
    if (types.contains('park')) return 'Park';
    if (types.contains('natural_feature')) return 'Nature';
    if (types.contains('point_of_interest')) return 'Point of Interest';
    return 'Outdoor';
  }

// Helper method to determine difficulty from rating
  int _determineDifficultyFromRating(double rating) {
    if (rating >= 4.5) return 4; // Challenging but rewarding
    if (rating >= 4.0) return 3; // Moderate
    if (rating >= 3.0) return 2; // Easy to moderate
    return 1; // Easy
  }

// Helper method to get photo URL from place data
  String _getPhotoUrlFromPlace(Map<String, dynamic> place, Map<String, dynamic>? details, String apiKey) {
    // Try to get photo reference from place or details
    String? photoReference;

    if (place.containsKey('photos') && place['photos'] is List && (place['photos'] as List).isNotEmpty) {
      photoReference = place['photos'][0]['photo_reference'] as String?;
    } else if (details != null && details.containsKey('photos') &&
        details['photos'] is List && (details['photos'] as List).isNotEmpty) {
      photoReference = details['photos'][0]['photo_reference'] as String?;
    }

    if (photoReference != null) {
      // Construct the photo URL
      return 'https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photoreference=$photoReference&key=$apiKey';
    }

    // Default image if no photo available
    return 'https://maps.gstatic.com/mapfiles/place_api/icons/v1/png_71/generic_business-71.png';
  }

// Helper method to get place details
  Future<Map<String, dynamic>?> _getPlaceDetails(String placeId, String apiKey) async {
    try {
      final detailsUrl = Uri.https(
        'maps.googleapis.com',
        '/maps/api/place/details/json',
        {
          'place_id': placeId,
          'fields': 'name,formatted_address,formatted_phone_number,website,photos,opening_hours,rating,reviews',
          'key': apiKey,
        },
      );

      final client = http.Client();
      try {
        final response = await client.get(detailsUrl);

        if (response.statusCode != 200) {
          return null;
        }

        final data = jsonDecode(response.body) as Map<String, dynamic>;

        if (data['status'] != 'OK') {
          return null;
        }

        return data['result'] as Map<String, dynamic>;
      } finally {
        client.close();
      }
    } catch (e) {
      AppLogger.error('Error getting place details: $e');
      return null;
    }
  }
}