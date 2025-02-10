import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hiker_connect/models/user_model.dart';

abstract class IAuthService {
  Future<UserModel?> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  Future<UserModel?> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
  });

  Future<UserModel?> signInWithGoogle();

  Future<void> resetPassword(String email);

  Future<void> updateUserProfile({
    String? displayName,
    String? bio,
    List<String>? interests,
    String? phoneNumber,
    UserLocation? location,
    DateTime? dateOfBirth,
    String? gender,
    double? height,
    double? weight,
    String? preferredLanguage,
    String? bloodType,
    String? allergies,
    String? insuranceInfo,
    List<String>? medicalConditions,
    List<String>? medications,
    List<EmergencyContact>? emergencyContacts,
    Map<String, String>? socialLinks,
  });
}