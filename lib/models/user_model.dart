import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
part 'user_model.g.dart';


@HiveType(typeId: 1)
class UserLocation {

  @HiveField(0)
  final GeoPoint? geoPoint;

  @HiveField(1)
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


@HiveType(typeId: 2)
class EmergencyContact {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final String relationship;

  @HiveField(2)
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

@HiveType(typeId: 4)
class EventPreferences {
  @HiveField(0)
  final List<String> preferredCategories;

  @HiveField(1)
  final int? preferredDifficulty;

  @HiveField(2)
  final double? maxDistance;

  @HiveField(3)
  final bool notifyNewEvents;

  @HiveField(4)
  final bool notifyEventChanges;

  @HiveField(5)
  final bool notifyEventReminders;

  EventPreferences({
    this.preferredCategories = const [],
    this.preferredDifficulty,
    this.maxDistance,
    this.notifyNewEvents = true,
    this.notifyEventChanges = true,
    this.notifyEventReminders = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'preferredCategories': preferredCategories,
      'preferredDifficulty': preferredDifficulty,
      'maxDistance': maxDistance,
      'notifyNewEvents': notifyNewEvents,
      'notifyEventChanges': notifyEventChanges,
      'notifyEventReminders': notifyEventReminders,
    };
  }

  factory EventPreferences.fromMap(dynamic map) {
    if (map == null) return EventPreferences();
    final safeMap = _convertToStringKeyMap(map);
    return EventPreferences(
      preferredCategories: _safeGetStringList(safeMap, 'preferredCategories'),
      preferredDifficulty: _safeGetInt(safeMap, 'preferredDifficulty'),
      maxDistance: _safeGetDouble(safeMap, 'maxDistance'),
      notifyNewEvents: _safeGetBool(safeMap, 'notifyNewEvents', defaultValue: true),
      notifyEventChanges: _safeGetBool(safeMap, 'notifyEventChanges', defaultValue: true),
      notifyEventReminders: _safeGetBool(safeMap, 'notifyEventReminders', defaultValue: true),
    );
  }

  static List<String> _safeGetStringList(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value == null) return [];
    if (value is List) {
      return value.map((e) => e?.toString() ?? '').whereType<String>().toList();
    }
    return [];
  }

  static int? _safeGetInt(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }

  static double? _safeGetDouble(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value == null) return null;
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }

  static bool _safeGetBool(Map<String, dynamic> data, String key, {bool defaultValue = false}) {
    final value = data[key];
    if (value == null) return defaultValue;
    if (value is bool) return value;
    if (value is String) {
      return value.toLowerCase() == 'true';
    }
    return defaultValue;
  }
}

@HiveType(typeId: 3)
class UserModel {
  @HiveField(0)
  final String uid;

  @HiveField(1)
  final String email;

  @HiveField(2)
  final String displayName;

  @HiveField(3)
  final String photoUrl;

  @HiveField(4)
  final String? bio;

  @HiveField(5)
  final List<String> interests;

  @HiveField(6)
  final DateTime createdAt;

  @HiveField(7)
  final DateTime lastActive;

  @HiveField(8)
  final bool isEmailVerified;

  @HiveField(9)
  final List<String> following;

  @HiveField(10)
  final List<String> followers;

  @HiveField(11)
  final String? phoneNumber;

  @HiveField(12)
  final UserLocation? location;

  @HiveField(13)
  final List<EmergencyContact>? emergencyContacts;

  @HiveField(14)
  final String? bloodType;

  @HiveField(15)
  final List<String>? medicalConditions;

  @HiveField(16)
  final List<String>? medications;

  @HiveField(17)
  final String? insuranceInfo;

  @HiveField(18)
  final String? allergies;

  @HiveField(19)
  final DateTime? dateOfBirth;

  @HiveField(20)
  final String? gender;

  @HiveField(21)
  final double? height;

  @HiveField(22)
  final double? weight;

  @HiveField(23)
  final String? preferredLanguage;

  @HiveField(24)
  final Map<String, String>? socialLinks;

  @HiveField(25)
  final List<String> favoriteEvents;

  @HiveField(26)
  final List<String> registeredEvents;

  @HiveField(27)
  final EventPreferences eventPreferences;

  @HiveField(28)
  final Map<String, DateTime>? eventReminders;

  @HiveField(29)
  final Map<String, dynamic>? lastViewedFilters;

  @HiveField(30)
  final List<String> galleryImageUrls;

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
    this.galleryImageUrls = const [],
    this.favoriteEvents = const [],
    this.registeredEvents = const [],
    EventPreferences? eventPreferences,
    this.eventReminders,
    this.lastViewedFilters,
  }) : photoUrl = photoUrl ?? '',
        eventPreferences = eventPreferences ?? EventPreferences(); // Provide a default empty string

  // Create a copy of the user with some modified fields
  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoUrl,
    String? bio,
    List<String>? interests,
    DateTime? createdAt,
    DateTime? lastActive,
    bool? isEmailVerified,
    List<String>? following,
    List<String>? followers,
    String? phoneNumber,
    UserLocation? location,
    List<EmergencyContact>? emergencyContacts,
    String? bloodType,
    List<String>? medicalConditions,
    List<String>? medications,
    String? insuranceInfo,
    String? allergies,
    DateTime? dateOfBirth,
    String? gender,
    double? height,
    double? weight,
    String? preferredLanguage,
    Map<String, String>? socialLinks,
    List<String>? favoriteEvents,
    List<String>? registeredEvents,
    EventPreferences? eventPreferences,
    Map<String, DateTime>? eventReminders,
    Map<String, dynamic>? lastViewedFilters,
    List<String>? galleryImageUrls,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      bio: bio ?? this.bio,
      interests: interests ?? this.interests,
      createdAt: createdAt ?? this.createdAt,
      lastActive: lastActive ?? this.lastActive,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      following: following ?? this.following,
      followers: followers ?? this.followers,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      location: location ?? this.location,
      emergencyContacts: emergencyContacts ?? this.emergencyContacts,
      bloodType: bloodType ?? this.bloodType,
      medicalConditions: medicalConditions ?? this.medicalConditions,
      medications: medications ?? this.medications,
      insuranceInfo: insuranceInfo ?? this.insuranceInfo,
      allergies: allergies ?? this.allergies,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      socialLinks: socialLinks ?? this.socialLinks,
      favoriteEvents: favoriteEvents ?? this.favoriteEvents,
      registeredEvents: registeredEvents ?? this.registeredEvents,
      eventPreferences: eventPreferences ?? this.eventPreferences,
      eventReminders: eventReminders ?? this.eventReminders,
      lastViewedFilters: lastViewedFilters ?? this.lastViewedFilters,
      galleryImageUrls: galleryImageUrls ?? this.galleryImageUrls,
    );
  }

  // Helper methods for favorite events
  bool hasEventInFavorites(String eventId) {
    return favoriteEvents.contains(eventId);
  }

  UserModel addFavoriteEvent(String eventId) {
    if (favoriteEvents.contains(eventId)) {
      return this;
    }
    return copyWith(
      favoriteEvents: [...favoriteEvents, eventId],
    );
  }

  UserModel removeFavoriteEvent(String eventId) {
    if (!favoriteEvents.contains(eventId)) {
      return this;
    }
    return copyWith(
      favoriteEvents: favoriteEvents.where((id) => id != eventId).toList(),
    );
  }

  // Helper methods for registered events
  bool isRegisteredForEvent(String eventId) {
    return registeredEvents.contains(eventId);
  }

  UserModel registerForEvent(String eventId) {
    if (registeredEvents.contains(eventId)) {
      return this;
    }
    return copyWith(
      registeredEvents: [...registeredEvents, eventId],
    );
  }

  UserModel unregisterFromEvent(String eventId) {
    if (!registeredEvents.contains(eventId)) {
      return this;
    }
    return copyWith(
      registeredEvents: registeredEvents.where((id) => id != eventId).toList(),
    );
  }

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
      'favoriteEvents': favoriteEvents,
      'registeredEvents': registeredEvents,
      'eventPreferences': eventPreferences.toMap(),
      'eventReminders': eventReminders != null
          ? eventReminders!.map((key, value) => MapEntry(key, Timestamp.fromDate(value)))
          : null,
      'lastViewedFilters': lastViewedFilters,
      'galleryImageUrls': galleryImageUrls,
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
      favoriteEvents: _safeGetStringList(data, 'favoriteEvents'),
      registeredEvents: _safeGetStringList(data, 'registeredEvents'),
      eventPreferences: data['eventPreferences'] != null
          ? EventPreferences.fromMap(data['eventPreferences'])
          : null,
      eventReminders: _safeGetEventReminders(data, 'eventReminders'),
      lastViewedFilters: _safeGetMap(data, 'lastViewedFilters'),
      galleryImageUrls: _safeGetStringList(data, 'galleryImageUrls'),

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

  static Map<String, DateTime>? _safeGetEventReminders(Map<String, dynamic> data, String key) {
    final reminders = data[key];
    if (reminders == null) return null;

    try {
      if (reminders is Map) {
        final result = <String, DateTime>{};
        reminders.forEach((eventId, timestamp) {
          if (eventId != null) {
            if (timestamp is Timestamp) {
              result[eventId.toString()] = timestamp.toDate();
            } else if (timestamp is DateTime) {
              result[eventId.toString()] = timestamp;
            }
          }
        });
        return result;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Map<String, dynamic>? _safeGetMap(Map<String, dynamic> data, String key) {
    final map = data[key];
    if (map == null) return null;

    try {
      if (map is Map) {
        return map.map((key, value) => MapEntry(key.toString(), value));
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}