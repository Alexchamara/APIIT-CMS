import 'package:apiit_cms/features/auth/data/auth_repository.dart';
import 'package:apiit_cms/features/class/data/class_repository.dart';
import 'package:apiit_cms/features/class/domain/models/class_model.dart';
import 'package:apiit_cms/features/reservations/data/reservation_repository.dart';
import 'package:apiit_cms/features/reservations/domain/models/reservation_model.dart';
import 'package:apiit_cms/shared/theme.dart';
import 'package:flutter/material.dart';

class AddReservationScreen extends StatefulWidget {
  const AddReservationScreen({super.key});

  @override
  State<AddReservationScreen> createState() => _AddReservationScreenState();
}

class _AddReservationScreenState extends State<AddReservationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _lecturerNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _classroomSearchController = TextEditingController();

  ReservationType _selectedType = ReservationType.lecture;
  DateTime _selectedDate = DateTime.now();
  ClassroomModel? _selectedClassroom;
  List<ClassroomModel> _availableClassrooms = [];
  List<ClassroomModel> _filteredClassrooms = [];
  bool _isLoadingClassrooms = false;
  bool _isLoading = false;

  // Time slots
  final List<TimeSlot> _selectedTimeSlots = [];
  final List<TimeSlot> _conflictedTimeSlots = [];
  final List<TimeSlot> _availableTimeSlots = [
    const TimeSlot(startTime: '08:00', endTime: '09:00'),
    const TimeSlot(startTime: '09:00', endTime: '10:00'),
    const TimeSlot(startTime: '10:00', endTime: '11:00'),
    const TimeSlot(startTime: '11:00', endTime: '12:00'),
    const TimeSlot(startTime: '12:00', endTime: '13:00'),
    const TimeSlot(startTime: '13:00', endTime: '14:00'),
    const TimeSlot(startTime: '14:00', endTime: '15:00'),
    const TimeSlot(startTime: '15:00', endTime: '16:00'),
    const TimeSlot(startTime: '16:00', endTime: '17:00'),
    const TimeSlot(startTime: '17:00', endTime: '18:00'),
    const TimeSlot(startTime: '18:00', endTime: '19:00'),
    const TimeSlot(startTime: '19:00', endTime: '20:00'),
    const TimeSlot(startTime: '20:00', endTime: '21:00'),
    const TimeSlot(startTime: '21:00', endTime: '22:00'),
  ];

  @override
  void initState() {
    super.initState();
    _loadClassrooms();
    _loadCurrentUser();
    _classroomSearchController.addListener(_filterClassrooms);
  }

  @override
  void dispose() {
    _lecturerNameController.dispose();
    _descriptionController.dispose();
    _classroomSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUser() async {
    final user = await AuthRepository.getCurrentUserModel();
    if (user != null) {
      _lecturerNameController.text = user.displayName;
    }
  }

  Future<void> _loadClassrooms() async {
    setState(() => _isLoadingClassrooms = true);

    try {
      final classrooms = await ClassroomRepository.getAllClassrooms();
      setState(() {
        _availableClassrooms = classrooms.where((classroom) => classroom.isAvailable).toList();
        _filteredClassrooms = _availableClassrooms;
        _isLoadingClassrooms = false;
      });
    } catch (e) {
      setState(() => _isLoadingClassrooms = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading classrooms: $e')),
        );
      }
    }
  }

  void _filterClassrooms() {
    final query = _classroomSearchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredClassrooms = _availableClassrooms;
      } else {
        _filteredClassrooms = _availableClassrooms.where((classroom) {
          return classroom.roomName.toLowerCase().contains(query) ||
              classroom.floor.toLowerCase().contains(query) ||
              _getClassroomTypeLabel(classroom.type).toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  Future<void> _selectDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
        // Remove any selected time slots that are now in the past
        _selectedTimeSlots.removeWhere((slot) => _isPastTimeSlot(slot));
      });
      // Check for conflicts when date changes
      _checkTimeSlotConflicts();
    }
  }

  void _toggleTimeSlot(TimeSlot timeSlot) {
    // Don't allow selection of conflicted time slots
    if (_conflictedTimeSlots.contains(timeSlot)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This time slot is already reserved for the selected classroom'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Don't allow selection of past time slots
    if (_isPastTimeSlot(timeSlot)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot reserve past time slots'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      if (_selectedTimeSlots.contains(timeSlot)) {
        _selectedTimeSlots.remove(timeSlot);
      } else {
        if (_selectedTimeSlots.length < 4) {
          _selectedTimeSlots.add(timeSlot);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Maximum 4 time slots can be selected')),
          );
        }
      }
    });
  }

  void _selectClassroom(ClassroomModel classroom) {
    setState(() {
      _selectedClassroom = classroom;
    });
    Navigator.pop(context);
    // Check for conflicts when classroom changes
    _checkTimeSlotConflicts();
  }

  Future<void> _checkTimeSlotConflicts() async {
    if (_selectedClassroom == null) {
      setState(() {
        _conflictedTimeSlots.clear();
      });
      return;
    }

    try {
      final conflicts = await ReservationRepository.checkConflicts(
        _selectedClassroom!.id,
        _selectedDate,
        _availableTimeSlots,
      );

      // Collect all conflicted time slots
      final conflictedSlots = <TimeSlot>[];
      for (final conflict in conflicts) {
        conflictedSlots.addAll(conflict.timeSlots);
      }

      setState(() {
        _conflictedTimeSlots.clear();
        _conflictedTimeSlots.addAll(conflictedSlots);
        
        // Remove any selected time slots that are now conflicted or in the past
        _selectedTimeSlots.removeWhere((slot) => 
            _conflictedTimeSlots.contains(slot) || _isPastTimeSlot(slot));
      });
    } catch (e) {
      // Handle error silently or show a snackbar
      debugPrint('Error checking conflicts: $e');
    }
  }

  bool _isPastTimeSlot(TimeSlot timeSlot) {
    // Only check for past time slots if the selected date is today
    final now = DateTime.now();
    final selectedDateOnly = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    final todayOnly = DateTime(now.year, now.month, now.day);
    
    // If selected date is not today, no time slots are considered past
    if (!selectedDateOnly.isAtSameMomentAs(todayOnly)) {
      return false;
    }
    
    // Parse the start time of the slot
    final timeParts = timeSlot.startTime.split(':');
    final slotHour = int.parse(timeParts[0]);
    final slotMinute = int.parse(timeParts[1]);
    
    // Create datetime for the slot start time today
    final slotDateTime = DateTime(now.year, now.month, now.day, slotHour, slotMinute);
    
    // Check if slot start time is in the past (with a small buffer of 15 minutes)
    return slotDateTime.isBefore(now.subtract(const Duration(minutes: 15)));
  }

  void _showClassroomSelection() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                Text(
                  'Select Classroom',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Search field
                TextField(
                  controller: _classroomSearchController,
                  decoration: InputDecoration(
                    hintText: 'Search classrooms...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Classrooms list
                Expanded(
                  child: _isLoadingClassrooms
                      ? const Center(child: CircularProgressIndicator())
                      : _filteredClassrooms.isEmpty
                          ? const Center(child: Text('No classrooms found'))
                          : ListView.builder(
                              controller: scrollController,
                              itemCount: _filteredClassrooms.length,
                              itemBuilder: (context, index) {
                                final classroom = _filteredClassrooms[index];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    leading: Icon(
                                      _getClassroomIcon(classroom.type),
                                      color: Colors.grey[700],
                                    ),
                                    title: Text(classroom.roomName),
                                    subtitle: Text(
                                      'Floor ${classroom.floor} • ${_getClassroomTypeLabel(classroom.type)} • ${classroom.capacity} seats',
                                    ),
                                    trailing: classroom.isCurrentlyOpen
                                        ? Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: AppTheme.primary.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              'Open',
                                              style: TextStyle(
                                                color: AppTheme.primary,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          )
                                        : null,
                                    onTap: () => _selectClassroom(classroom),
                                  ),
                                );
                              },
                            ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  IconData _getClassroomIcon(ClassroomType type) {
    switch (type) {
      case ClassroomType.lab:
        return Icons.computer;
      case ClassroomType.classroom:
        return Icons.school;
      case ClassroomType.auditorium:
        return Icons.groups;
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedClassroom == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a classroom')),
      );
      return;
    }

    if (_selectedTimeSlots.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one time slot')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Check for conflicts
      final conflicts = await ReservationRepository.checkConflicts(
        _selectedClassroom!.id,
        _selectedDate,
        _selectedTimeSlots,
      );

      if (conflicts.isNotEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Classroom is already reserved for ${conflicts.length} conflicting time slot(s)',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      final currentUser = await AuthRepository.getCurrentUserModel();
      if (currentUser == null) {
        throw Exception('User not found');
      }

      final newReservation = ReservationModel(
        id: '', // Will be set by repository
        lecturerId: currentUser.uid,
        lecturerName: _lecturerNameController.text.trim(),
        classroomId: _selectedClassroom!.id,
        classroomName: _selectedClassroom!.roomName,
        date: _selectedDate,
        type: _selectedType,
        timeSlots: _selectedTimeSlots,
        description: _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await ReservationRepository.createReservation(newReservation);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reservation created successfully')),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating reservation: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Reservation'),
        backgroundColor: AppTheme.primary,
        foregroundColor: AppTheme.white,
        elevation: 0,
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // User Name
                    TextFormField(
                      controller: _lecturerNameController,
                      decoration: const InputDecoration(
                        labelText: 'User Name',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter user name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Reservation Type
                    DropdownButtonFormField<ReservationType>(
                      value: _selectedType,
                      decoration: const InputDecoration(
                        labelText: 'Reservation Type',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.category),
                      ),
                      items: ReservationType.values
                          .where((type) => type != ReservationType.view)
                          .map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Row(
                            children: [
                              Icon(_getTypeIcon(type), size: 16),
                              const SizedBox(width: 8),
                              Text(_getTypeLabel(type)),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedType = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Date Selection
                    InkWell(
                      onTap: _selectDate,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, color: Colors.grey),
                            const SizedBox(width: 12),
                            Text(
                              'Date: ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                              style: const TextStyle(fontSize: 16),
                            ),
                            const Spacer(),
                            const Icon(Icons.arrow_drop_down, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Classroom Selection
                    InkWell(
                      onTap: _showClassroomSelection,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.room, color: Colors.grey),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _selectedClassroom == null
                                    ? 'Select Classroom'
                                    : '${_selectedClassroom!.roomName} (Floor ${_selectedClassroom!.floor})',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: _selectedClassroom == null
                                      ? Colors.grey[600]
                                      : Colors.black,
                                ),
                              ),
                            ),
                            const Icon(Icons.arrow_drop_down, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Time Slots Selection
                    Text(
                      'Time Slots (Select up to 4)',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Selected: ${_selectedTimeSlots.length}/4',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_conflictedTimeSlots.isNotEmpty) ...[
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: Colors.red[50],
                                  border: Border.all(color: Colors.red[300]!),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Reserved',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.red[700],
                                  fontSize: 10,
                                ),
                              ),
                              const SizedBox(width: 12),
                            ],
                            if (_availableTimeSlots.any((slot) => _isPastTimeSlot(slot))) ...[
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  border: Border.all(color: Colors.grey[300]!),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Past',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[600],
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _availableTimeSlots.map((timeSlot) {
                        final isSelected = _selectedTimeSlots.contains(timeSlot);
                        final isConflicted = _conflictedTimeSlots.contains(timeSlot);
                        final isPast = _isPastTimeSlot(timeSlot);
                        final isDisabled = isConflicted || isPast;
                        
                        return FilterChip(
                          label: Text(
                            timeSlot.toString(),
                            style: TextStyle(
                              color: isConflicted 
                                  ? Colors.red[700] 
                                  : isPast
                                      ? Colors.grey[500]
                                      : isSelected 
                                          ? AppTheme.primary 
                                          : null,
                            ),
                          ),
                          selected: isSelected,
                          onSelected: isDisabled ? null : (_) => _toggleTimeSlot(timeSlot),
                          selectedColor: AppTheme.primary.withOpacity(0.2),
                          checkmarkColor: AppTheme.primary,
                          backgroundColor: isConflicted 
                              ? Colors.red[50] 
                              : isPast
                                  ? Colors.grey[100]
                                  : null,
                          disabledColor: isConflicted ? Colors.red[50] : Colors.grey[100],
                          side: isConflicted 
                              ? BorderSide(color: Colors.red[300]!, width: 1) 
                              : isPast
                                  ? BorderSide(color: Colors.grey[300]!, width: 1)
                                  : null,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Description (Optional)
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description (Optional)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.notes),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),

            // Submit Button
            Container(
              padding: const EdgeInsets.all(16.0),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submitForm,
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Create Reservation'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getTypeIcon(ReservationType type) {
    switch (type) {
      case ReservationType.lecture:
        return Icons.school;
      case ReservationType.meeting:
        return Icons.people;
      case ReservationType.exam:
        return Icons.quiz;
      case ReservationType.discussion:
        return Icons.forum;
      case ReservationType.view:
        return Icons.visibility;
    }
  }

  String _getTypeLabel(ReservationType type) {
    switch (type) {
      case ReservationType.lecture:
        return 'Lecture';
      case ReservationType.meeting:
        return 'Meeting';
      case ReservationType.exam:
        return 'Exam';
      case ReservationType.discussion:
        return 'Discussion';
      case ReservationType.view:
        return 'View';
    }
  }

  String _getClassroomTypeLabel(ClassroomType type) {
    switch (type) {
      case ClassroomType.lab:
        return 'Computer Lab';
      case ClassroomType.classroom:
        return 'Classroom';
      case ClassroomType.auditorium:
        return 'Auditorium';
    }
  }
}
