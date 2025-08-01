class AnalyticsData {
  final ClassroomAnalytics classrooms;
  final ReservationAnalytics reservations;
  final UserAnalytics users;

  AnalyticsData({
    required this.classrooms,
    required this.reservations,
    required this.users,
  });
}

class ClassroomAnalytics {
  final int totalClassrooms;
  final int availableClassrooms;
  final int unavailableClassrooms;
  final int maintenanceClassrooms;
  final Map<String, int> classroomsByType;
  final Map<String, int> classroomsByFloor;
  final double averageCapacity;
  final int totalCapacity;

  ClassroomAnalytics({
    required this.totalClassrooms,
    required this.availableClassrooms,
    required this.unavailableClassrooms,
    required this.maintenanceClassrooms,
    required this.classroomsByType,
    required this.classroomsByFloor,
    required this.averageCapacity,
    required this.totalCapacity,
  });

  double get availabilityRate => totalClassrooms > 0 
      ? (availableClassrooms / totalClassrooms) * 100 
      : 0;
}

class ReservationAnalytics {
  final int totalReservations;
  final int approvedReservations;
  final int pendingReservations;
  final int cancelledReservations;
  final Map<String, int> reservationsByType;
  final Map<String, int> reservationsByMonth;
  final Map<String, int> mostBookedClassrooms;
  final Map<String, int> activeLecturers;
  final double averageReservationsPerDay;

  ReservationAnalytics({
    required this.totalReservations,
    required this.approvedReservations,
    required this.pendingReservations,
    required this.cancelledReservations,
    required this.reservationsByType,
    required this.reservationsByMonth,
    required this.mostBookedClassrooms,
    required this.activeLecturers,
    required this.averageReservationsPerDay,
  });

  double get approvalRate => totalReservations > 0 
      ? (approvedReservations / totalReservations) * 100 
      : 0;

  double get cancellationRate => totalReservations > 0 
      ? (cancelledReservations / totalReservations) * 100 
      : 0;
}

class UserAnalytics {
  final int totalUsers;
  final int adminUsers;
  final int lecturerUsers;
  final int activeUsers;
  final int inactiveUsers;
  final Map<String, int> userRegistrationsByMonth;
  final String mostActiveUser;
  final int mostActiveUserReservations;

  UserAnalytics({
    required this.totalUsers,
    required this.adminUsers,
    required this.lecturerUsers,
    required this.activeUsers,
    required this.inactiveUsers,
    required this.userRegistrationsByMonth,
    required this.mostActiveUser,
    required this.mostActiveUserReservations,
  });

  double get adminPercentage => totalUsers > 0 
      ? (adminUsers / totalUsers) * 100 
      : 0;

  double get lecturerPercentage => totalUsers > 0 
      ? (lecturerUsers / totalUsers) * 100 
      : 0;

  double get activeUserRate => totalUsers > 0 
      ? (activeUsers / totalUsers) * 100 
      : 0;
}
