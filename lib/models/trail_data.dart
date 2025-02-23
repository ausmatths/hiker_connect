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
  });

  // Convert the TrailData to a map for insertion into the database
  // Map<String, dynamic> toMap() {
  //   return {
  //     'name': name,
  //     'description': description,
  //     'difficulty': difficulty,
  //     'notice': notice,
  //     'images': images.join(','),  // Store images as comma-separated paths
  //     'date': date.toIso8601String(),
  //     'location': location,
  //     'participants': participants,
  //     'duration': duration.inMinutes,  // Store the duration in minutes
  //   };
  // }
  //
  // // Create from Map for retrieval
  // factory TrailData.fromMap(Map<String, dynamic> map) {
  //   return TrailData(
  //     name: map['name'] ?? '',
  //     description: map['description'] ?? '',
  //     difficulty: map['difficulty'] ?? '',
  //     notice: map['notice'] ?? '',
  //     images: List<String>.from(map['images'] ?? []),
  //     date: DateTime.parse(map['date']),
  //     location: map['location'] ?? '',
  //     participants: map['participants'] ?? 0,
  //     duration: Duration(minutes: map['duration'] ?? 0),
  //   );
  // }
}