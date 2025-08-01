import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:apiit_cms/features/auth/domain/models/user_model.dart';
import 'package:apiit_cms/features/support/domain/models/support_ticket_model.dart';
import 'package:apiit_cms/features/reservations/domain/models/reservation_model.dart';

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Initialize notifications and request permissions
  static Future<void> initialize() async {
    // Request notification permissions
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    // Get and store FCM token
    await _updateFCMToken();

    // Listen for token refresh
    FirebaseMessaging.instance.onTokenRefresh.listen(_updateFCMTokenOnRefresh);
  }

  /// Get current FCM token and update in Firestore
  static Future<void> _updateFCMToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        await _updateUserFCMToken(token);
      }
    } catch (e) {
      print('Error updating FCM token: $e');
    }
  }

  /// Update FCM token on refresh
  static Future<void> _updateFCMTokenOnRefresh(String token) async {
    await _updateUserFCMToken(token);
  }

  /// Update user's FCM token in Firestore
  static Future<void> _updateUserFCMToken(String token) async {
    try {
      final user = await _getCurrentUserDocument();
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'fcmToken': token,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error updating user FCM token: $e');
    }
  }

  /// Get current user document
  static Future<UserModel?> _getCurrentUserDocument() async {
    try {
      final authUser = await FirebaseAuth.instance.currentUser;
      if (authUser != null) {
        final doc = await _firestore.collection('users').doc(authUser.uid).get();
        if (doc.exists) {
          return UserModel.fromMap(doc.data()!);
        }
      }
      return null;
    } catch (e) {
      print('Error getting current user: $e');
      return null;
    }
  }

  /// Get all admin users with FCM tokens
  static Future<List<UserModel>> _getAdminUsers() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('userType', isEqualTo: 'admin')
          .where('isActive', isEqualTo: true)
          .get();

      return snapshot.docs
          .map((doc) => UserModel.fromMap(doc.data()))
          .where((user) => snapshot.docs
              .firstWhere((doc) => doc.data()['uid'] == user.uid)
              .data()
              .containsKey('fcmToken'))
          .toList();
    } catch (e) {
      print('Error getting admin users: $e');
      return [];
    }
  }

  /// Send notification to specific users
  static Future<void> _sendNotificationToUsers({
    required List<UserModel> users,
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    for (final user in users) {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final fcmToken = userDoc.data()?['fcmToken'] as String?;
      
      if (fcmToken != null) {
        await _createNotificationDocument(
          fcmToken: fcmToken,
          title: title,
          body: body,
          data: data,
        );
      }
    }
  }

  /// Create notification document that triggers Cloud Function
  static Future<void> _createNotificationDocument({
    required String fcmToken,
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'fcmToken': fcmToken,
        'title': title,
        'body': body,
        'data': data ?? {},
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      });
    } catch (e) {
      print('Error creating notification document: $e');
    }
  }

  /// Notify admins about new support ticket
  static Future<void> notifyAdminsAboutNewTicket(SupportTicketModel ticket) async {
    try {
      final admins = await _getAdminUsers();
      if (admins.isEmpty) return;

      await _sendNotificationToUsers(
        users: admins,
        title: 'New Support Ticket',
        body: 'New ticket "${ticket.title}" created by ${ticket.lecturerName}',
        data: {
          'type': 'support_ticket',
          'action': 'created',
          'ticketId': ticket.ticketId,
          'priority': ticket.priority.name,
        },
      );
    } catch (e) {
      print('Error notifying admins about new ticket: $e');
    }
  }

  /// Notify admins about support ticket update
  static Future<void> notifyAdminsAboutTicketUpdate(SupportTicketModel ticket) async {
    try {
      final admins = await _getAdminUsers();
      if (admins.isEmpty) return;

      await _sendNotificationToUsers(
        users: admins,
        title: 'Support Ticket Updated',
        body: 'Ticket "${ticket.title}" was updated by ${ticket.lecturerName}',
        data: {
          'type': 'support_ticket',
          'action': 'updated',
          'ticketId': ticket.ticketId,
          'status': ticket.status.name,
        },
      );
    } catch (e) {
      print('Error notifying admins about ticket update: $e');
    }
  }

  /// Notify admins about new reservation
  static Future<void> notifyAdminsAboutNewReservation(ReservationModel reservation) async {
    try {
      final admins = await _getAdminUsers();
      if (admins.isEmpty) return;

      await _sendNotificationToUsers(
        users: admins,
        title: 'New Reservation',
        body: '${reservation.lecturerName} reserved ${reservation.classroomName} on ${reservation.formattedDate}',
        data: {
          'type': 'reservation',
          'action': 'created',
          'reservationId': reservation.id,
          'classroomName': reservation.classroomName,
          'date': reservation.formattedDate,
        },
      );
    } catch (e) {
      print('Error notifying admins about new reservation: $e');
    }
  }

  /// Notify admins about reservation update
  static Future<void> notifyAdminsAboutReservationUpdate(ReservationModel reservation) async {
    try {
      final admins = await _getAdminUsers();
      if (admins.isEmpty) return;

      await _sendNotificationToUsers(
        users: admins,
        title: 'Reservation Updated',
        body: '${reservation.lecturerName} updated reservation for ${reservation.classroomName}',
        data: {
          'type': 'reservation',
          'action': 'updated',
          'reservationId': reservation.id,
          'classroomName': reservation.classroomName,
          'date': reservation.formattedDate,
        },
      );
    } catch (e) {
      print('Error notifying admins about reservation update: $e');
    }
  }

  /// Handle foreground notifications
  static void handleForegroundNotification() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Received foreground notification: ${message.notification?.title}');
      // You can show in-app notification UI here if needed
    });
  }

  /// Handle notification tap when app is in background
  static void handleNotificationTap() {
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Notification tapped: ${message.data}');
      // Handle navigation based on notification data
      _handleNotificationNavigation(message.data);
    });
  }

  /// Handle notification when app is opened from terminated state
  static Future<void> handleInitialNotification() async {
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      print('App opened from notification: ${initialMessage.data}');
      _handleNotificationNavigation(initialMessage.data);
    }
  }

  /// Navigate based on notification data
  static void _handleNotificationNavigation(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    
    switch (type) {
      case 'support_ticket':
        // Navigate to support tickets screen or specific ticket
        break;
      case 'reservation':
        // Navigate to reservations screen or specific reservation
        break;
      default:
        // Handle other notification types
        break;
    }
  }
}
