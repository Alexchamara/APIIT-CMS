import 'package:apiit_cms/features/auth/data/auth_repository.dart';
import 'package:apiit_cms/features/auth/domain/models/user_model.dart';
import 'package:apiit_cms/features/class/data/class_repository.dart';
import 'package:apiit_cms/features/class/domain/models/class_model.dart';
import 'package:apiit_cms/features/class/presentation/screens/add_class_screen.dart';
import 'package:apiit_cms/features/class/presentation/widgets/classroom_card.dart';
import 'package:apiit_cms/features/class/presentation/widgets/classroom_filter_drawer.dart';
import 'package:apiit_cms/shared/theme.dart';
import 'package:apiit_cms/shared/widgets/custom_app_bar.dart';
import 'package:flutter/material.dart';

class ClassroomsScreen extends StatefulWidget {
  const ClassroomsScreen({super.key});

  @override
  State<ClassroomsScreen> createState() => _ClassroomsScreenState();
}

class _ClassroomsScreenState extends State<ClassroomsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  List<ClassroomModel> _allClassrooms = [];
  List<ClassroomModel> _filteredClassrooms = [];
  bool _isLoading = true;
  String _errorMessage = '';
  UserModel? _currentUser;
  ClassroomFilterOptions _filterOptions = ClassroomFilterOptions();

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _loadClassrooms();
    _searchController.addListener(_filterClassrooms);
  }

  Future<void> _loadCurrentUser() async {
    try {
      _currentUser = await AuthRepository.getCurrentUserModel();
    } finally {
      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool get _isAdmin => _currentUser?.userType == UserType.admin;

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
      _filteredClassrooms = _allClassrooms.where((classroomItem) {
        // Text search filter
        final matchesSearch =
            query.isEmpty ||
            classroomItem.roomName.toLowerCase().contains(query) ||
            classroomItem.floor.toLowerCase().contains(query) ||
            classroomItem.type.name.toLowerCase().contains(query);

        // Type filter
        final matchesType =
            _filterOptions.selectedTypes.isEmpty ||
            _filterOptions.selectedTypes.contains(classroomItem.type);

        // Floor filter
        final matchesFloor =
            _filterOptions.selectedFloors.isEmpty ||
            _filterOptions.selectedFloors.contains(classroomItem.floor);

        // Capacity filter
        final matchesCapacity =
            _filterOptions.capacityRange == null ||
            (classroomItem.capacity >= _filterOptions.capacityRange!.start &&
                classroomItem.capacity <= _filterOptions.capacityRange!.end);

        // Availability filter
        final matchesAvailability =
            _filterOptions.isAvailable == null ||
            classroomItem.isAvailable == _filterOptions.isAvailable;

        // Currently open filter
        final matchesCurrentlyOpen =
            _filterOptions.isCurrentlyOpen == null ||
            classroomItem.isCurrentlyOpen == _filterOptions.isCurrentlyOpen;

        // Maintenance filter
        final matchesMaintenance =
            _filterOptions.isUnderMaintenance == null ||
            classroomItem.isUnderMaintenance !=
                _filterOptions.isUnderMaintenance;

        return matchesSearch &&
            matchesType &&
            matchesFloor &&
            matchesCapacity &&
            matchesAvailability &&
            matchesCurrentlyOpen &&
            matchesMaintenance;
      }).toList();
    });
  }

  void _onFiltersChanged(ClassroomFilterOptions newFilters) {
    setState(() {
      _filterOptions = newFilters;
    });
    _filterClassrooms();
  }

  void _openFilterDrawer() {
    _scaffoldKey.currentState?.openEndDrawer();
  }

  int _getActiveFiltersCount() {
    int count = 0;
    if (_filterOptions.selectedTypes.isNotEmpty) count++;
    if (_filterOptions.selectedFloors.isNotEmpty) count++;
    if (_filterOptions.capacityRange != null) {
      // Check if capacity range is different from default
      if (_allClassrooms.isNotEmpty) {
        final capacities = _allClassrooms.map((c) => c.capacity).toList();
        final minCapacity = capacities
            .reduce((a, b) => a < b ? a : b)
            .toDouble();
        final maxCapacity = capacities
            .reduce((a, b) => a > b ? a : b)
            .toDouble();
        if (_filterOptions.capacityRange!.start != minCapacity ||
            _filterOptions.capacityRange!.end != maxCapacity) {
          count++;
        }
      }
    }
    if (_filterOptions.isAvailable == true) count++;
    if (_filterOptions.isCurrentlyOpen == true) count++;
    if (_filterOptions.isUnderMaintenance == false) count++;
    return count;
  }

  Future<void> _navigateToAddClassroom() async {
    // Check if user is admin
    if (!_isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Only administrators can add new classrooms'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final result = await Navigator.of(context).push<ClassroomModel>(
      MaterialPageRoute(builder: (context) => const AddClassroomScreen()),
    );

    if (result != null) {
      await _loadClassrooms();
    }
  }

  Future<void> _deleteClassroom(ClassroomModel classroomModel) async {
    // Check if user is admin
    if (!_isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Only administrators can delete classrooms'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Classroom'),
        content: Text(
          'Are you sure you want to delete "${classroomModel.roomName}"?',
        ),
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
              content: Text(
                'Classroom "${classroomModel.roomName}" deleted successfully!',
              ),
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

  Future<void> _toggleAvailability(ClassroomModel classroomModel) async {
    // Check if user is admin
    if (!_isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Only administrators can modify classroom availability',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      await ClassroomRepository.toggleClassroomAvailability(classroomModel.id);
      await _loadClassrooms();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Classroom "${classroomModel.roomName}" is now ${!classroomModel.isAvailable ? "available" : "unavailable"}',
            ),
            backgroundColor: !classroomModel.isAvailable
                ? Colors.green
                : Colors.orange,
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
      key: _scaffoldKey,
      appBar: AppBarStyles.primary(
        title: 'Classrooms',
        showBackButton: false,
        actions: [
          // Filter button with indicator
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.sort),
                onPressed: _openFilterDrawer,
                tooltip: 'Filter Classrooms',
              ),
              if (_filterOptions.hasActiveFilters)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      endDrawer: ClassroomFilterDrawer(
        filterOptions: _filterOptions,
        allClassrooms: _allClassrooms,
        onFiltersChanged: _onFiltersChanged,
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

          // Active Filters Chip
          if (_filterOptions.hasActiveFilters)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Wrap(
                children: [
                  ActionChip(
                    avatar: Icon(
                      Icons.filter_list,
                      size: 18,
                      color: AppTheme.primary,
                    ),
                    label: Text(
                      '${_getActiveFiltersCount()} filter(s) active',
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.primary,
                      ),
                    ),
                    onPressed: _openFilterDrawer,
                    backgroundColor: AppTheme.primary.withOpacity(0.1),
                    side: BorderSide(color: AppTheme.primary.withOpacity(0.3)),
                  ),
                  const SizedBox(width: 8),
                  ActionChip(
                    label: const Text('Clear'),
                    onPressed: () {
                      setState(() {
                        _filterOptions.clearAll();
                      });
                      _filterClassrooms();
                    },
                    backgroundColor: Colors.grey[200],
                  ),
                ],
              ),
            ),

          if (_filterOptions.hasActiveFilters) const SizedBox(height: 8),

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
                          style: AppTheme.headlineMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _errorMessage,
                          textAlign: TextAlign.center,
                          style: AppTheme.bodyLarge,
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
                          style: AppTheme.headlineMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _searchController.text.isNotEmpty
                              ? 'Try adjusting your search terms'
                              : 'Add your first classroom using the + button',
                          style: AppTheme.bodyLarge,
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
                          isAdmin: _isAdmin,
                          onDelete: () => _deleteClassroom(classroomModel),
                          onToggleAvailability: () =>
                              _toggleAvailability(classroomModel),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: _isAdmin
          ? FloatingActionButton(
              onPressed: _navigateToAddClassroom,
              tooltip: 'Add New Classroom',
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
