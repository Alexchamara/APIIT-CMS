import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:apiit_cms/shared/models/admin_notification_model.dart';

class AdminNotificationRepository {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'notifications';

  /// Get all notifications stream (admin only)
  static Stream<List<AdminNotificationModel>> getAllNotifications() {
    return _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .limit(100) // Limit to recent 100 notifications
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => AdminNotificationModel.fromFirestore(doc))
              .toList(),
        );
  }

  /// Get notifications by type
  static Stream<List<AdminNotificationModel>> getNotificationsByType(
    String type,
  ) {
    return _firestore
        .collection(_collection)
        .where('data.type', isEqualTo: type)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => AdminNotificationModel.fromFirestore(doc))
              .toList(),
        );
  }

  /// Get notifications by status
  static Stream<List<AdminNotificationModel>> getNotificationsByStatus(
    String status,
  ) {
    return _firestore
        .collection(_collection)
        .where('status', isEqualTo: status)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => AdminNotificationModel.fromFirestore(doc))
              .toList(),
        );
  }

  /// Get recent notifications (last 24 hours)
  static Stream<List<AdminNotificationModel>> getRecentNotifications() {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));

    return _firestore
        .collection(_collection)
        .where('createdAt', isGreaterThan: Timestamp.fromDate(yesterday))
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => AdminNotificationModel.fromFirestore(doc))
              .toList(),
        );
  }

  /// Get notification statistics
  static Future<Map<String, int>> getNotificationStats() async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);

      // Get today's notifications
      final todaySnapshot = await _firestore
          .collection(_collection)
          .where(
            'createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
          )
          .get();

      final sentToday = todaySnapshot.docs
          .where((doc) => doc.data()['status'] == 'sent')
          .length;

      final failedToday = todaySnapshot.docs
          .where((doc) => doc.data()['status'] == 'failed')
          .length;

      final pendingToday = todaySnapshot.docs
          .where((doc) => doc.data()['status'] == 'pending')
          .length;

      // Get this week's notifications
      final startOfWeek = startOfDay.subtract(
        Duration(days: today.weekday - 1),
      );
      final weekSnapshot = await _firestore
          .collection(_collection)
          .where(
            'createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfWeek),
          )
          .get();

      return {
        'today_total': todaySnapshot.docs.length,
        'today_sent': sentToday,
        'today_failed': failedToday,
        'today_pending': pendingToday,
        'week_total': weekSnapshot.docs.length,
      };
    } catch (e) {
      print('Error getting notification stats: $e');
      return {};
    }
  }

  /// Delete old notifications (older than 30 days)
  static Future<void> cleanupOldNotifications() async {
    try {
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));

      final oldNotifications = await _firestore
          .collection(_collection)
          .where('createdAt', isLessThan: Timestamp.fromDate(thirtyDaysAgo))
          .get();

      final batch = _firestore.batch();
      for (final doc in oldNotifications.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      print('Cleaned up ${oldNotifications.docs.length} old notifications');
    } catch (e) {
      print('Error cleaning up old notifications: $e');
    }
  }

  /// Mark notification as read/acknowledged
  static Future<void> acknowledgeNotification(String notificationId) async {
    try {
      await _firestore.collection(_collection).doc(notificationId).update({
        'acknowledged': true,
        'acknowledgedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error acknowledging notification: $e');
    }
  }

  /// Retry failed notification
  static Future<void> retryFailedNotification(String notificationId) async {
    try {
      await _firestore.collection(_collection).doc(notificationId).update({
        'status': 'pending',
        'retryCount': FieldValue.increment(1),
        'retriedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error retrying notification: $e');
    }
  }
}
