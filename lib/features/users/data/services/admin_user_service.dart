import 'package:cloud_functions/cloud_functions.dart';

class AdminUserService {
  static final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// Deletes a user from Firebase Auth using Cloud Functions
  /// This requires a Cloud Function with Firebase Admin SDK
  static Future<void> deleteUserFromAuth(String uid) async {
    try {
      final HttpsCallable callable = _functions.httpsCallable('deleteUser');
      await callable.call({'uid': uid});
    } catch (e) {
      throw Exception('Failed to delete user from Firebase Auth: $e');
    }
  }

  /// Updates user email in Firebase Auth using Cloud Functions
  static Future<void> updateUserEmail(String uid, String newEmail) async {
    try {
      final HttpsCallable callable = _functions.httpsCallable(
        'updateUserEmail',
      );
      await callable.call({'uid': uid, 'email': newEmail});
    } catch (e) {
      throw Exception('Failed to update user email in Firebase Auth: $e');
    }
  }

  /// Disables user account in Firebase Auth using Cloud Functions
  static Future<void> disableUser(String uid) async {
    try {
      final HttpsCallable callable = _functions.httpsCallable('disableUser');
      await callable.call({'uid': uid});
    } catch (e) {
      throw Exception('Failed to disable user in Firebase Auth: $e');
    }
  }

  /// Enables user account in Firebase Auth using Cloud Functions
  static Future<void> enableUser(String uid) async {
    try {
      final HttpsCallable callable = _functions.httpsCallable('enableUser');
      await callable.call({'uid': uid});
    } catch (e) {
      throw Exception('Failed to enable user in Firebase Auth: $e');
    }
  }
}
