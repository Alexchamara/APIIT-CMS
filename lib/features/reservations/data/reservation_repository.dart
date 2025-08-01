import 'package:apiit_cms/features/reservations/domain/models/reservation_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:apiit_cms/shared/services/notification_service.dart';

class ReservationRepository {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'reservations';

  // Create a new reservation
  static Future<void> createReservation(ReservationModel reservation) async {
    try {
      final docRef = _firestore.collection(_collection).doc();
      final newReservation = reservation.copyWith(
        id: docRef.id,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await docRef.set(newReservation.toMap());
      
      // Send notification to admins
      NotificationService.notifyAdminsAboutNewReservation(newReservation);
    } catch (e) {
      throw Exception('Failed to create reservation: $e');
    }
  }

  // Get all reservations
  static Future<List<ReservationModel>> getAllReservations() async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .orderBy('date', descending: false)
          .get();

      return querySnapshot.docs
          .map((doc) => ReservationModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get reservations: $e');
    }
  }

  // Get reservations by lecturer ID
  static Future<List<ReservationModel>> getReservationsByLecturer(
      String lecturerId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('lecturerId', isEqualTo: lecturerId)
          .orderBy('date', descending: false)
          .get();

      return querySnapshot.docs
          .map((doc) => ReservationModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get lecturer reservations: $e');
    }
  }

  // Get reservations by classroom ID
  static Future<List<ReservationModel>> getReservationsByClassroom(
      String classroomId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('classroomId', isEqualTo: classroomId)
          .orderBy('date', descending: false)
          .get();

      return querySnapshot.docs
          .map((doc) => ReservationModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get classroom reservations: $e');
    }
  }

  // Get reservations by date
  static Future<List<ReservationModel>> getReservationsByDate(
      DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final querySnapshot = await _firestore
          .collection(_collection)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .orderBy('date')
          .get();

      return querySnapshot.docs
          .map((doc) => ReservationModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get reservations by date: $e');
    }
  }

  // Update reservation
  static Future<void> updateReservation(ReservationModel reservation) async {
    try {
      final updatedReservation = reservation.copyWith(
        updatedAt: DateTime.now(),
      );
      await _firestore
          .collection(_collection)
          .doc(reservation.id)
          .update(updatedReservation.toMap());
      
      // Send notification to admins
      NotificationService.notifyAdminsAboutReservationUpdate(updatedReservation);
    } catch (e) {
      throw Exception('Failed to update reservation: $e');
    }
  }

  // Delete reservation
  static Future<void> deleteReservation(String reservationId) async {
    try {
      await _firestore.collection(_collection).doc(reservationId).delete();
    } catch (e) {
      throw Exception('Failed to delete reservation: $e');
    }
  }

  // Check for conflicts (same classroom, date, and overlapping time slots)
  static Future<List<ReservationModel>> checkConflicts(
    String classroomId,
    DateTime date,
    List<TimeSlot> timeSlots,
    {String? excludeReservationId}
  ) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final querySnapshot = await _firestore
          .collection(_collection)
          .where('classroomId', isEqualTo: classroomId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .get();

      final reservations = querySnapshot.docs
          .map((doc) => ReservationModel.fromMap(doc.data()))
          .where((reservation) => 
              excludeReservationId == null || reservation.id != excludeReservationId)
          .toList();

      // Check for time slot conflicts
      final conflicts = <ReservationModel>[];
      for (final reservation in reservations) {
        for (final newSlot in timeSlots) {
          for (final existingSlot in reservation.timeSlots) {
            if (_slotsOverlap(newSlot, existingSlot)) {
              conflicts.add(reservation);
              break;
            }
          }
          if (conflicts.contains(reservation)) break;
        }
      }

      return conflicts;
    } catch (e) {
      throw Exception('Failed to check conflicts: $e');
    }
  }

  // Helper method to check if two time slots overlap
  static bool _slotsOverlap(TimeSlot slot1, TimeSlot slot2) {
    final start1 = _parseTime(slot1.startTime);
    final end1 = _parseTime(slot1.endTime);
    final start2 = _parseTime(slot2.startTime);
    final end2 = _parseTime(slot2.endTime);

    return start1 < end2 && start2 < end1;
  }

  // Helper method to parse time string (HH:mm) to minutes
  static int _parseTime(String timeString) {
    final parts = timeString.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  // Get reservations stream for real-time updates
  static Stream<List<ReservationModel>> getReservationsStream() {
    return _firestore
        .collection(_collection)
        .orderBy('date', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ReservationModel.fromMap(doc.data()))
            .toList());
  }

  // Search reservations
  static Future<List<ReservationModel>> searchReservations(String query) async {
    try {
      final allReservations = await getAllReservations();
      final lowerQuery = query.toLowerCase();

      return allReservations.where((reservation) {
        return reservation.lecturerName.toLowerCase().contains(lowerQuery) ||
            reservation.classroomName.toLowerCase().contains(lowerQuery) ||
            reservation.typeLabel.toLowerCase().contains(lowerQuery) ||
            reservation.description?.toLowerCase().contains(lowerQuery) == true;
      }).toList();
    } catch (e) {
      throw Exception('Failed to search reservations: $e');
    }
  }
}
