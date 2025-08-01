import 'package:apiit_cms/features/auth/data/auth_repository.dart';
import 'package:apiit_cms/features/auth/domain/models/user_model.dart';
import 'package:apiit_cms/features/class/data/class_repository.dart';
import 'package:apiit_cms/features/class/domain/models/class_model.dart';
import 'package:apiit_cms/shared/theme.dart';
import 'package:apiit_cms/shared/widgets/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AddClassroomScreen extends StatefulWidget {
  const AddClassroomScreen({super.key});

  @override
  State<AddClassroomScreen> createState() => _AddClassroomScreenState();
}

class _AddClassroomScreenState extends State<AddClassroomScreen> {
  final _formKey = GlobalKey<FormState>();
  final _roomNameController = TextEditingController();
  final _floorController = TextEditingController();
  final _capacityController = TextEditingController();
  final _openingHourController = TextEditingController(text: '8');
  final _closingHourController = TextEditingController(text: '17');

  ClassroomType _selectedType = ClassroomType.classroom;
  bool _isAvailable = true;
  final List<DateTime> _blackoutDays = [];
  DateTime? _maintenanceStart;
  DateTime? _maintenanceEnd;
  bool _isLoading = false;
  UserModel? _currentUser;
  bool _isLoadingUser = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    try {
      _currentUser = await AuthRepository.getCurrentUserModel();
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingUser = false;
        });
      }
    }
  }

  bool get _isAdmin => _currentUser?.userType == UserType.admin;

  @override
  void dispose() {
    _roomNameController.dispose();
    _floorController.dispose();
    _capacityController.dispose();
    _openingHourController.dispose();
    _closingHourController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final newClassroom = ClassroomModel(
        id: '', // Will be set by repository
        roomName: _roomNameController.text.trim().toUpperCase(),
        floor: _floorController.text.trim(),
        type: _selectedType,
        isAvailable: _isAvailable,
        capacity: int.parse(_capacityController.text),
        openingHour: int.parse(_openingHourController.text),
        closingHour: int.parse(_closingHourController.text),
        blackoutDays: _blackoutDays,
        maintenanceStart: _maintenanceStart,
        maintenanceEnd: _maintenanceEnd,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final createdClassroom = await ClassroomRepository.createClassroom(
        newClassroom,
      );

      if (mounted) {
        Navigator.of(context).pop(createdClassroom);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Classroom "${createdClassroom.roomName}" created successfully!',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create classroom: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _selectBlackoutDay() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (selectedDate != null && !_blackoutDays.contains(selectedDate)) {
      setState(() {
        _blackoutDays.add(selectedDate);
      });
    }
  }

  Future<void> _selectMaintenancePeriod() async {
    final dateRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _maintenanceStart != null && _maintenanceEnd != null
          ? DateTimeRange(start: _maintenanceStart!, end: _maintenanceEnd!)
          : null,
    );

    if (dateRange != null) {
      setState(() {
        _maintenanceStart = dateRange.start;
        _maintenanceEnd = dateRange.end;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading screen while determining user role
    if (_isLoadingUser) {
      return const Scaffold(
        backgroundColor: AppTheme.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppTheme.primary),
              SizedBox(height: 16),
              Text(
                'Loading...',
                style: TextStyle(fontSize: 16, color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    // Show access denied screen if user is not admin
    if (!_isAdmin) {
      return Scaffold(
        backgroundColor: AppTheme.white,
        appBar: AppBarStyles.primary(title: 'Access Denied'),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock, size: 64, color: AppTheme.grey),
              SizedBox(height: 16),
              Text('Access Denied', style: AppTheme.headlineMedium),
              SizedBox(height: 8),
              Text(
                'Only administrators can add new classrooms.',
                style: AppTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBarStyles.primary(
        title: 'Add New Classroom',
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.white),
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Room Name
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Basic Information', style: AppTheme.titleLarge),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _roomNameController,
                        decoration: const InputDecoration(
                          labelText: 'Room Name *',
                          hintText: 'e.g., LAB-001, CR-A-101',
                          prefixIcon: Icon(Icons.meeting_room),
                          border: OutlineInputBorder(),
                        ),
                        textCapitalization: TextCapitalization.characters,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Room name is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _floorController,
                        decoration: const InputDecoration(
                          labelText: 'Floor *',
                          hintText: 'e.g., 1, 2, Ground',
                          prefixIcon: Icon(Icons.layers),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Floor is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<ClassroomType>(
                        value: _selectedType,
                        decoration: const InputDecoration(
                          labelText: 'Type *',
                          prefixIcon: Icon(Icons.category),
                          border: OutlineInputBorder(),
                        ),
                        items: ClassroomType.values.map((type) {
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
                          if (value != null) {
                            setState(() => _selectedType = value);
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _capacityController,
                        decoration: const InputDecoration(
                          labelText: 'Capacity *',
                          hintText: 'Number of seats',
                          prefixIcon: Icon(Icons.people),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Capacity is required';
                          }
                          final capacity = int.tryParse(value);
                          if (capacity == null || capacity <= 0) {
                            return 'Please enter a valid capacity';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Operating Hours
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Operating Hours', style: AppTheme.titleLarge),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _openingHourController,
                        decoration: const InputDecoration(
                          labelText: 'Opening Hour *',
                          hintText: '24-hour format',
                          prefixIcon: Icon(Icons.access_time),
                          border: OutlineInputBorder(),
                          suffixText: ':00',
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Opening hour is required';
                          }
                          final hour = int.tryParse(value);
                          if (hour == null || hour < 0 || hour > 23) {
                            return 'Enter hour 0-23';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _closingHourController,
                        decoration: const InputDecoration(
                          labelText: 'Closing Hour *',
                          hintText: '24-hour format',
                          prefixIcon: Icon(Icons.access_time_filled),
                          border: OutlineInputBorder(),
                          suffixText: ':00',
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Closing hour is required';
                          }
                          final hour = int.tryParse(value);
                          if (hour == null || hour < 0 || hour > 23) {
                            return 'Enter hour 0-23';
                          }
                          final openingHour = int.tryParse(
                            _openingHourController.text,
                          );
                          if (openingHour != null && hour <= openingHour) {
                            return 'Must be later than opening hour';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Settings
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Settings', style: AppTheme.titleLarge),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        title: const Text('Available'),
                        subtitle: const Text(
                          'Is this classroom available for booking?',
                        ),
                        value: _isAvailable,
                        onChanged: (value) =>
                            setState(() => _isAvailable = value),
                        secondary: const Icon(Icons.visibility),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Blackout Days
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.event_busy),
                          const SizedBox(width: 8),
                          Text('Blackout Days', style: AppTheme.titleLarge),
                          const Spacer(),
                          OutlinedButton.icon(
                            onPressed: _selectBlackoutDay,
                            icon: const Icon(Icons.add),
                            label: const Text('Add Day'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_blackoutDays.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _blackoutDays.map((date) {
                            return Chip(
                              label: Text(_formatDate(date)),
                              deleteIcon: const Icon(Icons.close, size: 16),
                              onDeleted: () {
                                setState(() => _blackoutDays.remove(date));
                              },
                            );
                          }).toList(),
                        ),
                      ] else
                        Text(
                          'No blackout days set',
                          style: AppTheme.bodyLarge.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Maintenance Period
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.build),
                          const SizedBox(width: 8),
                          Text('Maintenance', style: AppTheme.titleLarge),
                          const Spacer(),
                          OutlinedButton.icon(
                            onPressed: _selectMaintenancePeriod,
                            icon: const Icon(Icons.edit_calendar),
                            label: const Text('Set Period'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_maintenanceStart != null &&
                          _maintenanceEnd != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange[200]!),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.schedule,
                                color: Colors.orange[700],
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${_formatDate(_maintenanceStart!)} - ${_formatDate(_maintenanceEnd!)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: Colors.orange[700],
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  setState(() {
                                    _maintenanceStart = null;
                                    _maintenanceEnd = null;
                                  });
                                },
                                icon: Icon(
                                  Icons.close,
                                  color: Colors.orange[700],
                                  size: 20,
                                ),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                        ),
                      ] else
                        Text(
                          'No maintenance period scheduled',
                          style: AppTheme.bodyLarge.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isLoading
                      ? null
                      : () => Navigator.of(context).pop(),
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
                      : const Text('Create Classroom'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getTypeIcon(ClassroomType type) {
    switch (type) {
      case ClassroomType.lab:
        return Icons.computer;
      case ClassroomType.classroom:
        return Icons.school;
      case ClassroomType.auditorium:
        return Icons.groups;
    }
  }

  String _getTypeLabel(ClassroomType type) {
    switch (type) {
      case ClassroomType.lab:
        return 'Computer Lab';
      case ClassroomType.classroom:
        return 'Classroom';
      case ClassroomType.auditorium:
        return 'Auditorium';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
