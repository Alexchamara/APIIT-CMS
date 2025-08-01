import 'package:apiit_cms/features/auth/domain/models/user_model.dart';
import 'package:apiit_cms/features/users/domain/repositories/user_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:apiit_cms/firebase_options.dart';

class UserRepositoryImpl implements UserRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Future<List<UserModel>> getAllUsers() async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .orderBy('displayName')
          .get();

      return querySnapshot.docs
          .map((doc) => UserModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch users: $e');
    }
  }

  @override
  Stream<List<UserModel>> getUsersStream() {
    return _firestore
        .collection('users')
        .orderBy('displayName')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => UserModel.fromMap(doc.data()))
              .toList(),
        );
  }

  @override
  Future<void> updateUser(UserModel user) async {
    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .update(user.copyWith(updatedAt: DateTime.now()).toMap());
    } catch (e) {
      throw Exception('Failed to update user: $e');
    }
  }

  @override
  Future<void> deleteUser(String uid) async {
    try {
      // First deactivate the user in Firestore
      await _firestore.collection('users').doc(uid).update({
        'isActive': false,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      // For a complete deletion, we need to use Firebase Admin SDK
      // This is a limitation of client-side Firebase Auth
      // In production, this should be done via a Cloud Function with Admin SDK

      // For now, we'll only deactivate the user in Firestore
      // The auth account will remain but be marked as inactive
    } catch (e) {
      throw Exception('Failed to delete user: $e');
    }
  }

  @override
  Future<void> deleteUserCompletely(String uid) async {
    try {
      // First, delete from Firestore
      await _firestore.collection('users').doc(uid).delete();

      // Try to delete from Firebase Auth
      // Note: This approach has limitations and works only in specific scenarios
      final currentUser = _auth.currentUser;

      if (currentUser?.uid == uid) {
        // If deleting own account
        await currentUser?.delete();
      } else {
        // For deleting other users' auth accounts, you would need:
        // 1. Firebase Admin SDK (server-side)
        // 2. Cloud Functions
        // 3. Custom backend with admin privileges

        // For now, we'll simulate the deletion by:
        // 1. Removing from Firestore (done above)
        // 2. Marking as deleted in a separate collection for audit
        await _firestore.collection('deleted_users').doc(uid).set({
          'deletedAt': Timestamp.fromDate(DateTime.now()),
          'deletedBy': currentUser?.uid ?? 'unknown',
          'originalUid': uid,
        });

        // User deleted from Firestore. Auth account requires admin deletion.
      }
    } catch (e) {
      throw Exception('Failed to completely delete user: $e');
    }
  }

  @override
  Future<UserModel?> createUser({
    required String email,
    required String displayName,
    required UserType userType,
    String? phoneNumber,
  }) async {
    FirebaseApp? secondaryApp;
    try {
      // Create a temporary password for the user
      const tempPassword = 'TempPass123!';

      // Create a secondary Firebase app to avoid affecting the current user session
      secondaryApp = await Firebase.initializeApp(
        name: 'secondary-${DateTime.now().millisecondsSinceEpoch}',
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // Get FirebaseAuth instance for the secondary app
      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);

      // Create user with the secondary auth instance
      final userCredential = await secondaryAuth.createUserWithEmailAndPassword(
        email: email,
        password: tempPassword,
      );

      if (userCredential.user != null) {
        final newUser = userCredential.user!;

        // Update display name in Firebase Auth
        await newUser.updateDisplayName(displayName);

        // Create user document in Firestore (using main instance)
        final userModel = UserModel(
          uid: newUser.uid,
          email: email,
          displayName: displayName,
          userType: userType,
          phoneNumber: phoneNumber,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await _firestore
            .collection('users')
            .doc(newUser.uid)
            .set(userModel.toMap());

        // Send password reset email so user can set their own password
        await secondaryAuth.sendPasswordResetEmail(email: email);

        // Sign out from secondary app
        await secondaryAuth.signOut();

        return userModel;
      }
      return null;
    } catch (e) {
      throw Exception('Failed to create user: $e');
    } finally {
      // Clean up secondary app
      if (secondaryApp != null) {
        await secondaryApp.delete();
      }
    }
  }
}
