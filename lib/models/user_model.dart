import 'package:cloud_firestore/cloud_firestore.dart';

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
  });

  // Create a UserModel from a Firebase User
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
    );
  }

  // Convert UserModel to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
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
    };
  }

  // Create a copy of UserModel with some updated fields
  UserModel copyWith({
    String? displayName,
    String? photoUrl,
    String? bio,
    List<String>? interests,
    DateTime? lastActive,
    bool? isEmailVerified,
    List<String>? following,
    List<String>? followers,
  }) {
    return UserModel(
      uid: this.uid,
      email: this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      bio: bio ?? this.bio,
      interests: interests ?? this.interests,
      createdAt: this.createdAt,
      lastActive: lastActive ?? this.lastActive,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      following: following ?? this.following,
      followers: followers ?? this.followers,
    );
  }

  // Compare two UserModel objects
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
              createdAt == other.createdAt &&
              lastActive == other.lastActive &&
              isEmailVerified == other.isEmailVerified &&
              following.toString() == other.following.toString() &&
              followers.toString() == other.followers.toString();

  @override
  int get hashCode =>
      uid.hashCode ^
      email.hashCode ^
      displayName.hashCode ^
      photoUrl.hashCode ^
      bio.hashCode ^
      interests.hashCode ^
      createdAt.hashCode ^
      lastActive.hashCode ^
      isEmailVerified.hashCode ^
      following.hashCode ^
      followers.hashCode;

  @override
  String toString() {
    return 'UserModel{uid: $uid, email: $email, displayName: $displayName, '
        'photoUrl: $photoUrl, bio: $bio, interests: $interests, '
        'createdAt: $createdAt, lastActive: $lastActive, '
        'isEmailVerified: $isEmailVerified, following: $following, '
        'followers: $followers}';
  }
}