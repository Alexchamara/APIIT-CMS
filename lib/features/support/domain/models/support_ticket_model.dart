import 'package:cloud_firestore/cloud_firestore.dart';

enum TicketStatus {
  pending,
  resolved,
  closed,
}

enum TicketPriority {
  low,
  medium,
  high,
  urgent,
}

class SupportTicketModel {
  final String ticketId;
  final String lecturerId;
  final String lecturerName;
  final String title;
  final String description;
  final TicketStatus status;
  final TicketPriority priority;
  final List<TicketMessage> messages;
  final DateTime createdAt;
  final DateTime updatedAt;

  SupportTicketModel({
    required this.ticketId,
    required this.lecturerId,
    required this.lecturerName,
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
    required this.messages,
    required this.createdAt,
    required this.updatedAt,
  });

  // Convert from Firestore document
  factory SupportTicketModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return SupportTicketModel(
      ticketId: doc.id,
      lecturerId: data['lecturerId'] ?? '',
      lecturerName: data['lecturerName'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      status: TicketStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => TicketStatus.pending,
      ),
      priority: TicketPriority.values.firstWhere(
        (e) => e.name == data['priority'],
        orElse: () => TicketPriority.medium,
      ),
      messages: (data['messages'] as List<dynamic>?)
          ?.map((message) => TicketMessage.fromMap(message))
          .toList() ?? [],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'lecturerId': lecturerId,
      'lecturerName': lecturerName,
      'title': title,
      'description': description,
      'status': status.name,
      'priority': priority.name,
      'messages': messages.map((message) => message.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Helper methods
  String get statusLabel {
    switch (status) {
      case TicketStatus.pending:
        return 'Pending';
      case TicketStatus.resolved:
        return 'Resolved';
      case TicketStatus.closed:
        return 'Closed';
    }
  }

  String get priorityLabel {
    switch (priority) {
      case TicketPriority.low:
        return 'Low';
      case TicketPriority.medium:
        return 'Medium';
      case TicketPriority.high:
        return 'High';
      case TicketPriority.urgent:
        return 'Urgent';
    }
  }

  String get formattedCreatedAt {
    return '${createdAt.day}/${createdAt.month}/${createdAt.year} ${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';
  }

  String get formattedUpdatedAt {
    return '${updatedAt.day}/${updatedAt.month}/${updatedAt.year} ${updatedAt.hour.toString().padLeft(2, '0')}:${updatedAt.minute.toString().padLeft(2, '0')}';
  }

  // Copy with method
  SupportTicketModel copyWith({
    String? ticketId,
    String? lecturerId,
    String? lecturerName,
    String? title,
    String? description,
    TicketStatus? status,
    TicketPriority? priority,
    List<TicketMessage>? messages,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SupportTicketModel(
      ticketId: ticketId ?? this.ticketId,
      lecturerId: lecturerId ?? this.lecturerId,
      lecturerName: lecturerName ?? this.lecturerName,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      messages: messages ?? this.messages,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class TicketMessage {
  final String messageId;
  final String senderId;
  final String senderName;
  final String message;
  final bool isFromAdmin;
  final DateTime createdAt;

  TicketMessage({
    required this.messageId,
    required this.senderId,
    required this.senderName,
    required this.message,
    required this.isFromAdmin,
    required this.createdAt,
  });

  // Convert from Map
  factory TicketMessage.fromMap(Map<String, dynamic> data) {
    return TicketMessage(
      messageId: data['messageId'] ?? '',
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? '',
      message: data['message'] ?? '',
      isFromAdmin: data['isFromAdmin'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  // Convert to Map
  Map<String, dynamic> toMap() {
    return {
      'messageId': messageId,
      'senderId': senderId,
      'senderName': senderName,
      'message': message,
      'isFromAdmin': isFromAdmin,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
