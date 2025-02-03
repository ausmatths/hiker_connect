import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hiker_connect/models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  // Get current user data from Firestore
  Future<UserModel?> getCurrentUserData() async {
    if (currentUser == null) return null;
    return await getUserData(currentUser!.uid);
  }

  // Get user data by UID
  Future<UserModel?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.exists ? UserModel.fromFirestore(doc) : null;
    } catch (e) {
      throw Exception('Failed to get user data: $e');
    }
  }

  // Sign up
  Future<UserModel?> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        final userModel = UserModel(
          uid: userCredential.user!.uid,
          email: email,
          displayName: displayName,
          createdAt: DateTime.now(),
          lastActive: DateTime.now(),
          isEmailVerified: userCredential.user!.emailVerified,
          interests: [],
          following: [],
          followers: [],
        );

        await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .set(userModel.toMap());

        return userModel;
      }
      return null;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<UserModel?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      print('Attempting to sign in with email: $email');

      // First authenticate
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        print('No user returned after authentication');
        return null;
      }

      print('User authenticated successfully: ${credential.user!.uid}');

      // Then get/create user document
      DocumentSnapshot<Map<String, dynamic>> doc =
      await _firestore.collection('users').doc(credential.user!.uid).get();

      if (!doc.exists) {
        print('Creating new user document');
        // Create new user document
        final newUser = UserModel(
          uid: credential.user!.uid,
          email: email,
          displayName: email.split('@')[0],
          createdAt: DateTime.now(),
          lastActive: DateTime.now(),
          isEmailVerified: credential.user!.emailVerified,
          interests: [],
          following: [],
          followers: [],
        );

        await _firestore
            .collection('users')
            .doc(credential.user!.uid)
            .set(newUser.toMap());

        return newUser;
      }

      print('Returning existing user document');
      return UserModel.fromFirestore(doc);

    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      print('Unexpected error during sign in: $e');
      throw Exception('An error occurred during sign in');
    }
  }

  // Update profile
  Future<void> updateUserProfile({
    String? displayName,
    String? photoUrl,
    String? bio,
    List<String>? interests,
  }) async {
    if (currentUser == null) throw Exception('No user logged in');

    try {
      final updates = <String, dynamic>{
        if (displayName != null) 'displayName': displayName,
        if (photoUrl != null) 'photoUrl': photoUrl,
        if (bio != null) 'bio': bio,
        if (interests != null) 'interests': interests,
        'lastActive': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('users').doc(currentUser!.uid).update(updates);
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  // Follow user
  Future<void> followUser(String targetUserId) async {
    if (currentUser == null) throw Exception('No user logged in');
    if (currentUser!.uid == targetUserId) throw Exception('Cannot follow yourself');

    final batch = _firestore.batch();
    final currentUserDoc = _firestore.collection('users').doc(currentUser!.uid);
    final targetUserDoc = _firestore.collection('users').doc(targetUserId);

    batch.update(currentUserDoc, {
      'following': FieldValue.arrayUnion([targetUserId])
    });
    batch.update(targetUserDoc, {
      'followers': FieldValue.arrayUnion([currentUser!.uid])
    });

    await batch.commit();
  }

  // Unfollow user
  Future<void> unfollowUser(String targetUserId) async {
    if (currentUser == null) throw Exception('No user logged in');

    final batch = _firestore.batch();
    final currentUserDoc = _firestore.collection('users').doc(currentUser!.uid);
    final targetUserDoc = _firestore.collection('users').doc(targetUserId);

    batch.update(currentUserDoc, {
      'following': FieldValue.arrayRemove([targetUserId])
    });
    batch.update(targetUserDoc, {
      'followers': FieldValue.arrayRemove([currentUser!.uid])
    });

    await batch.commit();
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      print('Successfully signed out');
    } catch (e) {
      print('Error during sign out: $e');
      throw Exception('Failed to sign out: $e');
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Delete account
  Future<void> deleteAccount() async {
    if (currentUser == null) throw Exception('No user logged in');

    try {
      await _firestore.collection('users').doc(currentUser!.uid).delete();
      await currentUser!.delete();
    } catch (e) {
      throw Exception('Failed to delete account: $e');
    }
  }

  // Handle Firebase Auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'weak-password':
        return 'Password is too weak.';
      case 'operation-not-allowed':
        return 'Operation not allowed.';
      default:
        return 'An error occurred. Please try again.';
    }
  }
}