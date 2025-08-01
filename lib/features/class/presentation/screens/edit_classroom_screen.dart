import 'package:apiit_cms/features/class/data/class_repository.dart';
import 'package:apiit_cms/features/class/domain/models/class_model.dart';
import 'package:apiit_cms/shared/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class EditClassroomScreen extends StatefulWidget {
  final ClassroomModel classroom;

  const EditClassroomScreen({
    super.key,
    required this.classroom,
  });

  @override
  State<EditClassroomScreen> createState() => _EditClassroomScreenState();
}

class _EditClassroomScreenState extends State<EditClassroomScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _roomNameController;
  late TextEditingController _floorController;
  late TextEditingController _capacityController;
  late TextEditingController _openingHourController;
  late TextEditingController _closingHourController;

  late ClassroomType _selectedType;
  late bool _isAvailable;
  late List<DateTime> _blackoutDays;
  DateTime? _maintenanceStart;
  DateTime? _maintenanceEnd;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with existing classroom data
    _roomNameController = TextEditingController(text: widget.classroom.roomName);
    _floorController = TextEditingController(text: widget.classroom.floor);
    _capacityController = TextEditingController(text: widget.classroom.capacity.toString());
    _openingHourController = TextEditingController(text: widget.classroom.openingHour.toString());
    _closingHourController = TextEditingController(text: widget.classroom.closingHour.toString());
    
    _selectedType = widget.classroom.type;
    _isAvailable = widget.classroom.isAvailable;
    _blackoutDays = List.from(widget.classroom.blackoutDays);
    _maintenanceStart = widget.classroom.maintenanceStart;
    _maintenanceEnd = widget.classroom.maintenanceEnd;
  }

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
      final updatedClassroom = widget.classroom.copyWith(
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
        updatedAt: DateTime.now(),
      );

      await ClassroomRepository.updateClassroom(updatedClassroom);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Classroom updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating classroom: $e'),
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

  Future<void> _selectMaintenanceDate(bool isStartDate) async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: isStartDate 
          ? (_maintenanceStart ?? DateTime.now())
          : (_maintenanceEnd ?? DateTime.now()),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (selectedDate != null) {
      setState(() {
        if (isStartDate) {
          _maintenanceStart = selectedDate;
          // Clear end date if start date is after it
          if (_maintenanceEnd != null && selectedDate.isAfter(_maintenanceEnd!)) {
            _maintenanceEnd = null;
          }
        } else {
          _maintenanceEnd = selectedDate;
        }
      });
    }
  }

  Future<void> _addBlackoutDay() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (selectedDate != null) {
      // Check if date is not already in blackout days
      final isAlreadyBlackedOut = _blackoutDays.any((date) =>
          date.year == selectedDate.year &&
          date.month == selectedDate.month &&
          date.day == selectedDate.day);

      if (!isAlreadyBlackedOut) {
        setState(() {
          _blackoutDays.add(selectedDate);
          _blackoutDays.sort(); // Keep dates sorted
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Date is already in blackout days'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  void _removeBlackoutDay(int index) {
    setState(() {
      _blackoutDays.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Edit Classroom',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _submitForm,
            child: Text(
              'Save',
              style: TextStyle(
                color: _isLoading ? Colors.white54 : Colors.white,
                fontWeight: FontWeight.bold,
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
              // Basic Information Section
              _buildSectionHeader('Basic Information'),
              const SizedBox(height: 12),
              
              // Room Name
              TextFormField(
                controller: _roomNameController,
                decoration: const InputDecoration(
                  labelText: 'Room Name',
                  hintText: 'e.g., A101, LAB-01',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.characters,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter room name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Floor and Type Row
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _floorController,
                      decoration: const InputDecoration(
                        labelText: 'Floor',
                        hintText: 'e.g., Ground, 1st, 2nd',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter floor';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<ClassroomType>(
                      value: _selectedType,
                      decoration: const InputDecoration(
                        labelText: 'Type',
                        border: OutlineInputBorder(),
                      ),
                      items: ClassroomType.values.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(_getTypeDisplayName(type)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedType = value!;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Capacity
              TextFormField(
                controller: _capacityController,
                decoration: const InputDecoration(
                  labelText: 'Capacity',
                  hintText: 'Number of people',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter capacity';
                  }
                  final capacity = int.tryParse(value);
                  if (capacity == null || capacity <= 0) {
                    return 'Please enter a valid capacity';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Operating Hours Section
              _buildSectionHeader('Operating Hours'),
              const SizedBox(height: 12),
              
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _openingHourController,
                      decoration: const InputDecoration(
                        labelText: 'Opening Hour',
                        hintText: '24-hour format (e.g., 8)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        final hour = int.tryParse(value);
                        if (hour == null || hour < 0 || hour > 23) {
                          return 'Enter 0-23';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _closingHourController,
                      decoration: const InputDecoration(
                        labelText: 'Closing Hour',
                        hintText: '24-hour format (e.g., 17)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        final hour = int.tryParse(value);
                        if (hour == null || hour < 0 || hour > 23) {
                          return 'Enter 0-23';
                        }
                        final openingHour = int.tryParse(_openingHourController.text);
                        if (openingHour != null && hour <= openingHour) {
                          return 'Must be after opening hour';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Availability Section
              _buildSectionHeader('Availability'),
              const SizedBox(height: 12),
              
              SwitchListTile(
                title: const Text('Available for Booking'),
                subtitle: Text(_isAvailable 
                    ? 'Classroom is available for reservations'
                    : 'Classroom is unavailable for reservations'),
                value: _isAvailable,
                onChanged: (value) {
                  setState(() {
                    _isAvailable = value;
                  });
                },
                activeColor: AppTheme.primary,
              ),
              const SizedBox(height: 24),

              // Maintenance Section
              _buildSectionHeader('Maintenance Schedule'),
              const SizedBox(height: 12),
              
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Start Date', style: TextStyle(fontWeight: FontWeight.w500)),
                                const SizedBox(height: 4),
                                InkWell(
                                  onTap: () => _selectMaintenanceDate(true),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.calendar_today, size: 20),
                                        const SizedBox(width: 8),
                                        Text(_maintenanceStart != null 
                                            ? '${_maintenanceStart!.day}/${_maintenanceStart!.month}/${_maintenanceStart!.year}'
                                            : 'Select date'),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('End Date', style: TextStyle(fontWeight: FontWeight.w500)),
                                const SizedBox(height: 4),
                                InkWell(
                                  onTap: () => _selectMaintenanceDate(false),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.calendar_today, size: 20),
                                        const SizedBox(width: 8),
                                        Text(_maintenanceEnd != null 
                                            ? '${_maintenanceEnd!.day}/${_maintenanceEnd!.month}/${_maintenanceEnd!.year}'
                                            : 'Select date'),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (_maintenanceStart != null || _maintenanceEnd != null) ...[
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _maintenanceStart = null;
                                  _maintenanceEnd = null;
                                });
                              },
                              child: const Text('Clear Maintenance'),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Blackout Days Section
              _buildSectionHeader('Blackout Days'),
              const SizedBox(height: 12),
              
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Days when the classroom is not available for booking',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: _addBlackoutDay,
                            icon: const Icon(Icons.add),
                            label: const Text('Add Day'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      if (_blackoutDays.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        ...List.generate(_blackoutDays.length, (index) {
                          final date = _blackoutDays[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                const Icon(Icons.event_busy, color: Colors.red, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text('${date.day}/${date.month}/${date.year}'),
                                ),
                                IconButton(
                                  onPressed: () => _removeBlackoutDay(index),
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            SizedBox(width: 12),
                            Text('Updating Classroom...'),
                          ],
                        )
                      : const Text(
                          'Update Classroom',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppTheme.primary,
      ),
    );
  }

  String _getTypeDisplayName(ClassroomType type) {
    switch (type) {
      case ClassroomType.classroom:
        return 'Classroom';
      case ClassroomType.lab:
        return 'Computer Lab';
      case ClassroomType.auditorium:
        return 'Auditorium';
    }
  }
}
