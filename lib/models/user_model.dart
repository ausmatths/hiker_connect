import 'package:cloud_firestore/cloud_firestore.dart';

class EmergencyContact {
  final String name;
  final String relationship;
  final String phoneNumber;

  EmergencyContact({
    required this.name,
    required this.relationship,
    required this.phoneNumber,
  });

  Map<String, dynamic> toMap() => {
    'name': name,
    'relationship': relationship,
    'phoneNumber': phoneNumber,
  };

  factory EmergencyContact.fromMap(Map<String, dynamic> map) => EmergencyContact(
    name: map['name'] ?? '',
    relationship: map['relationship'] ?? '',
    phoneNumber: map['phoneNumber'] ?? '',
  );
}

class UserLocation {
  final GeoPoint geoPoint;
  final String address;

  UserLocation({
    required this.geoPoint,
    required this.address,
  });

  Map<String, dynamic> toMap() => {
    'geoPoint': geoPoint,
    'address': address,
  };

  factory UserLocation.fromMap(Map<String, dynamic> map) => UserLocation(
    geoPoint: map['geoPoint'] as GeoPoint,
    address: map['address'] ?? '',
  );
}

class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;
  final String? bio;
  final List<String> interests;
  final DateTime createdAt;
  final DateTime lastActive;
  final bool isEmailVerified;
  final List<String> following;
  final List<String> followers;

  // New fields
  final String? phoneNumber;
  final UserLocation? location;
  final List<EmergencyContact> emergencyContacts;
  final String? bloodType;
  final List<String> medicalConditions;
  final List<String> medications;
  final String? insuranceInfo;
  final String? allergies;
  final DateTime? dateOfBirth;
  final String? gender;
  final double? height; // in cm
  final double? weight; // in kg
  final String? preferredLanguage;
  final Map<String, String>? socialLinks; // platform -> url

  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
    this.bio,
    this.interests = const [],
    required this.createdAt,
    required this.lastActive,
    this.isEmailVerified = false,
    this.following = const [],
    this.followers = const [],
    this.phoneNumber,
    this.location,
    this.emergencyContacts = const [],
    this.bloodType,
    this.medicalConditions = const [],
    this.medications = const [],
    this.insuranceInfo,
    this.allergies,
    this.dateOfBirth,
    this.gender,
    this.height,
    this.weight,
    this.preferredLanguage,
    this.socialLinks,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      photoUrl: data['photoUrl'],
      bio: data['bio'],
      interests: List<String>.from(data['interests'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lastActive: (data['lastActive'] as Timestamp).toDate(),
      isEmailVerified: data['isEmailVerified'] ?? false,
      following: List<String>.from(data['following'] ?? []),
      followers: List<String>.from(data['followers'] ?? []),
      phoneNumber: data['phoneNumber'],
      location: data['location'] != null
          ? UserLocation.fromMap(data['location'])
          : null,
      emergencyContacts: (data['emergencyContacts'] as List<dynamic>? ?? [])
          .map((e) => EmergencyContact.fromMap(e as Map<String, dynamic>))
          .toList(),
      bloodType: data['bloodType'],
      medicalConditions: List<String>.from(data['medicalConditions'] ?? []),
      medications: List<String>.from(data['medications'] ?? []),
      insuranceInfo: data['insuranceInfo'],
      allergies: data['allergies'],
      dateOfBirth: data['dateOfBirth'] != null
          ? (data['dateOfBirth'] as Timestamp).toDate()
          : null,
      gender: data['gender'],
      height: data['height']?.toDouble(),
      weight: data['weight']?.toDouble(),
      preferredLanguage: data['preferredLanguage'],
      socialLinks: data['socialLinks'] != null
          ? Map<String, String>.from(data['socialLinks'])
          : null,
    );
  }

  Map<String, dynamic> toMap() => {
    'email': email,
    'displayName': displayName,
    'photoUrl': photoUrl,
    'bio': bio,
    'interests': interests,
    'createdAt': Timestamp.fromDate(createdAt),
    'lastActive': Timestamp.fromDate(lastActive),
    'isEmailVerified': isEmailVerified,
    'following': following,
    'followers': followers,
    'phoneNumber': phoneNumber,
    'location': location?.toMap(),
    'emergencyContacts': emergencyContacts.map((e) => e.toMap()).toList(),
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

  UserModel copyWith({
    String? displayName,
    String? photoUrl,
    String? bio,
    List<String>? interests,
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
  }) {
    return UserModel(
      uid: uid,
      email: email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      bio: bio ?? this.bio,
      interests: interests ?? this.interests,
      createdAt: createdAt,
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
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is UserModel &&
              runtimeType == other.runtimeType &&
              uid == other.uid &&
              email == other.email &&
              displayName == other.displayName &&
              photoUrl == other.photoUrl &&
              bio == other.bio &&
              interests.toString() == other.interests.toString() &&
              following.toString() == other.following.toString() &&
              followers.toString() == other.followers.toString() &&
              phoneNumber == other.phoneNumber &&
              location == other.location &&
              emergencyContacts.toString() == other.emergencyContacts.toString() &&
              bloodType == other.bloodType &&
              medicalConditions.toString() == other.medicalConditions.toString() &&
              medications.toString() == other.medications.toString() &&
              insuranceInfo == other.insuranceInfo;

  @override
  int get hashCode =>
      uid.hashCode ^
      email.hashCode ^
      displayName.hashCode ^
      photoUrl.hashCode ^
      bio.hashCode ^
      interests.hashCode ^
      following.hashCode ^
      followers.hashCode ^
      phoneNumber.hashCode ^
      location.hashCode ^
      emergencyContacts.hashCode ^
      bloodType.hashCode ^
      medicalConditions.hashCode ^
      medications.hashCode ^
      insuranceInfo.hashCode;
}