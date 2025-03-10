// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'photo_data.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PhotoDataAdapter extends TypeAdapter<PhotoData> {
  @override
  final int typeId = 3;

  @override
  PhotoData read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PhotoData(
      id: fields[0] as String,
      url: fields[1] as String,
      thumbnailUrl: fields[2] as String?,
      uploaderId: fields[3] as String,
      trailId: fields[4] as String?,
      eventId: fields[5] as String?,
      uploadDate: fields[6] as DateTime,
      caption: fields[7] as String?,
      localPath: fields[8] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, PhotoData obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.url)
      ..writeByte(2)
      ..write(obj.thumbnailUrl)
      ..writeByte(3)
      ..write(obj.uploaderId)
      ..writeByte(4)
      ..write(obj.trailId)
      ..writeByte(5)
      ..write(obj.eventId)
      ..writeByte(6)
      ..write(obj.uploadDate)
      ..writeByte(7)
      ..write(obj.caption)
      ..writeByte(8)
      ..write(obj.localPath);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PhotoDataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PhotoData _$PhotoDataFromJson(Map<String, dynamic> json) => PhotoData(
      id: json['id'] as String,
      url: json['url'] as String,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      uploaderId: json['uploaderId'] as String,
      trailId: json['trailId'] as String?,
      eventId: json['eventId'] as String?,
      uploadDate: DateTime.parse(json['uploadDate'] as String),
      caption: json['caption'] as String?,
      localPath: json['localPath'] as String?,
    );

Map<String, dynamic> _$PhotoDataToJson(PhotoData instance) => <String, dynamic>{
      'id': instance.id,
      'url': instance.url,
      'thumbnailUrl': instance.thumbnailUrl,
      'uploaderId': instance.uploaderId,
      'trailId': instance.trailId,
      'eventId': instance.eventId,
      'uploadDate': instance.uploadDate.toIso8601String(),
      'caption': instance.caption,
      'localPath': instance.localPath,
    };
