import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hiker_connect/models/user_model.dart';
import 'auth_service_interface.dart';
import 'dart:developer' as developer;
import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';

class AuthService extends ChangeNotifier implements IAuthService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;

  // Flag to track if we're running in a test/emulator environment
  final bool _isEmulatorMode;

  /// Constructor with optional dependency injection for easier testing
  AuthService({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
    GoogleSignIn? googleSignIn,
    bool? isEmulatorMode,
  })  : _auth = firebaseAuth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn(),
        _isEmulatorMode = isEmulatorMode ?? kDebugMode {
    // Initialization debug logging
    developer.log(
      'AuthService initialized. Is emulator mode: $_isEmulatorMode',
      name: 'AuthService',
    );
  }

  /// Stream of authentication state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Get the currently authenticated user
  User? get currentUser => _auth.currentUser;

  /// Retrieve current user's data
  Future<UserModel?> getCurrentUserData() async {
    if (currentUser == null) return null;
    return await getUserData(currentUser!.uid);
  }

  /// Retrieve user data by user ID
  Future<UserModel?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.exists ? UserModel.fromFirestore(doc) : null;
    } catch (e, stackTrace) {
      // Enhanced error logging to catch App Check errors
      if (e is FirebaseException && e.code == 'permission-denied') {
        developer.log(
          'App Check or Permission Error: Failed to get user data',
          name: 'AuthService',
          error: {
            'error': e,
            'code': e.code,
            'message': e.message,
            'plugin': e.plugin,
          },
          stackTrace: stackTrace,
        );
      } else {
        developer.log(
          'Failed to get user data',
          name: 'AuthService',
          error: e,
          stackTrace: stackTrace,
        );
      }
      rethrow;
    }
  }

  /// Reset user password
  @override
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      developer.log(
        'Password reset email sent to $email',
        name: 'AuthService',
      );
    } on FirebaseAuthException catch (e) {
      developer.log(
        'Error sending password reset email',
        name: 'AuthService',
        error: e,
        stackTrace: StackTrace.current,
      );
      throw _handleAuthException(e);
    }
  }

  /// Update user profile
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
    // Ensure a user is logged in
    if (currentUser == null) {
      throw Exception('No user logged in');
    }

    try {
      // Prepare the update map with non-null values
      final updates = <String, dynamic>{
        if (displayName != null) 'displayName': displayName,
        if (bio != null) 'bio': bio,
        if (interests != null) 'interests': interests,
        if (phoneNumber != null) 'phoneNumber': phoneNumber,
        if (location != null) 'location': location.toMap(),
        if (dateOfBirth != null) 'dateOfBirth': Timestamp.fromDate(dateOfBirth),
        if (gender != null) 'gender': gender,
        if (height != null) 'height': height,
        if (weight != null) 'weight': weight,
        if (preferredLanguage != null) 'preferredLanguage': preferredLanguage,
        if (bloodType != null) 'bloodType': bloodType,
        if (allergies != null) 'allergies': allergies,
        if (insuranceInfo != null) 'insuranceInfo': insuranceInfo,
        if (medicalConditions != null) 'medicalConditions': medicalConditions,
        if (medications != null) 'medications': medications,
        if (emergencyContacts != null)
          'emergencyContacts': emergencyContacts.map((e) => e.toMap()).toList(),
        if (socialLinks != null) 'socialLinks': socialLinks,
        'lastActive': FieldValue.serverTimestamp(),
      };

      // Update Firestore document
      await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .update(updates);

      developer.log(
        'Profile updated successfully',
        name: 'AuthService',
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error updating profile',
        name: 'AuthService',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Email validation method with more robust regex
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
      caseSensitive: false,
    );
    return emailRegex.hasMatch(email.trim());
  }

  /// Password validation method
  bool _isValidPassword(String password) {
    // In production, enforce strong passwords
    if (!_isEmulatorMode) {
      return password.length >= 8 &&
          password.contains(RegExp(r'[A-Z]')) &&
          password.contains(RegExp(r'[a-z]')) &&
          password.contains(RegExp(r'[0-9]'));
    }
    // In development mode, accept any non-empty password
    return password.isNotEmpty;
  }

  Future<UserModel> _createOrGetUserDocument(User firebaseUser, String email) async {
    try {
      final userDoc = await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .get();

      if (!userDoc.exists) {
        final newUser = UserModel(
          uid: firebaseUser.uid,
          email: firebaseUser.email ?? email,
          displayName: firebaseUser.displayName ?? email.split('@')[0],
          createdAt: DateTime.now(),
          lastActive: DateTime.now(),
          isEmailVerified: firebaseUser.emailVerified,
          photoUrl: firebaseUser.photoURL ?? '',
          interests: [],
          following: [],
          followers: [],
        );

        try {
          await _firestore
              .collection('users')
              .doc(firebaseUser.uid)
              .set(newUser.toMap());
        } catch (e) {
          if (e is FirebaseException && e.code == 'permission-denied') {
            developer.log(
              'App Check or Permission Error: Failed to create user document',
              name: 'AuthService',
              error: {
                'error': e,
                'code': e.code,
                'message': e.message,
                'plugin': e.plugin,
              },
            );
          }
          rethrow;
        }

        return newUser;
      }

      return UserModel.fromFirestore(userDoc);
    } catch (e, stackTrace) {
      developer.log(
        'Error in _createOrGetUserDocument',
        name: 'AuthService',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<UserModel?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      // Skip validation in debug/test mode for easier testing
      if (!_isEmulatorMode && !_isValidEmail(email)) {
        throw ArgumentError('Invalid email format');
      }

      final trimmedEmail = email.trim();

      // Don't trim password as it might contain intentional spaces
      final trimmedPassword = password;

      // Log sign-in attempt
      developer.log(
        'Attempting sign in for: $trimmedEmail',
        name: 'AuthService',
      );

      try {
        // Try authentication with Firebase
        final userCredential = await _auth.signInWithEmailAndPassword(
          email: trimmedEmail,
          password: trimmedPassword,
        );

        final firebaseUser = userCredential.user;
        if (firebaseUser == null) {
          developer.log('Firebase returned null user after sign in', name: 'AuthService');
          throw Exception('Authentication failed');
        }

        developer.log(
          'Successfully authenticated user: ${firebaseUser.uid}',
          name: 'AuthService',
        );

        // Retrieve or create user document
        return await _createOrGetUserDocument(firebaseUser, trimmedEmail);
      } on FirebaseAuthException catch (e) {
        developer.log(
          'FirebaseAuthException during login: ${e.code} - ${e.message}',
          name: 'AuthService',
          error: e,
        );
        throw _handleAuthException(e);
      }
    } catch (e, stackTrace) {
      developer.log(
        'Comprehensive sign-in error',
        name: 'AuthService',
        error: e,
        stackTrace: stackTrace,
      );

      if (e is FirebaseAuthException) {
        throw _handleAuthException(e);
      }

      if (e is ArgumentError) {
        throw e.message.toString();
      }

      // Added full error message for debugging
      developer.log(
        'Unexpected error type: ${e.runtimeType}',
        name: 'AuthService',
        error: e.toString(),
        stackTrace: stackTrace,
      );

      throw 'Login failed: ${e.toString()}';
    }
  }

  @override
  Future<UserModel?> signInWithGoogle() async {
    try {
      developer.log('Starting Google sign in flow', name: 'AuthService');

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        developer.log('Google sign in canceled by user', name: 'AuthService');
        return null;
      }

      developer.log('Google user authenticated: ${googleUser.email}', name: 'AuthService');

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      developer.log('Signing in to Firebase with Google credential', name: 'AuthService');

      final userCredential = await _auth.signInWithCredential(credential);

      if (userCredential.user == null) {
        developer.log('No Firebase user returned from Google sign in', name: 'AuthService');
        return null;
      }

      developer.log(
        'Successfully signed in with Google: ${userCredential.user!.uid}',
        name: 'AuthService',
      );

      // Retrieve or create user document
      return await _createOrGetUserDocument(
          userCredential.user!,
          googleUser.email
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error signing in with Google',
        name: 'AuthService',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<UserModel?> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      // Skip validation in debug/test mode for easier development
      if (!_isEmulatorMode) {
        // Comprehensive input validation
        if (!_isValidEmail(email)) {
          throw ArgumentError('Please enter a valid email address');
        }

        if (!_isValidPassword(password)) {
          throw ArgumentError(
            'Password must be at least 8 characters long and include '
                'uppercase, lowercase, and numeric characters',
          );
        }

        if (displayName.trim().length < 2) {
          throw ArgumentError('Display name must be at least 2 characters long');
        }
      }

      developer.log('Creating user with email: ${email.trim()}', name: 'AuthService');

      // Create user in Firebase Authentication
      final UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      )
          .timeout(
        const Duration(seconds: 15), // Increased timeout
        onTimeout: () => throw TimeoutException('Sign-up request timed out'),
      );

      final User? firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        developer.log('No Firebase user returned after creation', name: 'AuthService');
        return null;
      }

      developer.log('User created in Firebase: ${firebaseUser.uid}', name: 'AuthService');

      // Create user document in Firestore
      final newUser = UserModel(
        uid: firebaseUser.uid,
        email: firebaseUser.email!,
        displayName: displayName.trim(),
        createdAt: DateTime.now(),
        lastActive: DateTime.now(),
        isEmailVerified: false,
        photoUrl: null,
        interests: [],
        following: [],
        followers: [],
      );

      try {
        await _firestore
            .collection('users')
            .doc(firebaseUser.uid)
            .set(newUser.toMap());

        developer.log('User document created in Firestore', name: 'AuthService');
      } catch (e) {
        developer.log(
          'Error creating user document in Firestore',
          name: 'AuthService',
          error: e,
        );
        // Continue even if Firestore update fails - we can try again later
      }

      // Optional: Send email verification (no need to await)
      try {
        firebaseUser.sendEmailVerification();
        developer.log('Verification email sent', name: 'AuthService');
      } catch (e) {
        developer.log('Error sending verification email: $e', name: 'AuthService');
        // Non-critical, continue anyway
      }

      return newUser;
    } on FirebaseAuthException catch (e) {
      developer.log(
        'Sign-up error',
        name: 'AuthService',
        error: e,
      );
      throw _handleAuthException(e);
    } on TimeoutException catch (e) {
      developer.log(
        'Sign-up timeout',
        name: 'AuthService',
        error: e,
      );
      throw Exception('Sign-up took too long. Please check your connection.');
    } catch (e, stackTrace) {
      developer.log(
        'Unexpected sign-up error',
        name: 'AuthService',
        error: e,
        stackTrace: stackTrace,
      );

      if (e is ArgumentError) {
        throw e.message.toString();
      }

      throw Exception('An unexpected error occurred during sign-up');
    }
  }

  String _handleAuthException(FirebaseAuthException e) {
    developer.log(
      'Authentication Error: ${e.code}',
      name: 'AuthService',
      error: e,
    );

    final errorMessages = {
      'user-not-found': 'No account found with this email. Please sign up.',
      'wrong-password': 'Incorrect password. Please try again.',
      'email-already-in-use': 'An account already exists with this email.',
      'invalid-email': 'Invalid email address format.',
      'weak-password': 'Password is too weak. Use a stronger password.',
      'network-request-failed': 'Network error. Please check your connection.',
      'too-many-requests': 'Too many login attempts. Please try again later.',
      'user-disabled': 'This account has been disabled.',
      'operation-not-allowed': 'This login method is not enabled.',
      'invalid-credential': 'Your login information appears to be invalid. Please try resetting your password.',
      'INVALID_LOGIN_CREDENTIALS': 'The email or password is incorrect. Please try again.',
      'account-exists-with-different-credential': 'An account already exists with the same email address but different sign-in credentials.',
    };

    return errorMessages[e.code] ?? 'Authentication failed. Please try again.';
  }

  /// Sign out of the application
  Future<void> signOut() async {
    try {
      // Try Google sign out first
      try {
        await _googleSignIn.signOut();
        developer.log(
          'Successfully signed out from Google',
          name: 'AuthService',
        );
      } catch (e) {
        developer.log(
          'Error signing out from Google',
          name: 'AuthService',
          error: e,
          stackTrace: StackTrace.current,
        );
        // Continue with Firebase sign out even if Google sign out fails
      }

      // Then Firebase sign out
      await _auth.signOut();
      notifyListeners(); // Add notification after successful sign out
      developer.log(
        'Successfully signed out from Firebase',
        name: 'AuthService',
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error during Firebase sign out',
        name: 'AuthService',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}