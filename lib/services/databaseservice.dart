import 'package:hive/hive.dart';
import 'package:hiker_connect/models/trail_data.dart';
import 'package:hiker_connect/models/user_model.dart';
import 'package:hiker_connect/models/event_data.dart';
import 'package:hiker_connect/utils/logger.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Box<TrailData>? _trailBox;
  // Fixed type - changed from UserModelAdapter to UserModel
  static Box<UserModel>? _userBox;
  static Box<EventData>? _eventBox;

  factory DatabaseService() {
    return _instance;
  }

  DatabaseService._internal();

  Future<void> init() async {
    try {
      // Don't register adapters here - they should only be registered once in main.dart
      // Just open the boxes
      _trailBox = await Hive.openBox<TrailData>('trailBox');
      _userBox = await Hive.openBox<UserModel>('userBox');
      _eventBox = await Hive.openBox<EventData>('eventBox');
    } catch (e) {
      AppLogger.error('Failed to initialize database: ${e.toString()}');
      rethrow;
    }
  }

  Future<int> insertTrails(TrailData trail) async {
    try {
      final box = _trailBox ?? await Hive.openBox<TrailData>('trailBox');
      final resultKey = await box.add(trail);
      AppLogger.info('Trail inserted successfully: ${trail.trailName}');
      return resultKey;
    } catch (e) {
      AppLogger.error('Failed to insert trail: ${trail.trailName} - ${e.toString()}');
      rethrow;
    }
  }

  Future<List<TrailData>> getTrails() async {
    try {
      final box = _trailBox ?? await Hive.openBox<TrailData>('trailBox');
      return box.values.toList();
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
        AppLogger.info('Trail updated successfully: ${trail.trailName}');
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
      AppLogger.info('No trail found with name: $name');
      return null;
    } catch (e) {
      AppLogger.error('Failed to get trail by name: $name - ${e.toString()}');
      rethrow;
    }
  }
}