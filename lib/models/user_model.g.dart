// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserLocationAdapter extends TypeAdapter<UserLocation> {
  @override
  final int typeId = 1;

  @override
  UserLocation read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserLocation(
      geoPoint: fields[0] as GeoPoint?,
      address: fields[1] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, UserLocation obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.geoPoint)
      ..writeByte(1)
      ..write(obj.address);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserLocationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class EmergencyContactAdapter extends TypeAdapter<EmergencyContact> {
  @override
  final int typeId = 2;

  @override
  EmergencyContact read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return EmergencyContact(
      name: fields[0] as String,
      relationship: fields[1] as String,
      phoneNumber: fields[2] as String,
    );
  }

  @override
  void write(BinaryWriter writer, EmergencyContact obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.relationship)
      ..writeByte(2)
      ..write(obj.phoneNumber);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EmergencyContactAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class UserModelAdapter extends TypeAdapter<UserModel> {
  @override
  final int typeId = 3;

  @override
  UserModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserModel(
      uid: fields[0] as String,
      email: fields[1] as String,
      displayName: fields[2] as String,
      photoUrl: fields[3] as String?,
      bio: fields[4] as String?,
      interests: (fields[5] as List).cast<String>(),
      createdAt: fields[6] as DateTime,
      lastActive: fields[7] as DateTime,
      isEmailVerified: fields[8] as bool,
      following: (fields[9] as List).cast<String>(),
      followers: (fields[10] as List).cast<String>(),
      phoneNumber: fields[11] as String?,
      location: fields[12] as UserLocation?,
      emergencyContacts: (fields[13] as List?)?.cast<EmergencyContact>(),
      bloodType: fields[14] as String?,
      medicalConditions: (fields[15] as List?)?.cast<String>(),
      medications: (fields[16] as List?)?.cast<String>(),
      insuranceInfo: fields[17] as String?,
      allergies: fields[18] as String?,
      dateOfBirth: fields[19] as DateTime?,
      gender: fields[20] as String?,
      height: fields[21] as double?,
      weight: fields[22] as double?,
      preferredLanguage: fields[23] as String?,
      socialLinks: (fields[24] as Map?)?.cast<String, String>(),
    );
  }

  @override
  void write(BinaryWriter writer, UserModel obj) {
    writer
      ..writeByte(25)
      ..writeByte(0)
      ..write(obj.uid)
      ..writeByte(1)
      ..write(obj.email)
      ..writeByte(2)
      ..write(obj.displayName)
      ..writeByte(3)
      ..write(obj.photoUrl)
      ..writeByte(4)
      ..write(obj.bio)
      ..writeByte(5)
      ..write(obj.interests)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.lastActive)
      ..writeByte(8)
      ..write(obj.isEmailVerified)
      ..writeByte(9)
      ..write(obj.following)
      ..writeByte(10)
      ..write(obj.followers)
      ..writeByte(11)
      ..write(obj.phoneNumber)
      ..writeByte(12)
      ..write(obj.location)
      ..writeByte(13)
      ..write(obj.emergencyContacts)
      ..writeByte(14)
      ..write(obj.bloodType)
      ..writeByte(15)
      ..write(obj.medicalConditions)
      ..writeByte(16)
      ..write(obj.medications)
      ..writeByte(17)
      ..write(obj.insuranceInfo)
      ..writeByte(18)
      ..write(obj.allergies)
      ..writeByte(19)
      ..write(obj.dateOfBirth)
      ..writeByte(20)
      ..write(obj.gender)
      ..writeByte(21)
      ..write(obj.height)
      ..writeByte(22)
      ..write(obj.weight)
      ..writeByte(23)
      ..write(obj.preferredLanguage)
      ..writeByte(24)
      ..write(obj.socialLinks);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
