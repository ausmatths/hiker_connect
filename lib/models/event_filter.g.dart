// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_filter.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class EventFilterAdapter extends TypeAdapter<EventFilter> {
  @override
  final int typeId = 7;

  @override
  EventFilter read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return EventFilter(
      searchQuery: fields[11] as String?,
      startDate: fields[0] as DateTime?,
      endDate: fields[1] as DateTime?,
      categories: (fields[2] as List).cast<String>(),
      minDifficulty: fields[3] as int?,
      maxDifficulty: fields[4] as int?,
      location: fields[5] as String?,
      maxDistance: fields[6] as double?,
      userLatitude: fields[7] as double?,
      userLongitude: fields[8] as double?,
      favoritesOnly: fields[9] as bool,
      showOnlyFavorites: fields[10] as bool,
      category: fields[12] as String?,
      difficultyLevel: fields[13] as int?,
      locationQuery: fields[14] as String?,
      includePastEvents: fields[15] as bool,
      includeCurrentEvents: fields[16] as bool,
      includeFutureEvents: fields[17] as bool,
      radiusInKm: fields[18] as double?,
    );
  }

  @override
  void write(BinaryWriter writer, EventFilter obj) {
    writer
      ..writeByte(19)
      ..writeByte(0)
      ..write(obj.startDate)
      ..writeByte(1)
      ..write(obj.endDate)
      ..writeByte(2)
      ..write(obj.categories)
      ..writeByte(3)
      ..write(obj.minDifficulty)
      ..writeByte(4)
      ..write(obj.maxDifficulty)
      ..writeByte(5)
      ..write(obj.location)
      ..writeByte(6)
      ..write(obj.maxDistance)
      ..writeByte(7)
      ..write(obj.userLatitude)
      ..writeByte(8)
      ..write(obj.userLongitude)
      ..writeByte(9)
      ..write(obj.favoritesOnly)
      ..writeByte(10)
      ..write(obj.showOnlyFavorites)
      ..writeByte(11)
      ..write(obj.searchQuery)
      ..writeByte(12)
      ..write(obj.category)
      ..writeByte(13)
      ..write(obj.difficultyLevel)
      ..writeByte(14)
      ..write(obj.locationQuery)
      ..writeByte(15)
      ..write(obj.includePastEvents)
      ..writeByte(16)
      ..write(obj.includeCurrentEvents)
      ..writeByte(17)
      ..write(obj.includeFutureEvents)
      ..writeByte(18)
      ..write(obj.radiusInKm);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventFilterAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
