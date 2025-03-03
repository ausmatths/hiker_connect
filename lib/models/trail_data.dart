import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
part 'trail_data.g.dart';

@HiveType(typeId: 0)
class TrailData {
  @HiveField(0)
  final int trailId;
  @HiveField(1)
  final String trailName;
  @HiveField(2)
  final String trailDescription;
  @HiveField(3)
  final String trailDifficulty;
  @HiveField(4)
  final String trailNotice;
  @HiveField(5)
  final List<String> trailImages;
  @HiveField(6)
  final DateTime trailDate;
  @HiveField(7)
  final String trailLocation;
  @HiveField(8)
  final int trailParticipantNumber;
  @HiveField(9)
  final Duration trailDuration;
  @HiveField(10)
  final String trailType;

  TrailData({
    required this.trailId,
    required this.trailName,
    required this.trailDescription,
    required this.trailDifficulty,
    required this.trailNotice,
    required this.trailImages,
    required this.trailDate,
    required this.trailLocation,
    required this.trailParticipantNumber,
    required this.trailDuration,
    required this.trailType,
  });

  Map<String, dynamic> toMap() {
    return {
      'trailId': trailId,
      'trailName': trailName,
      'trailDescription': trailDescription,
      'trailDifficulty': trailDifficulty,
      'trailNotice': trailNotice,
      'trailImages': trailImages.isEmpty ? [] : trailImages,
      'trailDate': trailDate.toIso8601String(),
      'trailLocation': trailLocation,
      'trailParticipantNumber': trailParticipantNumber,
      'trailDuration': trailDuration.inMinutes,
      'trailType': trailType,
    };
  }

  // Robust fromMap method with extensive error checking
  factory TrailData.fromMap(Map<String, dynamic> map) {
    // Safe integer conversion
    int safeInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    // Safe string conversion
    String safeString(dynamic value) {
      if (value == null) return '';
      return value.toString().trim();
    }

    // Safe list conversion
    List<String> safeStringList(dynamic value) {
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

    // Safe date parsing
    DateTime safeParseDate(dynamic value) {
      try {
        if (value == null) return DateTime.now();
        if (value is Timestamp) return value.toDate();
        if (value is String) return DateTime.parse(value);
        return DateTime.now();
      } catch (e) {
        print('Error parsing date: $value, Error: $e');
        return DateTime.now();
      }
    }

    // Safe duration parsing
    Duration safeParseDuration(dynamic value) {
      try {
        if (value == null) return Duration.zero;
        if (value is int) return Duration(minutes: value);
        if (value is num) return Duration(minutes: value.toInt());
        if (value is String) {
          final intValue = int.tryParse(value);
          return intValue != null
              ? Duration(minutes: intValue)
              : Duration.zero;
        }
        return Duration.zero;
      } catch (e) {
        print('Error parsing duration: $value, Error: $e');
        return Duration.zero;
      }
    }

    // Additional description handling
    String getDescription(Map<String, dynamic> map) {
      // Prioritize 'trailDescription', fallback to 'description'
      return safeString(map['trailDescription'] ?? map['description']);
    }

    // Get trail type, default to 'Trail' if not specified
    String getTrailType(Map<String, dynamic> map) {
      final type = safeString(map['trailType']);
      return type.isEmpty ? 'Trail' : type;
    }

    try {
      return TrailData(
        trailId: safeInt(map['trailId']),
        trailName: safeString(map['trailName']),
        trailDescription: getDescription(map),
        trailDifficulty: safeString(map['trailDifficulty']),
        trailNotice: safeString(map['trailNotice']),
        trailImages: safeStringList(map['trailImages']),
        trailDate: safeParseDate(map['trailDate']),
        trailLocation: safeString(map['trailLocation']),
        trailParticipantNumber: safeInt(map['trailParticipantNumber']),
        trailDuration: safeParseDuration(map['trailDuration']),
        trailType: getTrailType(map),
      );
    } catch (e) {
      print('Error creating TrailData: $e');
      print('Input map: $map');
      rethrow;
    }
  }
}