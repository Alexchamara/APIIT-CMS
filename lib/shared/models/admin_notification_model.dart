import 'package:cloud_firestore/cloud_firestore.dart';

class AdminNotificationModel {
  final String id;
  final String title;
  final String body;
  final String type; // 'support_ticket', 'reservation'
  final String
  action; // 'created', 'updated', 'status_updated', 'message_added'
  final Map<String, String> data;
  final DateTime createdAt;
  final String status; // 'pending', 'sent', 'failed'
  final DateTime? sentAt;
  final String? error;

  AdminNotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.action,
    required this.data,
    required this.createdAt,
    required this.status,
    this.sentAt,
    this.error,
  });

  factory AdminNotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return AdminNotificationModel(
      id: doc.id,
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      type: data['data']?['type'] ?? '',
      action: data['data']?['action'] ?? '',
      data: Map<String, String>.from(data['data'] ?? {}),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      status: data['status'] ?? 'pending',
      sentAt: data['sentAt'] != null
          ? (data['sentAt'] as Timestamp).toDate()
          : null,
      error: data['error'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'body': body,
      'data': data,
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status,
      if (sentAt != null) 'sentAt': Timestamp.fromDate(sentAt!),
      if (error != null) 'error': error,
    };
  }

  String get formattedTime {
    return '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';
  }

  String get formattedDate {
    return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }

  bool get isSuccess => status == 'sent';
  bool get isFailed => status == 'failed';
  bool get isPending => status == 'pending';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminNotificationModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
