import 'package:json_annotation/json_annotation.dart';
import 'package:hive/hive.dart';

part 'photo_data.g.dart';

@JsonSerializable()
@HiveType(typeId: 3)
class PhotoData extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String url;

  @HiveField(2)
  final String? thumbnailUrl;

  @HiveField(3)
  final String uploaderId;

  @HiveField(4)
  final String? trailId;

  @HiveField(5)
  final String? eventId;

  @HiveField(6)
  final DateTime uploadDate;

  @HiveField(7)
  final String? caption;

  PhotoData({
    required this.id,
    required this.url,
    this.thumbnailUrl,
    required this.uploaderId,
    this.trailId,
    this.eventId,
    required this.uploadDate,
    this.caption,
  });

  // Add this copyWith method
  PhotoData copyWith({
    String? id,
    String? url,
    String? thumbnailUrl,
    String? uploaderId,
    String? trailId,
    String? eventId,
    DateTime? uploadDate,
    String? caption,
  }) {
    return PhotoData(
      id: id ?? this.id,
      url: url ?? this.url,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      uploaderId: uploaderId ?? this.uploaderId,
      trailId: trailId ?? this.trailId,
      eventId: eventId ?? this.eventId,
      uploadDate: uploadDate ?? this.uploadDate,
      caption: caption ?? this.caption,
    );
  }

  factory PhotoData.fromJson(Map<String, dynamic> json) => _$PhotoDataFromJson(json);

  Map<String, dynamic> toJson() => _$PhotoDataToJson(this);
}