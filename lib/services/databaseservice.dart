import 'package:hive/hive.dart';
import 'package:hiker_connect/models/trail_data.dart';
import 'package:hiker_connect/models/user_model.dart';
import 'package:hiker_connect/models/event_data.dart';
import 'package:hiker_connect/utils/logger.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();

  Box<TrailData>? _trailBox;
  Box<UserModelAdapter>? _userBox;
  Box<EventData>? _eventBox;

  factory DatabaseService() {
    return _instance;
  }

  DatabaseService._internal();

  // Initialize boxes if not already initialized
  Future<void> init() async {
    if (_trailBox == null || !_trailBox!.isOpen) {
      try {
        Hive.registerAdapter(TrailDataAdapter());
        Hive.registerAdapter(UserModelAdapter());
        Hive.registerAdapter(EventDataAdapter());

        _trailBox = await Hive.openBox<TrailData>('trailBox');
        _userBox = await Hive.openBox<UserModelAdapter>('userBox');
        _eventBox = await Hive.openBox<EventData>('eventBox');
      } catch (e, stackTrace) {
        AppLogger.error('Failed to initialize database: $e', stackTrace: stackTrace);
        rethrow;
      }
    }
  }

  Future<int> insertTrails(TrailData trail) async {
    try {
      await init();
      final box = _trailBox!;
      final resultKey = await box.add(trail);
      AppLogger.info('Trail inserted successfully: ${trail.trailName}');
      return resultKey;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to insert trail: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<List<TrailData>> getTrails() async {
    try {
      await init();
      final box = _trailBox!;
      return box.values.toList();
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get trails: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> updateTrail(String trailName, TrailData trail) async {
    try {
      await init();
      final box = _trailBox!;
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
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to update trail: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<TrailData?> getTrailByName(String name) async {
    try {
      await init();
      final box = _trailBox!;

      for (var i = 0; i < box.length; i++) {
        final trail = box.getAt(i);
        if (trail != null && trail.trailName == name) {
          return trail;
        }
      }
      return null; // Explicitly return null if no trail is found
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get trail by name: $e', stackTrace: stackTrace);
      rethrow;
    }
  }
}