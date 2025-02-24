// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_data.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class EventDataAdapter extends TypeAdapter<EventData> {
  @override
  final int typeId = 0;

  @override
  EventData read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return EventData(
      eventId: fields[0] as int,
      eventName: fields[1] as String,
      eventDescription: fields[2] as String,
      eventDate: fields[6] as DateTime,
      eventLocation: fields[7] as String,
      evenParticipantNumber: fields[8] as int,
      eventDuration: fields[9] as Duration,
    );
  }

  @override
  void write(BinaryWriter writer, EventData obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.eventId)
      ..writeByte(1)
      ..write(obj.eventName)
      ..writeByte(2)
      ..write(obj.eventDescription)
      ..writeByte(6)
      ..write(obj.eventDate)
      ..writeByte(7)
      ..write(obj.eventLocation)
      ..writeByte(8)
      ..write(obj.evenParticipantNumber)
      ..writeByte(9)
      ..write(obj.eventDuration);
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
