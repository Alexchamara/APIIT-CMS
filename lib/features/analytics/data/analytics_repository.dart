import 'package:apiit_cms/features/analytics/domain/models/analytics_data.dart';
import 'package:apiit_cms/features/auth/domain/models/user_model.dart';
import 'package:apiit_cms/features/class/domain/models/class_model.dart';
import 'package:apiit_cms/features/reservarions/domain/models/reservation_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AnalyticsRepository {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get comprehensive analytics data
  static Future<AnalyticsData> getAnalyticsData() async {
    try {
      // Fetch all data in parallel for better performance
      final results = await Future.wait([
        _getClassroomAnalytics(),
        _getReservationAnalytics(),
        _getUserAnalytics(),
      ]);

      return AnalyticsData(
        classrooms: results[0] as ClassroomAnalytics,
        reservations: results[1] as ReservationAnalytics,
        users: results[2] as UserAnalytics,
      );
    } catch (e) {
      throw Exception('Failed to fetch analytics data: $e');
    }
  }

  /// Get classroom analytics
  static Future<ClassroomAnalytics> _getClassroomAnalytics() async {
    final querySnapshot = await _firestore
        .collection('classrooms')
        .get();

    final classrooms = querySnapshot.docs
        .map((doc) => ClassroomModel.fromMap(doc.data()))
        .toList();

    // Calculate basic counts
    int available = 0;
    int unavailable = 0;
    int maintenance = 0;
    final typeCount = <String, int>{};
    final floorCount = <String, int>{};
    int totalCapacity = 0;

    for (final classroom in classrooms) {
      // Availability status
      if (classroom.isAvailable) {
        if (classroom.maintenanceStart != null && 
            classroom.maintenanceEnd != null &&
            DateTime.now().isAfter(classroom.maintenanceStart!) &&
            DateTime.now().isBefore(classroom.maintenanceEnd!)) {
          maintenance++;
        } else {
          available++;
        }
      } else {
        unavailable++;
      }

      // Type distribution
      final typeName = _getClassroomTypeName(classroom.type);
      typeCount[typeName] = (typeCount[typeName] ?? 0) + 1;

      // Floor distribution
      floorCount[classroom.floor] = (floorCount[classroom.floor] ?? 0) + 1;

      // Capacity calculation
      totalCapacity += classroom.capacity;
    }

    final averageCapacity = classrooms.isNotEmpty 
        ? totalCapacity / classrooms.length 
        : 0.0;

    return ClassroomAnalytics(
      totalClassrooms: classrooms.length,
      availableClassrooms: available,
      unavailableClassrooms: unavailable,
      maintenanceClassrooms: maintenance,
      classroomsByType: typeCount,
      classroomsByFloor: floorCount,
      averageCapacity: averageCapacity,
      totalCapacity: totalCapacity,
    );
  }

  /// Get reservation analytics
  static Future<ReservationAnalytics> _getReservationAnalytics() async {
    final querySnapshot = await _firestore
        .collection('reservations')
        .get();

    final reservations = querySnapshot.docs
        .map((doc) => ReservationModel.fromMap(doc.data()))
        .toList();

    // Calculate basic counts
    int approved = 0;
    int pending = 0;
    int cancelled = 0;
    final typeCount = <String, int>{};
    final monthCount = <String, int>{};
    final classroomCount = <String, int>{};
    final lecturerCount = <String, int>{};

    for (final reservation in reservations) {
      // Status counts
      if (reservation.isCancelled) {
        cancelled++;
      } else if (reservation.isApproved) {
        approved++;
      } else {
        pending++;
      }

      // Type distribution
      final typeName = _getReservationTypeName(reservation.type);
      typeCount[typeName] = (typeCount[typeName] ?? 0) + 1;

      // Monthly distribution
      final monthKey = '${reservation.date.year}-${reservation.date.month.toString().padLeft(2, '0')}';
      monthCount[monthKey] = (monthCount[monthKey] ?? 0) + 1;

      // Classroom usage
      classroomCount[reservation.classroomName] = 
          (classroomCount[reservation.classroomName] ?? 0) + 1;

      // Lecturer activity
      lecturerCount[reservation.lecturerName] = 
          (lecturerCount[reservation.lecturerName] ?? 0) + 1;
    }

    // Calculate average reservations per day (last 30 days)
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    final recentReservations = reservations.where(
      (r) => r.date.isAfter(thirtyDaysAgo)
    ).length;
    final averagePerDay = recentReservations / 30.0;

    return ReservationAnalytics(
      totalReservations: reservations.length,
      approvedReservations: approved,
      pendingReservations: pending,
      cancelledReservations: cancelled,
      reservationsByType: typeCount,
      reservationsByMonth: monthCount,
      mostBookedClassrooms: _getTopEntries(classroomCount, 5),
      activeLecturers: _getTopEntries(lecturerCount, 5),
      averageReservationsPerDay: averagePerDay,
    );
  }

  /// Get user analytics
  static Future<UserAnalytics> _getUserAnalytics() async {
    final querySnapshot = await _firestore
        .collection('users')
        .get();

    final users = querySnapshot.docs
        .map((doc) => UserModel.fromMap(doc.data()))
        .toList();

    // Calculate basic counts
    int admins = 0;
    int lecturers = 0;
    int active = 0;
    int inactive = 0;
    final monthlyRegistrations = <String, int>{};

    for (final user in users) {
      // User type counts
      if (user.userType == UserType.admin) {
        admins++;
      } else {
        lecturers++;
      }

      // Activity status
      if (user.isActive) {
        active++;
      } else {
        inactive++;
      }

      // Monthly registrations
      final monthKey = '${user.createdAt.year}-${user.createdAt.month.toString().padLeft(2, '0')}';
      monthlyRegistrations[monthKey] = (monthlyRegistrations[monthKey] ?? 0) + 1;
    }

    // Get most active user (by reservations)
    final reservationSnapshot = await _firestore
        .collection('reservations')
        .get();

    final lecturerReservationCount = <String, int>{};
    for (final doc in reservationSnapshot.docs) {
      final data = doc.data();
      final lecturerName = data['lecturerName'] as String;
      lecturerReservationCount[lecturerName] = 
          (lecturerReservationCount[lecturerName] ?? 0) + 1;
    }

    String mostActiveUser = 'None';
    int mostActiveCount = 0;
    if (lecturerReservationCount.isNotEmpty) {
      final sorted = lecturerReservationCount.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      mostActiveUser = sorted.first.key;
      mostActiveCount = sorted.first.value;
    }

    return UserAnalytics(
      totalUsers: users.length,
      adminUsers: admins,
      lecturerUsers: lecturers,
      activeUsers: active,
      inactiveUsers: inactive,
      userRegistrationsByMonth: monthlyRegistrations,
      mostActiveUser: mostActiveUser,
      mostActiveUserReservations: mostActiveCount,
    );
  }

  /// Helper method to get classroom type name
  static String _getClassroomTypeName(ClassroomType type) {
    switch (type) {
      case ClassroomType.lab:
        return 'Lab';
      case ClassroomType.classroom:
        return 'Classroom';
      case ClassroomType.auditorium:
        return 'Auditorium';
    }
  }

  /// Helper method to get reservation type name
  static String _getReservationTypeName(ReservationType type) {
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

  /// Helper method to get top entries from a map
  static Map<String, int> _getTopEntries(Map<String, int> data, int limit) {
    final sorted = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final result = <String, int>{};
    for (int i = 0; i < sorted.length && i < limit; i++) {
      result[sorted[i].key] = sorted[i].value;
    }
    return result;
  }
}
