// test/services/firebase_auth_mock.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hiker_connect/models/user_model.dart';
import 'package:hiker_connect/services/firebase_auth.dart';

// Define mock auth service with test control capabilities
class MockAuthService with ChangeNotifier implements AuthService {
  UserModel? _mockUserData;
  User? _mockUser;

  // Test control flags
  bool _shouldThrowOnUpdate = false;
  String _updateErrorMessage = 'Update failed';

  MockAuthService({UserModel? mockUserData, User? mockUser})
      : _mockUserData = mockUserData,
        _mockUser = mockUser;

  void updateMockData({UserModel? userData, User? user}) {
    _mockUserData = userData;
    _mockUser = user;
    notifyListeners();
  }

  // Test control methods
  void setupUpdateToFail([String? errorMessage]) {
    _shouldThrowOnUpdate = true;
    if (errorMessage != null) {
      _updateErrorMessage = errorMessage;
    }
  }

  void setupUpdateToSucceed() {
    _shouldThrowOnUpdate = false;
  }

  @override
  Stream<User?> get authStateChanges => Stream.value(_mockUser);

  @override
  User? get currentUser => _mockUser;

  @override
  Future<UserModel?> getCurrentUserData() async => _mockUserData;

  @override
  Future<UserModel?> getUserData(String uid) async => _mockUserData;

  @override
  Future<void> resetPassword(String email) async {
    // Mock implementation
    return;
  }

  @override
  Future<UserModel?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    return _mockUserData;
  }

  @override
  Future<UserModel?> signInWithGoogle() async {
    return _mockUserData;
  }

  @override
  Future<UserModel?> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
  }) async {
    return _mockUserData;
  }

  @override
  Future<void> signOut() async {
    _mockUser = null;
    _mockUserData = null;
    notifyListeners();
  }

  @override
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
  }) async {
    // For tests: throw if set to fail, otherwise succeed
    if (_shouldThrowOnUpdate) {
      throw Exception(_updateErrorMessage);
    }

    // Simple mock implementation - we don't need to actually update the data
    // for the tests to pass
    return;
  }
}