import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hiker_connect/models/trail_data.dart';
import 'package:hiker_connect/utils/logger.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Box<TrailData>? _trailBox;

  factory DatabaseService() {
    return _instance;
  }

  DatabaseService._internal();

  Future<Box<TrailData>> getTrailBox() async {
    return _trailBox ?? await Hive.openBox<TrailData>('trailBox');
  }

  Future<void> init() async {
    try {
      // Just open the boxes
      _trailBox = await Hive.openBox<TrailData>('trailBox');

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

  Future<void> syncTrailToFirestore(TrailData trail) async {
    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      final currentUser = FirebaseAuth.instance.currentUser;

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