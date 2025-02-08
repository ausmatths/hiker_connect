import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:hiker_connect/models/trail_data.dart';

class DatabaseService {
  static Database? _db;
  static final DatabaseService instance = DatabaseService._constructor();

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

  // Getter for the database
  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await getDatabase();
    return _db!;
  }

  // Function to initialize the database
  Future<Database> getDatabase() async {
    final dbDirpath = await getDatabasesPath();
    final dbpath = join(dbDirpath, 'trail.db');

    // Open or create the database
    final database = await openDatabase(
      dbpath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_trailTableName (
            $_name TEXT,
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
      },
    );
    return database;
  }

  // Utility method to encode images list to JSON string
  String _encodeImages(List<String> images) {
    return jsonEncode(images);
  }

  // Utility method to decode JSON string back to images list
  List<String> _decodeImages(String imagesJson) {
    if (imagesJson.isEmpty) return [];
    try {
      List<dynamic> decoded = jsonDecode(imagesJson);
      return decoded.map((e) => e.toString()).toList();
    } catch (e) {
      print('Error decoding images: $e');
      return [];
    }
  }

  // Insert event data
  Future<int> insertTrails(TrailData event) async {
    final db = await database;
    final Map<String, dynamic> data = event.toMap();
    // Encode images before saving to database
    data[_images] = _encodeImages(event.images);

    return await db.insert(
      _trailTableName,
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Get all events
  Future<List<TrailData>> getTrails() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(_trailTableName);

    // Convert the List<Map<String, dynamic>> into a List<TrailData>
    return List.generate(maps.length, (i) {
      // Decode images before creating TrailData object
      final Map<String, dynamic> data = Map<String, dynamic>.from(maps[i]);
      data[_images] = _decodeImages(maps[i][_images].toString());
      return TrailData.fromMap(data);
    });
  }

  // Update an existing trail
  Future<int> updateTrail(TrailData event) async {
    final db = await database;
    final Map<String, dynamic> data = event.toMap();
    data[_images] = _encodeImages(event.images);

    return await db.update(
      _trailTableName,
      data,
      where: '$_name = ?',
      whereArgs: [event.name],
    );
  }

  // Delete a trail
  Future<int> deleteTrail(String name) async {
    final db = await database;
    return await db.delete(
      _trailTableName,
      where: '$_name = ?',
      whereArgs: [name],
    );
  }

  // Get a single trail by name
  Future<TrailData?> getTrailByName(String name) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _trailTableName,
      where: '$_name = ?',
      whereArgs: [name],
    );

    if (maps.isEmpty) return null;

    final Map<String, dynamic> data = Map<String, dynamic>.from(maps.first);
    data[_images] = _decodeImages(maps.first[_images].toString());
    return TrailData.fromMap(data);
  }

  // Verify database connection
  Future<bool> verifyConnection() async {
    try {
      Database db = await database;

      // Insert a dummy record
      await db.insert(
        _trailTableName,
        {
          _name: 'Test Event',
          _description: 'Test description',
          _difficulty: 'Medium',
          _notice: 'Test notice',
          _images: '[]',
          _date: DateTime.now().toIso8601String(),
          _location: 'Test Location',
          _participants: 10,
          _duration: 120,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Retrieve the inserted record
      List<Map<String, dynamic>> result = await db.query(_trailTableName);
      if (result.isNotEmpty) {
        print('Database Connection Verified!');
        return true;
      } else {
        print('Database is empty or error occurred');
        return false;
      }
    } catch (e) {
      print('Error verifying database connection: $e');
      return false;
    }
  }

  // Close the database
  Future<void> close() async {
    final db = await database;
    await db.close();
    _db = null;
  }
}