import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:apiit_cms/features/support/domain/models/support_ticket_model.dart';
import 'package:apiit_cms/features/auth/data/auth_repository.dart';

class SupportTicketRepository {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'support_tickets';

  // Create a new support ticket
  static Future<String> createTicket({
    required String title,
    required String description,
    required TicketPriority priority,
  }) async {
    try {
      final currentUser = await AuthRepository.getCurrentUserModel();
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final now = DateTime.now();

      // Create the ticket document
      final ticketData = {
        'lecturerId': currentUser.uid,
        'lecturerName': currentUser.displayName,
        'title': title,
        'description': description,
        'status': TicketStatus.pending.name,
        'priority': priority.name,
        'messages': <Map<String, dynamic>>[],
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
      };

      final docRef = await _firestore.collection(_collection).add(ticketData);
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create ticket: $e');
    }
  }

  // Get all tickets (admin only)
  static Stream<List<SupportTicketModel>> getAllTickets() {
    return _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SupportTicketModel.fromFirestore(doc))
            .toList());
  }

  // Get tickets by status (admin only)
  static Stream<List<SupportTicketModel>> getAllTicketsByStatus(TicketStatus status) {
    return _firestore
        .collection(_collection)
        .where('status', isEqualTo: status.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SupportTicketModel.fromFirestore(doc))
            .toList());
  }

  // Get user's own tickets
  static Stream<List<SupportTicketModel>> getUserTickets() async* {
    final currentUser = await AuthRepository.getCurrentUserModel();
    if (currentUser == null) return;

    yield* _firestore
        .collection(_collection)
        .where('lecturerId', isEqualTo: currentUser.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SupportTicketModel.fromFirestore(doc))
            .toList());
  }

  // Get user's tickets by status
  static Stream<List<SupportTicketModel>> getUserTicketsByStatus(TicketStatus status) async* {
    final currentUser = await AuthRepository.getCurrentUserModel();
    if (currentUser == null) return;

    yield* _firestore
        .collection(_collection)
        .where('lecturerId', isEqualTo: currentUser.uid)
        .where('status', isEqualTo: status.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SupportTicketModel.fromFirestore(doc))
            .toList());
  }

  // Get single ticket by ID
  static Future<SupportTicketModel?> getTicketById(String ticketId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(ticketId).get();
      if (doc.exists) {
        return SupportTicketModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get ticket: $e');
    }
  }

  // Add message to ticket
  static Future<void> addMessage({
    required String ticketId,
    required String message,
  }) async {
    try {
      final currentUser = await AuthRepository.getCurrentUserModel();
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final ticketMessage = TicketMessage(
        messageId: DateTime.now().millisecondsSinceEpoch.toString(),
        senderId: currentUser.uid,
        senderName: currentUser.displayName,
        message: message,
        isFromAdmin: currentUser.userType.name == 'admin',
        createdAt: DateTime.now(),
      );

      await _firestore.collection(_collection).doc(ticketId).update({
        'messages': FieldValue.arrayUnion([ticketMessage.toMap()]),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Failed to add message: $e');
    }
  }

  // Update ticket status (admin only)
  static Future<void> updateTicketStatus({
    required String ticketId,
    required TicketStatus status,
  }) async {
    try {
      await _firestore.collection(_collection).doc(ticketId).update({
        'status': status.name,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Failed to update status: $e');
    }
  }

  // Delete ticket (admin only)
  static Future<void> deleteTicket(String ticketId) async {
    try {
      // Delete ticket document
      await _firestore.collection(_collection).doc(ticketId).delete();
    } catch (e) {
      throw Exception('Failed to delete ticket: $e');
    }
  }

  // Search tickets
  static Future<List<SupportTicketModel>> searchTickets({
    required String query,
    bool isAdmin = false,
  }) async {
    try {
      Query firestoreQuery = _firestore.collection(_collection);

      // If not admin, filter by current user
      if (!isAdmin) {
        final currentUser = await AuthRepository.getCurrentUserModel();
        if (currentUser == null) return [];
        firestoreQuery = firestoreQuery.where('lecturerId', isEqualTo: currentUser.uid);
      }

      final snapshot = await firestoreQuery.get();
      final tickets = snapshot.docs
          .map((doc) => SupportTicketModel.fromFirestore(doc))
          .toList();

      // Filter by search query
      final filteredTickets = tickets.where((ticket) {
        final titleMatch = ticket.title.toLowerCase().contains(query.toLowerCase());
        final descriptionMatch = ticket.description.toLowerCase().contains(query.toLowerCase());
        final lecturerMatch = ticket.lecturerName.toLowerCase().contains(query.toLowerCase());
        return titleMatch || descriptionMatch || lecturerMatch;
      }).toList();

      return filteredTickets;
    } catch (e) {
      throw Exception('Failed to search tickets: $e');
    }
  }
}
