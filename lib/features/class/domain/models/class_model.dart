import 'package:cloud_firestore/cloud_firestore.dart';

enum ClassroomType { lab, classroom, auditorium }

class ClassroomModel {
  final String id;
  final String roomName;
  final String floor;
  final ClassroomType type;
  final bool isAvailable;
  final int capacity;
  final int openingHour; // 24-hour format (e.g., 8 for 8 AM)
  final int closingHour; // 24-hour format (e.g., 17 for 5 PM)
  final List<DateTime> blackoutDays;
  final DateTime? maintenanceStart;
  final DateTime? maintenanceEnd;
  final DateTime createdAt;
  final DateTime updatedAt;

  ClassroomModel({
    required this.id,
    required this.roomName,
    required this.floor,
    required this.type,
    this.isAvailable = true,
    required this.capacity,
    this.openingHour = 8,
    this.closingHour = 17,
    this.blackoutDays = const [],
    this.maintenanceStart,
    this.maintenanceEnd,
    required this.createdAt,
    required this.updatedAt,
  });

  // Factory constructor to create ClassroomModel from Firestore document
  factory ClassroomModel.fromMap(Map<String, dynamic> map) {
    return ClassroomModel(
      id: map['id'] ?? '',
      roomName: map['roomName'] ?? '',
      floor: map['floor'] ?? '',
      type: ClassroomType.values.firstWhere(
        (type) => type.name == map['type'],
        orElse: () => ClassroomType.classroom,
      ),
      isAvailable: map['isAvailable'] ?? true,
      capacity: map['capacity'] ?? 0,
      openingHour: map['openingHour'] ?? 8,
      closingHour: map['closingHour'] ?? 17,
      blackoutDays: (map['blackoutDays'] as List<dynamic>?)
              ?.map((timestamp) => (timestamp as Timestamp).toDate())
              .toList() ??
          [],
      maintenanceStart: map['maintenanceStart'] != null
          ? (map['maintenanceStart'] as Timestamp).toDate()
          : null,
      maintenanceEnd: map['maintenanceEnd'] != null
          ? (map['maintenanceEnd'] as Timestamp).toDate()
          : null,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  // Convert ClassroomModel to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'roomName': roomName,
      'floor': floor,
      'type': type.name,
      'isAvailable': isAvailable,
      'capacity': capacity,
      'openingHour': openingHour,
      'closingHour': closingHour,
      'blackoutDays': blackoutDays.map((date) => Timestamp.fromDate(date)).toList(),
      'maintenanceStart': maintenanceStart != null 
          ? Timestamp.fromDate(maintenanceStart!) 
          : null,
      'maintenanceEnd': maintenanceEnd != null 
          ? Timestamp.fromDate(maintenanceEnd!) 
          : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Create a copy with updated fields
  ClassroomModel copyWith({
    String? id,
    String? roomName,
    String? floor,
    ClassroomType? type,
    bool? isAvailable,
    int? capacity,
    int? openingHour,
    int? closingHour,
    List<DateTime>? blackoutDays,
    DateTime? maintenanceStart,
    DateTime? maintenanceEnd,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ClassroomModel(
      id: id ?? this.id,
      roomName: roomName ?? this.roomName,
      floor: floor ?? this.floor,
      type: type ?? this.type,
      isAvailable: isAvailable ?? this.isAvailable,
      capacity: capacity ?? this.capacity,
      openingHour: openingHour ?? this.openingHour,
      closingHour: closingHour ?? this.closingHour,
      blackoutDays: blackoutDays ?? this.blackoutDays,
      maintenanceStart: maintenanceStart ?? this.maintenanceStart,
      maintenanceEnd: maintenanceEnd ?? this.maintenanceEnd,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Check if classroom is currently under maintenance
  bool get isUnderMaintenance {
    final now = DateTime.now();
    if (maintenanceStart != null && maintenanceEnd != null) {
      return now.isAfter(maintenanceStart!) && now.isBefore(maintenanceEnd!);
    }
    return false;
  }

  // Check if classroom is currently open based on operating hours
  bool get isCurrentlyOpen {
    final now = DateTime.now();
    final currentHour = now.hour;
    return currentHour >= openingHour && currentHour < closingHour;
  }

  // Check if a specific date is a blackout day
  bool isBlackoutDay(DateTime date) {
    return blackoutDays.any((blackoutDay) =>
        blackoutDay.year == date.year &&
        blackoutDay.month == date.month &&
        blackoutDay.day == date.day);
  }

  // Get formatted operating hours string
  String get operatingHours {
    String formatHour(int hour) {
      if (hour == 0) return '12:00 AM';
      if (hour < 12) return '$hour:00 AM';
      if (hour == 12) return '12:00 PM';
      return '${hour - 12}:00 PM';
    }
    
    return '${formatHour(openingHour)} - ${formatHour(closingHour)}';
  }

  @override
  String toString() {
    return 'ClassroomModel(id: $id, roomName: $roomName, floor: $floor, type: $type, capacity: $capacity, isAvailable: $isAvailable)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ClassroomModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
