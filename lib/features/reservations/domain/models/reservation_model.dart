import 'package:cloud_firestore/cloud_firestore.dart';

enum ReservationType {
  lecture,
  view,
  meeting,
  exam,
  discussion,
}

class TimeSlot {
  final String startTime;
  final String endTime;

  const TimeSlot({
    required this.startTime,
    required this.endTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'startTime': startTime,
      'endTime': endTime,
    };
  }

  factory TimeSlot.fromMap(Map<String, dynamic> map) {
    return TimeSlot(
      startTime: map['startTime'] ?? '',
      endTime: map['endTime'] ?? '',
    );
  }

  @override
  String toString() => '$startTime - $endTime';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimeSlot &&
          runtimeType == other.runtimeType &&
          startTime == other.startTime &&
          endTime == other.endTime;

  @override
  int get hashCode => startTime.hashCode ^ endTime.hashCode;
}

class ReservationModel {
  final String id;
  final String lecturerId;
  final String lecturerName;
  final String classroomId;
  final String classroomName;
  final DateTime date;
  final ReservationType type;
  final List<TimeSlot> timeSlots;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ReservationModel({
    required this.id,
    required this.lecturerId,
    required this.lecturerName,
    required this.classroomId,
    required this.classroomName,
    required this.date,
    required this.type,
    required this.timeSlots,
    this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'lecturerId': lecturerId,
      'lecturerName': lecturerName,
      'classroomId': classroomId,
      'classroomName': classroomName,
      'date': Timestamp.fromDate(date),
      'type': type.name,
      'timeSlots': timeSlots.map((slot) => slot.toMap()).toList(),
      'description': description,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory ReservationModel.fromMap(Map<String, dynamic> map) {
    return ReservationModel(
      id: map['id'] ?? '',
      lecturerId: map['lecturerId'] ?? '',
      lecturerName: map['lecturerName'] ?? '',
      classroomId: map['classroomId'] ?? '',
      classroomName: map['classroomName'] ?? '',
      date: (map['date'] as Timestamp).toDate(),
      type: ReservationType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => ReservationType.lecture,
      ),
      timeSlots: (map['timeSlots'] as List<dynamic>?)
              ?.map((slot) => TimeSlot.fromMap(slot as Map<String, dynamic>))
              .toList() ??
          [],
      description: map['description'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  ReservationModel copyWith({
    String? id,
    String? lecturerId,
    String? lecturerName,
    String? classroomId,
    String? classroomName,
    DateTime? date,
    ReservationType? type,
    List<TimeSlot>? timeSlots,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ReservationModel(
      id: id ?? this.id,
      lecturerId: lecturerId ?? this.lecturerId,
      lecturerName: lecturerName ?? this.lecturerName,
      classroomId: classroomId ?? this.classroomId,
      classroomName: classroomName ?? this.classroomName,
      date: date ?? this.date,
      type: type ?? this.type,
      timeSlots: timeSlots ?? this.timeSlots,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get formattedDate {
    return '${date.day}/${date.month}/${date.year}';
  }

  String get formattedTimeSlots {
    return timeSlots.map((slot) => slot.toString()).join(', ');
  }

  String get typeLabel {
    switch (type) {
      case ReservationType.lecture:
        return 'Lecture';
      case ReservationType.view:
        return 'View';
      case ReservationType.meeting:
        return 'Meeting';
      case ReservationType.exam:
        return 'Exam';
      case ReservationType.discussion:
        return 'Discussion';
    }
  }

  String get statusLabel {
    return 'Active';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReservationModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
