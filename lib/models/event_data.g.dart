// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_data.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class EventDataAdapter extends TypeAdapter<EventData> {
  @override
  final int typeId = 4;

  @override
  EventData read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return EventData(
      id: fields[0] as String,
      title: fields[1] as String,
      description: fields[2] as String?,
      startDate: fields[3] as DateTime?,
      location: fields[4] as String?,
      participantLimit: fields[5] as int?,
      duration: fields[6] as Duration?,
      endDate: fields[7] as DateTime?,
      imageUrl: fields[8] as String?,
      organizer: fields[9] as String?,
      url: fields[10] as String?,
      isFree: fields[11] as bool?,
      price: fields[12] as String?,
      capacity: fields[13] as int?,
      status: fields[14] as String?,
      venueId: fields[15] as String?,
      organizerId: fields[16] as String?,
      eventbriteId: fields[17] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, EventData obj) {
    writer
      ..writeByte(18)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.startDate)
      ..writeByte(4)
      ..write(obj.location)
      ..writeByte(5)
      ..write(obj.participantLimit)
      ..writeByte(6)
      ..write(obj.duration)
      ..writeByte(7)
      ..write(obj.endDate)
      ..writeByte(8)
      ..write(obj.imageUrl)
      ..writeByte(9)
      ..write(obj.organizer)
      ..writeByte(10)
      ..write(obj.url)
      ..writeByte(11)
      ..write(obj.isFree)
      ..writeByte(12)
      ..write(obj.price)
      ..writeByte(13)
      ..write(obj.capacity)
      ..writeByte(14)
      ..write(obj.status)
      ..writeByte(15)
      ..write(obj.venueId)
      ..writeByte(16)
      ..write(obj.organizerId)
      ..writeByte(17)
      ..write(obj.eventbriteId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventDataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
