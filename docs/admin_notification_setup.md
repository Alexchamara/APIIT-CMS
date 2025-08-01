# Admin Notification System Setup Guide

This guide explains how to set up and configure the admin notification system for the APIIT CMS application.

## Overview

The notification system automatically sends push notifications to admin users when:
- Support tickets are created or updated
- Reservations are created or updated
- Messages are added to support tickets
- Ticket statuses change

## Components

### 1. Flutter App Components

#### NotificationService (`lib/shared/services/notification_service.dart`)
- Handles FCM token management
- Initializes push notifications
- Provides methods to send notifications to admins
- Manages foreground and background notification handling

#### AdminNotificationModel (`lib/shared/models/admin_notification_model.dart`)
- Data model for notification tracking
- Includes status, timing, and content information

#### AdminNotificationRepository (`lib/shared/repositories/admin_notification_repository.dart`)
- Repository for managing notification data
- Provides streams for real-time notification monitoring
- Includes statistics and cleanup functions

### 2. Firebase Cloud Functions

#### sendNotifications
- Triggered when documents are created in `notifications` collection
- Sends actual push notifications via FCM
- Updates notification status (sent/failed)

#### notifyAdminsOnTicketChange
- Triggered on support ticket document changes
- Detects new tickets, status updates, and message additions
- Creates notification documents for all admin users

#### notifyAdminsOnReservationChange
- Triggered on reservation document changes
- Detects new reservations and updates
- Creates notification documents for all admin users

## Setup Instructions

### 1. Flutter App Setup

#### Dependencies
Add to `pubspec.yaml`:
```yaml
dependencies:
  firebase_messaging: ^15.1.4
```

#### Permissions

##### Android (`android/app/src/main/AndroidManifest.xml`)
```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.WAKE_LOCK" />
<uses-permission android:name="android.permission.VIBRATE" />
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />

<!-- Firebase Messaging -->
<service
    android:name=".java.MyFirebaseMessagingService"
    android:exported="false">
    <intent-filter>
        <action android:name="com.google.firebase.MESSAGING_EVENT" />
    </intent-filter>
</service>
```

##### iOS (`ios/Runner/Info.plist`)
```xml
<key>UIBackgroundModes</key>
<array>
    <string>fetch</string>
    <string>remote-notification</string>
</array>
```

#### Initialization
The notification service is automatically initialized in `main.dart`:
```dart
await NotificationService.initialize();
NotificationService.handleForegroundNotification();
NotificationService.handleNotificationTap();
await NotificationService.handleInitialNotification();
```

### 2. Firebase Functions Setup

#### Prerequisites
- Firebase CLI installed
- Project Owner or Editor permissions
- Service Account User role assigned

#### Deployment Steps

1. **Install Dependencies**
   ```bash
   cd firebase-functions/functions
   npm install
   ```

2. **Build TypeScript**
   ```bash
   npm run build
   ```

3. **Deploy Functions**
   ```bash
   cd ..
   firebase deploy --only functions
   ```

4. **Verify Deployment**
   Check Firebase Console > Functions to ensure all functions are deployed:
   - `deleteUserDocument`
   - `sendNotifications`
   - `notifyAdminsOnTicketChange`
   - `notifyAdminsOnReservationChange`

### 3. Firebase Console Configuration

#### Cloud Messaging Setup
1. Go to Firebase Console > Project Settings > Cloud Messaging
2. Generate a Web Push certificate (for web support)
3. Note the Sender ID for Android configuration

#### Security Rules
Ensure Firestore security rules allow:
- Admin users to read from `notifications` collection
- Cloud Functions to write to `notifications` collection
- Users to update their own `fcmToken` field

Example rules:
```javascript
// Allow users to update their FCM token
match /users/{userId} {
  allow read, write: if request.auth != null && request.auth.uid == userId;
  allow read: if isAdmin();
}

// Allow admins to read notifications
match /notifications/{notificationId} {
  allow read: if isAdmin();
  allow write: if false; // Only Cloud Functions should write
}

function isAdmin() {
  return resource.data.userType == 'admin';
}
```

## How It Works

### 1. User Authentication & Token Management
- When users log in, FCM token is automatically retrieved
- Token is stored in user document: `users/{uid}.fcmToken`
- Token is refreshed automatically when needed

### 2. Notification Flow

#### Support Tickets
1. User creates/updates support ticket
2. Repository calls `NotificationService.notifyAdminsAboutNewTicket()`
3. Service gets all admin users with FCM tokens
4. Creates notification documents in `notifications` collection
5. Cloud Function `sendNotifications` triggers
6. Push notifications sent to admin devices

#### Reservations
1. User creates/updates reservation
2. Repository calls `NotificationService.notifyAdminsAboutNewReservation()`
3. Same flow as support tickets

### 3. Cloud Function Triggers
- Functions monitor `support_tickets` and `reservations` collections
- Detect document changes (create, update)
- Automatically create notification documents
- Handle edge cases and error scenarios

## Notification Types

### Support Ticket Notifications
- **New Ticket**: When a ticket is created
- **Status Update**: When ticket status changes
- **Message Added**: When new messages are added

### Reservation Notifications
- **New Reservation**: When a reservation is created
- **Reservation Update**: When reservation details change

## Monitoring & Management

### Admin Dashboard Features
- View all notifications (recent, by type, by status)
- Notification statistics (sent, failed, pending)
- Retry failed notifications
- Cleanup old notifications

### Usage Examples

#### Check Notification Stats
```dart
final stats = await AdminNotificationRepository.getNotificationStats();
print('Today sent: ${stats['today_sent']}');
print('Today failed: ${stats['today_failed']}');
```

#### Monitor Recent Notifications
```dart
AdminNotificationRepository.getRecentNotifications().listen((notifications) {
  for (final notification in notifications) {
    print('${notification.title}: ${notification.status}');
  }
});
```

#### Cleanup Old Data
```dart
await AdminNotificationRepository.cleanupOldNotifications();
```

## Troubleshooting

### Common Issues

#### No Notifications Received
1. Check FCM token is stored in user document
2. Verify user has admin privileges
3. Check Cloud Functions logs in Firebase Console
4. Ensure notification permissions are granted

#### Functions Not Triggering
1. Verify functions are deployed successfully
2. Check Firestore security rules
3. Review function logs for errors
4. Ensure proper IAM permissions

#### Token Issues
1. Token refresh happens automatically
2. Check network connectivity
3. Verify Firebase configuration
4. Re-initialize notification service

### Debugging Steps

1. **Check User FCM Token**
   ```dart
   final token = await FirebaseMessaging.instance.getToken();
   print('FCM Token: $token');
   ```

2. **Verify Admin Status**
   ```dart
   final user = await AuthRepository.getCurrentUserModel();
   print('User Type: ${user?.userType}');
   ```

3. **Monitor Function Logs**
   ```bash
   firebase functions:log
   ```

4. **Test Notification Flow**
   - Create a test support ticket
   - Check `notifications` collection in Firestore
   - Verify notification document creation
   - Check function execution logs

## Security Considerations

- FCM tokens are stored securely in user documents
- Only admin users receive notifications
- Cloud Functions validate user permissions
- Notification data includes minimal sensitive information
- Old notifications are automatically cleaned up

## Performance Optimization

- Notifications are batched for multiple admins
- Token refresh is handled automatically
- Failed notifications can be retried
- Old data is cleaned up regularly
- Limits on notification history (100 recent items)

## Future Enhancements

- Push notification scheduling
- Notification templates and customization
- Rich media notifications
- Email fallback for critical notifications
- Notification preferences per admin
- Real-time notification dashboard
- Analytics and reporting
