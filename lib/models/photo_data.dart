import 'package:json_annotation/json_annotation.dart';
import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  @HiveField(8)
  final String? localPath;

  PhotoData({
    required this.id,
    required this.url,
    this.thumbnailUrl,
    required this.uploaderId,
    this.trailId,
    this.eventId,
    required this.uploadDate,
    this.caption,
    this.localPath,
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
    String? localPath,
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
      localPath: localPath ?? this.localPath,
    );
  }

  factory PhotoData.fromJson(Map<String, dynamic> json) => _$PhotoDataFromJson(json);

  Map<String, dynamic> toJson() => _$PhotoDataToJson(this);

  // Create from Firestore document
  factory PhotoData.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PhotoData(
      id: doc.id,
      url: data['url'] ?? '',
      thumbnailUrl: data['thumbnailUrl'],
      uploaderId: data['uploaderId'] ?? '',
      trailId: data['trailId'],
      eventId: data['eventId'],
      uploadDate: (data['uploadDate'] as Timestamp).toDate(),
      caption: data['caption'],
      localPath: data['localPath'],
    );
  }

  // Convert to Firestore data
  Map<String, dynamic> toFirestore() {
    return {
      'url': url,
      'thumbnailUrl': thumbnailUrl,
      'uploaderId': uploaderId,
      'trailId': trailId,
      'eventId': eventId,
      'uploadDate': Timestamp.fromDate(uploadDate),
      'caption': caption,
      'localPath': localPath,
    };
  }
}