import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hiker_connect/models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream to listen to auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Get current user data from Firestore
  Future<UserModel?> getCurrentUserData() async {
    if (currentUser == null) return null;
    return await getUserData(currentUser!.uid);
  }

  // Add this method to get any user's data by UID
  Future<UserModel?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.exists ? UserModel.fromFirestore(doc) : null;
    } catch (e) {
      throw Exception('Failed to get user data: $e');
    }
  }

  // Sign up with email and password
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
        // Create the user model
        final userModel = UserModel(
          uid: userCredential.user!.uid,
          email: email,
          displayName: displayName,
          createdAt: DateTime.now(),
          lastActive: DateTime.now(),
          isEmailVerified: userCredential.user!.emailVerified,
        );

        // Save user data to Firestore
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

  // Sign in with email and password
  Future<UserModel?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        // Update last active timestamp
        await _firestore.collection('users').doc(userCredential.user!.uid).update({
          'lastActive': FieldValue.serverTimestamp(),
        });

        // Get and return user data
        return await getCurrentUserData();
      }
      return null;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Update user profile
  Future<void> updateUserProfile({
    String? displayName,
    String? photoUrl,
    String? bio,
    List<String>? interests,
  }) async {
    if (currentUser == null) throw Exception('No user logged in');

    try {
      final userDoc = _firestore.collection('users').doc(currentUser!.uid);
      final updates = <String, dynamic>{
        if (displayName != null) 'displayName': displayName,
        if (photoUrl != null) 'photoUrl': photoUrl,
        if (bio != null) 'bio': bio,
        if (interests != null) 'interests': interests,
        'lastActive': FieldValue.serverTimestamp(),
      };

      await userDoc.update(updates);
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
    if (currentUser != null) {
      // Update last active timestamp before signing out
      await _firestore.collection('users').doc(currentUser!.uid).update({
        'lastActive': FieldValue.serverTimestamp(),
      });
    }
    await _auth.signOut();
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
      // Delete user data from Firestore
      await _firestore.collection('users').doc(currentUser!.uid).delete();
      // Delete user authentication
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