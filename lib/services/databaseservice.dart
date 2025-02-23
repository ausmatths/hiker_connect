import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:hiker_connect/models/trail_data.dart';
import 'package:hiker_connect/models/user_model.dart';
import 'package:hiker_connect/models/event_data.dart';
import 'package:hiker_connect/utils/logger.dart';

class DatabaseService {

  static final DatabaseService _instance = DatabaseService._internal();

  static Box<TrailData>? _trailBox;
  static Box<UserModelAdapter>? _userBox;
  static Box<EventData>? _eventBox;


  // static const int _currentVersion = 1;
  //
  // final String _trailTableName = 'trails';
  // final String _name = 'name';
  // final String _description = 'description';
  // final String _difficulty = 'difficulty';
  // final String _notice = 'notice';
  // final String _images = 'images';
  // final String _date = 'date';
  // final String _location = 'location';
  // final String _participants = 'participants';
  // final String _duration = 'duration';
  //
  // DatabaseService._constructor();

  factory DatabaseService() {
    return _instance;
  }
  DatabaseService._internal();


  Future<void> _initDatabase() async {
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

  // Future<void> _onCreate(Database db, int version) async {
  //   try {
  //     await db.execute('''
  //       CREATE TABLE $_trailTableName (
  //         $_name TEXT PRIMARY KEY,
  //         $_description TEXT,
  //         $_difficulty TEXT,
  //         $_notice TEXT,
  //         $_images TEXT,
  //         $_date TEXT,
  //         $_location TEXT,
  //         $_participants INTEGER,
  //         $_duration INTEGER
  //       )
  //     ''');
  //     AppLogger.info('Database created successfully at version $version');
  //   } catch (e, stackTrace) {
  //     AppLogger.error('Failed to create database tables: $e', stackTrace: stackTrace);
  //     rethrow;
  //   }
  // }
  //
  // Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
  //   try {
  //     // Add upgrade logic here when needed
  //     AppLogger.info('Database upgraded from version $oldVersion to $newVersion');
  //   } catch (e, stackTrace) {
  //     AppLogger.error('Failed to upgrade database: $e', stackTrace: stackTrace);
  //     rethrow;
  //   }
  // }

  String _encodeImages(List<String> images) {
    try {
      return jsonEncode(images);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to encode images: $e', stackTrace: stackTrace);
      return '[]';
    }
  }

  List<String> _decodeImages(String imagesJson) {
    if (imagesJson.isEmpty) return [];
    try {
      List<dynamic> decoded = jsonDecode(imagesJson);
      return decoded.map((e) => e.toString()).toList();
    } catch (e, stackTrace) {
      AppLogger.error('Failed to decode images: $e', stackTrace: stackTrace);
      return [];
    }
  }

  Future<int> insertTrails(TrailData trail) async {
    try{
    // final Map<String, dynamic> data = trail.toMap();
    // data[_images] = _encodeImages(trail.trailImages);
      final box = _trailBox ?? await Hive.openBox<TrailData>('trailBox');


      final resultKey = await box.add(trail);

      AppLogger.info('Trail inserted successfully: ${trail.trailName}');
          return  resultKey;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to insert trail: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<List<TrailData>> getTrails() async {
    try {
      final boxMaps = _trailBox ?? await Hive.openBox<TrailData>('trailBox');
      // return List.generate(maps.length, (i) {
      //   final Map<String, dynamic> data = Map<String, dynamic>.from(maps[i]);
      //   data[_images] = _decodeImages(maps[i][_images].toString());
      //   return TrailData.fromMap(data);
      // });
      return boxMaps.values.toList();
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get trails: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> updateTrail(String trailName, TrailData trail) async {
    try{
    final updateBox = _trailBox ?? await Hive.openBox<TrailData>('trailBox');
    int resultKey = 0;

    for (var i = 0; i < updateBox.length; i++) {
      final trail = updateBox.getAt(i);
      if (trail != null && trail.trailName == trailName) {

        resultKey = updateBox.keyAt(i);
      }
    }
    final result = await updateBox.put(resultKey, trail);


    // final box = await database;
    // try {
    //   return await box.transaction((txn) async {
    //     final Map<String, dynamic> data = trail.toMap();
    //     data[_images] = _encodeImages(trail.trailImages);
    //
    //     final result = await txn.update(
    //       _trailTableName,
    //       data,
    //       where: '$_name = ?',
    //       whereArgs: [trail.trailName],
    //     );

        AppLogger.info('Trail updated successfully: ${trail.trailName}');
        //return result;
      }
     catch (e, stackTrace) {
      AppLogger.error('Failed to update trail: $e', stackTrace: stackTrace);
      //rethrow;
    }
  }
  //
  // Future<int> deleteTrail(String name) async {
  //   final db = await database;
  //   try {
  //     return await db.transaction((txn) async {
  //       final result = await txn.delete(
  //         _trailTableName,
  //         where: '$_name = ?',
  //         whereArgs: [name],
  //       );
  //
  //       AppLogger.info('Trail deleted successfully: $name');
  //       return result;
  //     });
  //   } catch (e, stackTrace) {
  //     AppLogger.error('Failed to delete trail: $e', stackTrace: stackTrace);
  //     rethrow;
  //   }
  // }
  //
  Future<TrailData?> getTrailByName(String name) async {

    try {
      final trailbynameBox = _trailBox ?? await Hive.openBox<TrailData>('trailBox');


      for (var i = 0; i < trailbynameBox.length; i++) {
        final trail = trailbynameBox.getAt(i);
        if (trail != null && trail.trailName == name) {
              return trail;
        }
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get trail by name: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  // Future<bool> verifyConnection() async {
  //   try {
  //     final db = await database;
  //     await db.transaction((txn) async {
  //       await txn.insert(
  //         _trailTableName,
  //         {
  //           _name: 'Test Trail',
  //           _description: 'Test description',
  //           _difficulty: 'Easy',
  //           _notice: 'Test notice',
  //           _images: '[]',
  //           _date: DateTime.now().toIso8601String(),
  //           _location: 'Test Location',
  //           _participants: 10,
  //           _duration: 120,
  //         },
  //         conflictAlgorithm: ConflictAlgorithm.replace,
  //       );
  //
  //       final result = await txn.query(_trailTableName);
  //       if (result.isEmpty) {
  //         throw Exception('Database verification failed: no test data found');
  //       }
  //     });
  //
  //     AppLogger.info('Database connection verified successfully');
  //     return true;
  //   } catch (e, stackTrace) {
  //     AppLogger.error('Database verification failed: $e', stackTrace: stackTrace);
  //     return false;
  //   }
  // }

  // Future<void> close() async {
  //   try {
  //     if (_db != null) {
  //       await _db!.close();
  //       _db = null;
  //       AppLogger.info('Database closed successfully');
  //     }
  //   } catch (e, stackTrace) {
  //     AppLogger.error('Failed to close database: $e', stackTrace: stackTrace);
  //     rethrow;
  //   }
  // }
}