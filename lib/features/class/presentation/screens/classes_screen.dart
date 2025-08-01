import 'package:apiit_cms/features/class/data/class_repository.dart';
import 'package:apiit_cms/features/class/domain/models/class_model.dart';
import 'package:apiit_cms/features/class/presentation/screens/add_class_screen.dart';
import 'package:apiit_cms/features/class/presentation/screens/edit_classroom_screen.dart';
import 'package:apiit_cms/features/class/presentation/widgets/classroom_card.dart';
import 'package:apiit_cms/features/auth/data/auth_repository.dart';
import 'package:apiit_cms/features/auth/domain/models/user_model.dart';
import 'package:apiit_cms/shared/theme.dart';
import 'package:flutter/material.dart';

class ClassroomsScreen extends StatefulWidget {
  const ClassroomsScreen({super.key});

  @override
  State<ClassroomsScreen> createState() => _ClassroomsScreenState();
}

class _ClassroomsScreenState extends State<ClassroomsScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<ClassroomModel> _allClassrooms = [];
  List<ClassroomModel> _filteredClassrooms = [];
  UserModel? _currentUser;
  bool _isLoading = true;
  String _errorMessage = '';

  bool get _isAdmin => _currentUser?.userType == UserType.admin;

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_filterClassrooms);
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadCurrentUser(),
      _loadClassrooms(),
    ]);
  }

  Future<void> _loadCurrentUser() async {
    _currentUser = await AuthRepository.getCurrentUserModel();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadClassrooms() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final classrooms = await ClassroomRepository.getAllClassrooms();
      setState(() {
        _allClassrooms = classrooms;
        _filteredClassrooms = classrooms;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _filterClassrooms() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredClassrooms = _allClassrooms;
      } else {
        _filteredClassrooms = _allClassrooms
            .where((classroomItem) =>
                classroomItem.roomName.toLowerCase().contains(query) ||
                classroomItem.floor.toLowerCase().contains(query) ||
                classroomItem.type.name.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  Future<void> _navigateToAddClassroom() async {
    final result = await Navigator.of(context).push<ClassroomModel>(
      MaterialPageRoute(
        builder: (context) => const AddClassroomScreen(),
      ),
    );

    if (result != null) {
      await _loadClassrooms();
    }
  }

  Future<void> _deleteClassroom(ClassroomModel classroomModel) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Classroom'),
        content: Text('Are you sure you want to delete "${classroomModel.roomName}"?'),
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
        await ClassroomRepository.deleteClassroom(classroomModel.id);
        await _loadClassrooms();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Classroom "${classroomModel.roomName}" deleted successfully!'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete classroom: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _editClassroom(ClassroomModel classroomModel) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditClassroomScreen(classroom: classroomModel),
      ),
    );
    
    // If the edit was successful, reload the classrooms
    if (result == true) {
      await _loadClassrooms();
    }
  }

  Future<void> _toggleAvailability(ClassroomModel classroomModel) async {
    try {
      await ClassroomRepository.toggleClassroomAvailability(classroomModel.id);
      await _loadClassrooms();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Classroom "${classroomModel.roomName}" is now ${!classroomModel.isAvailable ? "available" : "unavailable"}',
            ),
            backgroundColor: !classroomModel.isAvailable ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update availability: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Classrooms'),
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
                hintText: 'Search classrooms by name, floor, or type...',
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
          
          // Classrooms List
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
                              'Error loading classrooms',
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
                              onPressed: _loadClassrooms,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _filteredClassrooms.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.school_outlined,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _searchController.text.isNotEmpty
                                      ? 'No classrooms found'
                                      : 'No classrooms available',
                                  style: Theme.of(context).textTheme.headlineSmall,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _searchController.text.isNotEmpty
                                      ? 'Try adjusting your search terms'
                                      : 'Add your first classroom using the + button',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadClassrooms,
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              itemCount: _filteredClassrooms.length,
                              itemBuilder: (context, index) {
                                final classroomModel = _filteredClassrooms[index];
                                return ClassroomCard(
                                  classroomModel: classroomModel,
                                  onDelete: () => _deleteClassroom(classroomModel),
                                  onToggleAvailability: () => _toggleAvailability(classroomModel),
                                  onEdit: () => _editClassroom(classroomModel),
                                  currentUser: _currentUser,
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
      floatingActionButton: _isAdmin ? FloatingActionButton(
        onPressed: _navigateToAddClassroom,
        tooltip: 'Add New Classroom',
        child: const Icon(Icons.add),
      ) : null,
    );
  }
}
