// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trail_data.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TrailDataAdapter extends TypeAdapter<TrailData> {
  @override
  final int typeId = 0;

  @override
  TrailData read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TrailData(
      trailId: fields[0] as int,
      trailName: fields[1] as String,
      trailDescription: fields[2] as String,
      trailDifficulty: fields[3] as String,
      trailNotice: fields[4] as String,
      trailImages: (fields[5] as List).cast<String>(),
      trailDate: fields[6] as DateTime,
      trailLocation: fields[7] as String,
      trailParticipantNumber: fields[8] as int,
      trailDuration: fields[9] as Duration,
      trailType: fields[10] as String,
    );
  }

  @override
  void write(BinaryWriter writer, TrailData obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.trailId)
      ..writeByte(1)
      ..write(obj.trailName)
      ..writeByte(2)
      ..write(obj.trailDescription)
      ..writeByte(3)
      ..write(obj.trailDifficulty)
      ..writeByte(4)
      ..write(obj.trailNotice)
      ..writeByte(5)
      ..write(obj.trailImages)
      ..writeByte(6)
      ..write(obj.trailDate)
      ..writeByte(7)
      ..write(obj.trailLocation)
      ..writeByte(8)
      ..write(obj.trailParticipantNumber)
      ..writeByte(9)
      ..write(obj.trailDuration)
      ..writeByte(10)
      ..write(obj.trailType);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TrailDataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
