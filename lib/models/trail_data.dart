import 'package:hive/hive.dart';
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
      'description': trailDescription,
      'trailDifficulty': trailDifficulty,
      'trailNotice': trailNotice,
      'trailImages': trailImages.join(','),
      'trailDate': trailDate.toIso8601String(),
      'trailLocation': trailLocation,
      'trailParticipantNumber': trailParticipantNumber,
      'trailDuration': trailDuration.inMinutes,
      'trailType': trailType,
    };
  }

  // Create from Map for retrieval
  factory TrailData.fromMap(Map<String, dynamic> map) {
    return TrailData(
      trailId: map['trailId'] ?? 0,
      trailName: map['trailName'] ?? '',
      trailDescription: map['trailDescription'] ?? '',
      trailDifficulty: map['trailDifficulty'] ?? '',
      trailNotice: map['trailNotice'] ?? '',
      trailImages: List<String>.from(map['trailImages'] ?? []),
      trailDate: DateTime.parse(map['trailDate']),
      trailLocation: map['trailLocation'] ?? '',
      trailParticipantNumber: map['trailParticipantNumber'] ?? 0,
      trailDuration: Duration(minutes: map['trailDuration'] ?? 0),
      trailType: map['trailType'] ?? '',
    );
  }
}