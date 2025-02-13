import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hiker_connect/models/user_model.dart';
import 'auth_service_interface.dart';
import 'dart:developer' as developer;
import 'dart:async';
import 'package:flutter/foundation.dart';


class AuthService extends ChangeNotifier implements IAuthService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;

  /// Constructor with optional dependency injection for easier testing
  AuthService({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
    GoogleSignIn? googleSignIn,
  })  : _auth = firebaseAuth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn();

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
    return password.length >= 8 &&
        password.contains(RegExp(r'[A-Z]')) &&
        password.contains(RegExp(r'[a-z]')) &&
        password.contains(RegExp(r'[0-9]'));
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
      // Validate inputs
      if (!_isValidEmail(email)) {
        throw ArgumentError('Invalid email format');
      }

      final trimmedEmail = email.trim();
      final trimmedPassword = password.trim();

      // Log sign-in attempt with more details
      developer.log(
        'Attempting sign in for: $trimmedEmail',
        name: 'AuthService',
      );

      // Perform authentication with explicit error handling
      UserCredential? userCredential;
      try {
        userCredential = await _auth.signInWithEmailAndPassword(
          email: trimmedEmail,
          password: trimmedPassword,
        );
      } on FirebaseAuthException catch (authException) {
        developer.log(
          'FirebaseAuthException details: ${authException.code}, ${authException.message}',
          name: 'AuthService',
        );
        throw _handleAuthException(authException);
      } catch (e) {
        developer.log(
          'Unexpected authentication error: $e',
          name: 'AuthService',
          error: e,
        );
        rethrow;
      }

      // Explicit null and type checks
      final User? firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        developer.log('No user found after authentication', name: 'AuthService');
        return null;
      }

      // Retrieve or create user document
      return await _createOrGetUserDocument(firebaseUser, trimmedEmail);

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

      throw Exception('An unexpected error occurred during login. Please try again.');
    }
  }

  @override
  Future<UserModel?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);

      if (userCredential.user == null) return null;

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

      // Create user in Firebase Authentication
      final UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      )
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException('Sign-up request timed out'),
      );

      final User? firebaseUser = userCredential.user;
      if (firebaseUser == null) return null;

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

      await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .set(newUser.toMap());

      // Optional: Send email verification
      await firebaseUser.sendEmailVerification();

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
      throw Exception('An unexpected error occurred during sign-up');
    }
  }

  /// Handle Firebase Auth exceptions with more detailed error messages
  String _handleAuthException(FirebaseAuthException e) {
    developer.log(
      'Authentication Error: ${e.code}',
      name: 'AuthService',
      error: e,
    );

    switch (e.code) {
      case 'user-not-found':
        return 'No account found with this email. Please sign up.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'invalid-email':
        return 'Invalid email address format.';
      case 'weak-password':
        return 'Password is too weak. Use a stronger password.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      case 'too-many-requests':
        return 'Too many login attempts. Please try again later.';
      case 'user-disabled':
        return 'This account has been disabled.';
      default:
        return 'Authentication failed. Please try again.';
    }
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