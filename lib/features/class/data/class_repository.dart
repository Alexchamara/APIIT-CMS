import 'package:apiit_cms/features/class/domain/models/class_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ClassroomRepository {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _classroomsCollection = 'classrooms';

  // Create a new classroom
  static Future<ClassroomModel> createClassroom(ClassroomModel classroomModel) async {
    try {
      final docRef = _firestore.collection(_classroomsCollection).doc();
      final newClassroom = classroomModel.copyWith(
        id: docRef.id,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      await docRef.set(newClassroom.toMap());
      return newClassroom;
    } catch (e) {
      throw Exception('Failed to create classroom: $e');
    }
  }

  // Get all classrooms
  static Future<List<ClassroomModel>> getAllClassrooms() async {
    try {
      final querySnapshot = await _firestore
          .collection(_classroomsCollection)
          .orderBy('roomName')
          .get();

      return querySnapshot.docs
          .map((doc) => ClassroomModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch classrooms: $e');
    }
  }

  // Get classrooms as a stream for real-time updates
  static Stream<List<ClassroomModel>> getClassroomsStream() {
    return _firestore
        .collection(_classroomsCollection)
        .orderBy('roomName')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ClassroomModel.fromMap(doc.data()))
            .toList());
  }

  // Get a specific classroom by ID
  static Future<ClassroomModel?> getClassroomById(String classroomId) async {
    try {
      final doc = await _firestore
          .collection(_classroomsCollection)
          .doc(classroomId)
          .get();

      if (doc.exists && doc.data() != null) {
        return ClassroomModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch classroom: $e');
    }
  }

  // Update an existing classroom
  static Future<ClassroomModel> updateClassroom(ClassroomModel classroomModel) async {
    try {
      final updatedClassroom = classroomModel.copyWith(updatedAt: DateTime.now());
      
      await _firestore
          .collection(_classroomsCollection)
          .doc(classroomModel.id)
          .update(updatedClassroom.toMap());
          
      return updatedClassroom;
    } catch (e) {
      throw Exception('Failed to update classroom: $e');
    }
  }

  // Delete a classroom
  static Future<void> deleteClassroom(String classroomId) async {
    try {
      await _firestore
          .collection(_classroomsCollection)
          .doc(classroomId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete classroom: $e');
    }
  }

  // Search classrooms by room name
  static Future<List<ClassroomModel>> searchClassrooms(String searchQuery) async {
    try {
      if (searchQuery.isEmpty) {
        return getAllClassrooms();
      }

      final querySnapshot = await _firestore
          .collection(_classroomsCollection)
          .where('roomName', isGreaterThanOrEqualTo: searchQuery.toUpperCase())
          .where('roomName', isLessThanOrEqualTo: '${searchQuery.toUpperCase()}\uf8ff')
          .get();

      return querySnapshot.docs
          .map((doc) => ClassroomModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to search classrooms: $e');
    }
  }

  // Get classrooms by type
  static Future<List<ClassroomModel>> getClassroomsByType(ClassroomType type) async {
    try {
      final querySnapshot = await _firestore
          .collection(_classroomsCollection)
          .where('type', isEqualTo: type.name)
          .orderBy('roomName')
          .get();

      return querySnapshot.docs
          .map((doc) => ClassroomModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch classrooms by type: $e');
    }
  }

  // Get available classrooms
  static Future<List<ClassroomModel>> getAvailableClassrooms() async {
    try {
      final querySnapshot = await _firestore
          .collection(_classroomsCollection)
          .where('isAvailable', isEqualTo: true)
          .orderBy('roomName')
          .get();

      return querySnapshot.docs
          .map((doc) => ClassroomModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch available classrooms: $e');
    }
  }

  // Get classrooms by floor
  static Future<List<ClassroomModel>> getClassroomsByFloor(String floor) async {
    try {
      final querySnapshot = await _firestore
          .collection(_classroomsCollection)
          .where('floor', isEqualTo: floor)
          .orderBy('roomName')
          .get();

      return querySnapshot.docs
          .map((doc) => ClassroomModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch classrooms by floor: $e');
    }
  }

  // Toggle classroom availability
  static Future<ClassroomModel> toggleClassroomAvailability(String classroomId) async {
    try {
      final classroomModel = await getClassroomById(classroomId);
      if (classroomModel == null) {
        throw Exception('Classroom not found');
      }

      final updatedClassroom = classroomModel.copyWith(
        isAvailable: !classroomModel.isAvailable,
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection(_classroomsCollection)
          .doc(classroomId)
          .update({'isAvailable': updatedClassroom.isAvailable, 'updatedAt': Timestamp.fromDate(updatedClassroom.updatedAt)});

      return updatedClassroom;
    } catch (e) {
      throw Exception('Failed to toggle classroom availability: $e');
    }
  }

  // Add blackout days to a classroom
  static Future<ClassroomModel> addBlackoutDays(String classroomId, List<DateTime> blackoutDays) async {
    try {
      final classroomModel = await getClassroomById(classroomId);
      if (classroomModel == null) {
        throw Exception('Classroom not found');
      }

      final updatedBlackoutDays = [...classroomModel.blackoutDays, ...blackoutDays];
      final updatedClassroom = classroomModel.copyWith(
        blackoutDays: updatedBlackoutDays,
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection(_classroomsCollection)
          .doc(classroomId)
          .update({
        'blackoutDays': updatedBlackoutDays.map((date) => Timestamp.fromDate(date)).toList(),
        'updatedAt': Timestamp.fromDate(updatedClassroom.updatedAt),
      });

      return updatedClassroom;
    } catch (e) {
      throw Exception('Failed to add blackout days: $e');
    }
  }

  // Set maintenance period for a classroom
  static Future<ClassroomModel> setMaintenancePeriod(
    String classroomId,
    DateTime? maintenanceStart,
    DateTime? maintenanceEnd,
  ) async {
    try {
      final classroomModel = await getClassroomById(classroomId);
      if (classroomModel == null) {
        throw Exception('Classroom not found');
      }

      final updatedClassroom = classroomModel.copyWith(
        maintenanceStart: maintenanceStart,
        maintenanceEnd: maintenanceEnd,
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection(_classroomsCollection)
          .doc(classroomId)
          .update({
        'maintenanceStart': maintenanceStart != null ? Timestamp.fromDate(maintenanceStart) : null,
        'maintenanceEnd': maintenanceEnd != null ? Timestamp.fromDate(maintenanceEnd) : null,
        'updatedAt': Timestamp.fromDate(updatedClassroom.updatedAt),
      });

      return updatedClassroom;
    } catch (e) {
      throw Exception('Failed to set maintenance period: $e');
    }
  }
}
