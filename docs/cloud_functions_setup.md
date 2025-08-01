# Firebase Cloud Function for User Management

This document describes the Cloud Functions needed to properly manage Firebase Auth users from the admin panel.

## Required Cloud Functions

### 1. Delete User Function

```javascript
const functions = require('firebase-functions');
const admin = require('firebase-admin');

// Initialize Firebase Admin SDK
if (!admin.apps.length) {
  admin.initializeApp();
}

exports.deleteUser = functions.https.onCall(async (data, context) => {
  // Check if the request is made by an authenticated admin
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Request not authenticated.');
  }

  // Check if the user has admin privileges
  const adminUser = await admin.firestore().collection('users').doc(context.auth.uid).get();
  if (!adminUser.exists || adminUser.data().userType !== 'admin') {
    throw new functions.https.HttpsError('permission-denied', 'User does not have admin privileges.');
  }

  const { uid } = data;
  if (!uid) {
    throw new functions.https.HttpsError('invalid-argument', 'User UID is required.');
  }

  try {
    // Delete user from Firebase Auth
    await admin.auth().deleteUser(uid);
    
    // Delete user document from Firestore
    await admin.firestore().collection('users').doc(uid).delete();
    
    // Log the deletion
    await admin.firestore().collection('admin_logs').add({
      action: 'delete_user',
      targetUid: uid,
      adminUid: context.auth.uid,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });

    return { success: true, message: 'User deleted successfully' };
  } catch (error) {
    console.error('Error deleting user:', error);
    throw new functions.https.HttpsError('internal', 'Failed to delete user: ' + error.message);
  }
});
```

### 2. Disable/Enable User Functions

```javascript
exports.disableUser = functions.https.onCall(async (data, context) => {
  // Authentication and admin check (same as above)
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Request not authenticated.');
  }

  const adminUser = await admin.firestore().collection('users').doc(context.auth.uid).get();
  if (!adminUser.exists || adminUser.data().userType !== 'admin') {
    throw new functions.https.HttpsError('permission-denied', 'User does not have admin privileges.');
  }

  const { uid } = data;
  if (!uid) {
    throw new functions.https.HttpsError('invalid-argument', 'User UID is required.');
  }

  try {
    await admin.auth().updateUser(uid, { disabled: true });
    
    // Update Firestore
    await admin.firestore().collection('users').doc(uid).update({
      isActive: false,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return { success: true, message: 'User disabled successfully' };
  } catch (error) {
    console.error('Error disabling user:', error);
    throw new functions.https.HttpsError('internal', 'Failed to disable user: ' + error.message);
  }
});

exports.enableUser = functions.https.onCall(async (data, context) => {
  // Same pattern as disableUser but with disabled: false
  // ... implementation similar to disableUser
};
```

### 3. Update User Email Function

```javascript
exports.updateUserEmail = functions.https.onCall(async (data, context) => {
  // Authentication and admin check
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Request not authenticated.');
  }

  const adminUser = await admin.firestore().collection('users').doc(context.auth.uid).get();
  if (!adminUser.exists || adminUser.data().userType !== 'admin') {
    throw new functions.https.HttpsError('permission-denied', 'User does not have admin privileges.');
  }

  const { uid, email } = data;
  if (!uid || !email) {
    throw new functions.https.HttpsError('invalid-argument', 'User UID and email are required.');
  }

  try {
    // Update Firebase Auth
    await admin.auth().updateUser(uid, { email });
    
    // Update Firestore
    await admin.firestore().collection('users').doc(uid).update({
      email,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return { success: true, message: 'User email updated successfully' };
  } catch (error) {
    console.error('Error updating user email:', error);
    throw new functions.https.HttpsError('internal', 'Failed to update user email: ' + error.message);
  }
});
```

## Deployment Instructions

1. **Initialize Firebase Functions:**
   ```bash
   firebase init functions
   ```

2. **Install Dependencies:**
   ```bash
   cd functions
   npm install firebase-functions firebase-admin
   ```

3. **Replace the generated index.js with the functions above**

4. **Deploy:**
   ```bash
   firebase deploy --only functions
   ```

## Security Considerations

1. **Admin Verification:** All functions check if the caller has admin privileges
2. **Input Validation:** All required parameters are validated
3. **Error Handling:** Proper error handling with meaningful messages
4. **Logging:** Admin actions are logged for audit purposes

## Usage in Flutter App

The `AdminUserService` class in the Flutter app calls these functions:

```dart
await AdminUserService.deleteUserFromAuth(userUid);
await AdminUserService.disableUser(userUid);
await AdminUserService.enableUser(userUid);
await AdminUserService.updateUserEmail(userUid, newEmail);
```

## Note

Currently, the app falls back to marking users as inactive in Firestore if Cloud Functions are not available. Deploy these functions for full admin functionality.
