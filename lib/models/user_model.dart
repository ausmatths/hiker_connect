import 'package:cloud_firestore/cloud_firestore.dart';

class UserLocation {
  final GeoPoint? geoPoint;
  final String? address;

  UserLocation({this.geoPoint, this.address});

  Map<String, dynamic> toMap() {
    return {
      'geoPoint': geoPoint,
      'address': address,
    };
  }

  factory UserLocation.fromMap(dynamic map) {
    if (map == null) return UserLocation();
    final safeMap = _convertToStringKeyMap(map);
    return UserLocation(
      geoPoint: safeMap['geoPoint'] as GeoPoint?,
      address: safeMap['address'] as String?,
    );
  }
}

class EmergencyContact {
  final String name;
  final String relationship;
  final String phoneNumber;

  EmergencyContact({
    required this.name,
    required this.relationship,
    required this.phoneNumber,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'relationship': relationship,
      'phoneNumber': phoneNumber,
    };
  }

  factory EmergencyContact.fromMap(dynamic map) {
    final safeMap = _convertToStringKeyMap(map);
    return EmergencyContact(
      name: (safeMap['name'] as String?) ?? '',
      relationship: (safeMap['relationship'] as String?) ?? '',
      phoneNumber: (safeMap['phoneNumber'] as String?) ?? '',
    );
  }
}

// Helper function to convert dynamic maps to Map<String, dynamic>
Map<String, dynamic> _convertToStringKeyMap(dynamic map) {
  if (map is Map<String, dynamic>) return map;
  if (map is Map) {
    return map.map((key, value) => MapEntry(key.toString(), value));
  }
  return {};
}

class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String photoUrl; // Changed to non-nullable
  final String? bio;
  final List<String> interests;
  final DateTime createdAt;
  final DateTime lastActive;
  final bool isEmailVerified;
  final List<String> following;
  final List<String> followers;
  final String? phoneNumber;
  final UserLocation? location;
  final List<EmergencyContact>? emergencyContacts;
  final String? bloodType;
  final List<String>? medicalConditions;
  final List<String>? medications;
  final String? insuranceInfo;
  final String? allergies;
  final DateTime? dateOfBirth;
  final String? gender;
  final double? height;
  final double? weight;
  final String? preferredLanguage;
  final Map<String, String>? socialLinks;

  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    String? photoUrl,
    this.bio,
    this.interests = const [],
    required this.createdAt,
    required this.lastActive,
    this.isEmailVerified = false,
    this.following = const [],
    this.followers = const [],
    this.phoneNumber,
    this.location,
    this.emergencyContacts,
    this.bloodType,
    this.medicalConditions,
    this.medications,
    this.insuranceInfo,
    this.allergies,
    this.dateOfBirth,
    this.gender,
    this.height,
    this.weight,
    this.preferredLanguage,
    this.socialLinks,
  }) : photoUrl = photoUrl ?? ''; // Provide a default empty string

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl.isEmpty ? null : photoUrl, // Only store non-empty photoUrl
      'bio': bio,
      'interests': interests,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastActive': Timestamp.fromDate(lastActive),
      'isEmailVerified': isEmailVerified,
      'following': following,
      'followers': followers,
      'phoneNumber': phoneNumber,
      'location': location?.toMap(),
      'emergencyContacts': emergencyContacts?.map((e) => e.toMap()).toList(),
      'bloodType': bloodType,
      'medicalConditions': medicalConditions,
      'medications': medications,
      'insuranceInfo': insuranceInfo,
      'allergies': allergies,
      'dateOfBirth': dateOfBirth != null ? Timestamp.fromDate(dateOfBirth!) : null,
      'gender': gender,
      'height': height,
      'weight': weight,
      'preferredLanguage': preferredLanguage,
      'socialLinks': socialLinks,
    };
  }

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    // Handle both Map<String, dynamic> and dynamic data
    final rawData = doc.data();
    final data = _convertToStringKeyMap(rawData);

    return UserModel(
      uid: doc.id,
      email: _safeGetString(data, 'email'),
      displayName: _safeGetString(data, 'displayName', defaultValue: 'User'),
      photoUrl: _safeGetString(data, 'photoUrl'), // No default value for photoUrl
      bio: _safeGetString(data, 'bio'),
      interests: _safeGetStringList(data, 'interests'),
      createdAt: _safeGetTimestamp(data, 'createdAt'),
      lastActive: _safeGetTimestamp(data, 'lastActive'),
      isEmailVerified: _safeGetBool(data, 'isEmailVerified'),
      following: _safeGetStringList(data, 'following'),
      followers: _safeGetStringList(data, 'followers'),
      phoneNumber: _safeGetString(data, 'phoneNumber'),
      location: data['location'] != null
          ? UserLocation.fromMap(data['location'])
          : null,
      emergencyContacts: _safeGetEmergencyContacts(data, 'emergencyContacts'),
      bloodType: _safeGetString(data, 'bloodType'),
      medicalConditions: _safeGetStringList(data, 'medicalConditions'),
      medications: _safeGetStringList(data, 'medications'),
      insuranceInfo: _safeGetString(data, 'insuranceInfo'),
      allergies: _safeGetString(data, 'allergies'),
      dateOfBirth: _safeGetTimestamp(data, 'dateOfBirth'),
      gender: _safeGetString(data, 'gender'),
      height: _safeGetDouble(data, 'height'),
      weight: _safeGetDouble(data, 'weight'),
      preferredLanguage: _safeGetString(data, 'preferredLanguage'),
      socialLinks: _safeGetSocialLinks(data, 'socialLinks'),
    );
  }

  // Safe type conversion helpers
  static String _safeGetString(Map<String, dynamic> data, String key, {String defaultValue = ''}) {
    return (data[key] as String?) ?? defaultValue;
  }

  static List<String> _safeGetStringList(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value == null) return [];
    if (value is List) {
      return value.map((e) => e?.toString() ?? '').whereType<String>().toList();
    }
    return [];
  }

  static DateTime _safeGetTimestamp(Map<String, dynamic> data, String key) {
    final timestamp = data[key];
    if (timestamp == null) return DateTime.now();
    return (timestamp is Timestamp) ? timestamp.toDate() : DateTime.now();
  }

  static bool _safeGetBool(Map<String, dynamic> data, String key) {
    return (data[key] as bool?) ?? false;
  }

  static double? _safeGetDouble(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value == null) return null;
    return (value is num) ? value.toDouble() : null;
  }

  static List<EmergencyContact>? _safeGetEmergencyContacts(Map<String, dynamic> data, String key) {
    final contacts = data[key];
    if (contacts == null) return null;

    try {
      if (contacts is List) {
        return contacts
            .map((contact) => EmergencyContact.fromMap(contact))
            .whereType<EmergencyContact>()
            .toList();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Map<String, String>? _safeGetSocialLinks(Map<String, dynamic> data, String key) {
    final links = data[key];
    if (links == null) return null;

    try {
      if (links is Map) {
        return links.map((key, value) =>
            MapEntry(key.toString(), value?.toString() ?? '')
        );
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}