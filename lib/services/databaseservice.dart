import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hiker_connect/models/trail_data.dart';
import 'package:hiker_connect/utils/logger.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Box<TrailData>? _trailBox;
  //static Box<UserModel>? _userBox;
  //static Box<EventData>? _eventBox;

  factory DatabaseService() {
    return _instance;
  }

  DatabaseService._internal();


  Future<Box<TrailData>> getTrailBox() async {
    return _trailBox ?? await Hive.openBox<TrailData>('trailBox');
  }

  // Future<Box<UserModel>> getUserBox() async {
  //   return _userBox ?? await Hive.openBox<UserModel>('userBox');
  // }

  // Future<Box<EventData>> getEventBox() async {
  //   return _eventBox ?? await Hive.openBox<EventData>('eventBox');
  // }

  Future<void> init() async {
    try {
      // Just open the boxes
      _trailBox = await Hive.openBox<TrailData>('trailBox');
      //_userBox = await Hive.openBox<UserModel>('userBox');
     // _eventBox = await Hive.openBox<EventData>('eventBox');

      AppLogger.info('Hive boxes initialized successfully');
    } catch (e) {
      AppLogger.error('Failed to initialize database: ${e.toString()}');
      rethrow;
    }
  }

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

  // Firestore integration methods
  Future<void> syncTrailToFirestore(TrailData trail) async {
    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;

      // Convert trail to Map
      final trailMap = trail.toMap();

      // Add additional metadata for cloud storage
      trailMap['lastUpdated'] = FieldValue.serverTimestamp();
      trailMap['createdBy'] = FirebaseAuth.instance.currentUser?.uid;

      // Save to Firestore
      await firestore.collection('trails').doc(trail.trailId.toString()).set(trailMap);
      AppLogger.info('Trail synced to Firestore: ${trail.trailName}');
    } catch (e) {
      AppLogger.error('Failed to sync trail to Firestore: ${e.toString()}');
      // Don't rethrow here to prevent local operations from failing
    }
  }

  Future<List<TrailData>> getTrailsFromFirestore() async {
    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      final snapshot = await firestore.collection('trails').get();

      if (snapshot.docs.isEmpty) {
        AppLogger.info('No trails found in Firestore');
        return [];
      }

      final trails = snapshot.docs.map((doc) {
        final data = doc.data();

        // Fix for the trailImages field - this is the key issue
        if (data.containsKey('trailImages')) {
          var imagesData = data['trailImages'];
          if (imagesData is String) {
            // Convert single string to a list of one string
            data['trailImages'] = [imagesData];
          } else if (imagesData == null) {
            // Provide default empty list if missing
            data['trailImages'] = [];
          }
        } else {
          // If the field doesn't exist, add an empty list
          data['trailImages'] = [];
        }

        // Convert Firestore data to TrailData
        return TrailData.fromMap(data);
      }).toList();

      // Save fetched trails to local storage for offline access
      final box = _trailBox ?? await Hive.openBox<TrailData>('trailBox');
      for (var trail in trails) {
        await box.add(trail);
      }
      await box.flush();

      AppLogger.info('Retrieved ${trails.length} trails from Firestore');
      return trails;
    } catch (e) {
      AppLogger.error('Failed to get trails from Firestore: ${e.toString()}');
      return []; // Return empty list on error instead of throwing
    }
  }

  Future<TrailData?> getTrailByNameFromFirestore(String name) async {
    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      final snapshot = await firestore.collection('trails')
          .where('trailName', isEqualTo: name)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return null;
      }

      final data = snapshot.docs.first.data();
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
      final FirebaseFirestore firestore = FirebaseFirestore.instance;

      // Delete from Firestore
      await firestore.collection('trails').doc(trailId.toString()).delete();
      AppLogger.info('Trail deleted from Firestore: ID $trailId');
    } catch (e) {
      AppLogger.error('Failed to delete trail from Firestore: ${e.toString()}');
      // Don't rethrow here to prevent local operations from failing
    }
  }
}