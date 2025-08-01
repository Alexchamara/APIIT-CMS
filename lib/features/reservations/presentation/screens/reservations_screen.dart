import 'package:apiit_cms/features/auth/data/auth_repository.dart';
import 'package:apiit_cms/features/auth/domain/models/user_model.dart';
import 'package:apiit_cms/features/reservations/data/reservation_repository.dart';
import 'package:apiit_cms/features/reservations/domain/models/reservation_model.dart';
import 'package:apiit_cms/features/reservations/presentation/screens/add_reservation_screen.dart';
import 'package:apiit_cms/features/reservations/presentation/widgets/reservation_card.dart';
import 'package:apiit_cms/shared/theme.dart';
import 'package:flutter/material.dart';

class ReservationsScreen extends StatefulWidget {
  const ReservationsScreen({super.key});

  @override
  State<ReservationsScreen> createState() => _ReservationsScreenState();
}

class _ReservationsScreenState extends State<ReservationsScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<ReservationModel> _allReservations = [];
  List<ReservationModel> _filteredReservations = [];
  bool _isLoading = true;
  String _errorMessage = '';
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _searchController.addListener(_filterReservations);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUser() async {
    try {
      _currentUser = await AuthRepository.getCurrentUserModel();
      _loadReservations();
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load user information: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadReservations() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      List<ReservationModel> reservations;
      
      if (_currentUser?.userType == UserType.admin) {
        // Admin can see all reservations
        reservations = await ReservationRepository.getAllReservations();
      } else if (_currentUser?.uid != null) {
        // Lecturers can only see their own reservations
        reservations = await ReservationRepository.getReservationsByLecturer(_currentUser!.uid);
      } else {
        reservations = [];
      }
      
      setState(() {
        _allReservations = reservations;
        _filteredReservations = reservations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _filterReservations() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredReservations = _allReservations;
      } else {
        _filteredReservations = _allReservations.where((reservation) {
          return reservation.lecturerName.toLowerCase().contains(query) ||
              reservation.classroomName.toLowerCase().contains(query) ||
              reservation.typeLabel.toLowerCase().contains(query) ||
              reservation.description?.toLowerCase().contains(query) == true;
        }).toList();
      }
    });
  }

  Future<void> _navigateToAddReservation() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddReservationScreen(),
      ),
    );

    if (result == true) {
      _loadReservations();
    }
  }

  Future<void> _deleteReservation(ReservationModel reservation) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Reservation'),
        content: Text('Are you sure you want to delete the reservation for ${reservation.classroomName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ReservationRepository.deleteReservation(reservation.id);
        _loadReservations();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Reservation deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting reservation: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reservations'),
        backgroundColor: AppTheme.primary,
        foregroundColor: AppTheme.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search reservations by lecturer, classroom, or type...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
          ),
          
          // Reservations List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage.isNotEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: Colors.red[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Error loading reservations',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _errorMessage,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadReservations,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _filteredReservations.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.event_note_outlined,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _searchController.text.isNotEmpty
                                      ? 'No reservations found'
                                      : 'No reservations available',
                                  style: Theme.of(context).textTheme.headlineSmall,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _searchController.text.isNotEmpty
                                      ? 'Try adjusting your search terms'
                                      : 'Add your first reservation using the + button',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadReservations,
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              itemCount: _filteredReservations.length,
                              itemBuilder: (context, index) {
                                final reservation = _filteredReservations[index];
                                return ReservationCard(
                                  reservation: reservation,
                                  onDelete: () => _deleteReservation(reservation),
                                  currentUser: _currentUser,
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddReservation,
        tooltip: 'Add New Reservation',
        child: const Icon(Icons.add),
      ),
    );
  }
}
