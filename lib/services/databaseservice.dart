import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:hiker_connect/models/trail_data.dart';
import 'package:hiker_connect/utils/logger.dart';

class DatabaseService {
  static Database? _db;
  static final DatabaseService instance = DatabaseService._constructor();

  static const int _currentVersion = 1;

  final String _trailTableName = 'trails';
  final String _name = 'name';
  final String _description = 'description';
  final String _difficulty = 'difficulty';
  final String _notice = 'notice';
  final String _images = 'images';
  final String _date = 'date';
  final String _location = 'location';
  final String _participants = 'participants';
  final String _duration = 'duration';

  DatabaseService._constructor();

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    try {
      final dbDirpath = await getDatabasesPath();
      final dbpath = join(dbDirpath, 'trail.db');

      return await openDatabase(
        dbpath,
        version: _currentVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
        onDowngrade: onDatabaseDowngradeDelete,
      );
    } catch (e, stackTrace) {
      AppLogger.error('Failed to initialize database: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    try {
      await db.execute('''
        CREATE TABLE $_trailTableName (
          $_name TEXT PRIMARY KEY,
          $_description TEXT,
          $_difficulty TEXT,
          $_notice TEXT,
          $_images TEXT,
          $_date TEXT,
          $_location TEXT,
          $_participants INTEGER,
          $_duration INTEGER
        )
      ''');
      AppLogger.info('Database created successfully at version $version');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to create database tables: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    try {
      // Add upgrade logic here when needed
      AppLogger.info('Database upgraded from version $oldVersion to $newVersion');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to upgrade database: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

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
    final db = await database;
    try {
      return await db.transaction((txn) async {
        final Map<String, dynamic> data = trail.toMap();
        data[_images] = _encodeImages(trail.images);

        final result = await txn.insert(
          _trailTableName,
          data,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        AppLogger.info('Trail inserted successfully: ${trail.name}');
        return result;
      });
    } catch (e, stackTrace) {
      AppLogger.error('Failed to insert trail: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<List<TrailData>> getTrails() async {
    final db = await database;
    try {
      final List<Map<String, dynamic>> maps = await db.query(_trailTableName);
      return List.generate(maps.length, (i) {
        final Map<String, dynamic> data = Map<String, dynamic>.from(maps[i]);
        data[_images] = _decodeImages(maps[i][_images].toString());
        return TrailData.fromMap(data);
      });
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get trails: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<int> updateTrail(TrailData trail) async {
    final db = await database;
    try {
      return await db.transaction((txn) async {
        final Map<String, dynamic> data = trail.toMap();
        data[_images] = _encodeImages(trail.images);

        final result = await txn.update(
          _trailTableName,
          data,
          where: '$_name = ?',
          whereArgs: [trail.name],
        );

        AppLogger.info('Trail updated successfully: ${trail.name}');
        return result;
      });
    } catch (e, stackTrace) {
      AppLogger.error('Failed to update trail: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<int> deleteTrail(String name) async {
    final db = await database;
    try {
      return await db.transaction((txn) async {
        final result = await txn.delete(
          _trailTableName,
          where: '$_name = ?',
          whereArgs: [name],
        );

        AppLogger.info('Trail deleted successfully: $name');
        return result;
      });
    } catch (e, stackTrace) {
      AppLogger.error('Failed to delete trail: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<TrailData?> getTrailByName(String name) async {
    final db = await database;
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        _trailTableName,
        where: '$_name = ?',
        whereArgs: [name],
      );

      if (maps.isEmpty) return null;

      final Map<String, dynamic> data = Map<String, dynamic>.from(maps.first);
      data[_images] = _decodeImages(maps.first[_images].toString());
      return TrailData.fromMap(data);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get trail by name: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<bool> verifyConnection() async {
    try {
      final db = await database;
      await db.transaction((txn) async {
        await txn.insert(
          _trailTableName,
          {
            _name: 'Test Trail',
            _description: 'Test description',
            _difficulty: 'Easy',
            _notice: 'Test notice',
            _images: '[]',
            _date: DateTime.now().toIso8601String(),
            _location: 'Test Location',
            _participants: 10,
            _duration: 120,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        final result = await txn.query(_trailTableName);
        if (result.isEmpty) {
          throw Exception('Database verification failed: no test data found');
        }
      });

      AppLogger.info('Database connection verified successfully');
      return true;
    } catch (e, stackTrace) {
      AppLogger.error('Database verification failed: $e', stackTrace: stackTrace);
      return false;
    }
  }

  Future<void> close() async {
    try {
      if (_db != null) {
        await _db!.close();
        _db = null;
        AppLogger.info('Database closed successfully');
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to close database: $e', stackTrace: stackTrace);
      rethrow;
    }
  }
}