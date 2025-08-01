import 'package:apiit_cms/features/class/domain/models/class_model.dart';
import 'package:apiit_cms/shared/theme.dart';
import 'package:flutter/material.dart';

class ClassroomFilterOptions {
  Set<ClassroomType> selectedTypes;
  Set<String> selectedFloors;
  RangeValues? capacityRange;
  bool? isAvailable;
  bool? isCurrentlyOpen;
  bool? isUnderMaintenance;
  int? minCapacity;
  int? maxCapacity;

  ClassroomFilterOptions({
    Set<ClassroomType>? selectedTypes,
    Set<String>? selectedFloors,
    this.capacityRange,
    this.isAvailable,
    this.isCurrentlyOpen,
    this.isUnderMaintenance,
    this.minCapacity,
    this.maxCapacity,
  }) : selectedTypes = selectedTypes ?? {},
       selectedFloors = selectedFloors ?? {};

  ClassroomFilterOptions copyWith({
    Set<ClassroomType>? selectedTypes,
    Set<String>? selectedFloors,
    RangeValues? capacityRange,
    bool? isAvailable,
    bool? isCurrentlyOpen,
    bool? isUnderMaintenance,
    int? minCapacity,
    int? maxCapacity,
  }) {
    return ClassroomFilterOptions(
      selectedTypes: selectedTypes ?? this.selectedTypes,
      selectedFloors: selectedFloors ?? this.selectedFloors,
      capacityRange: capacityRange ?? this.capacityRange,
      isAvailable: isAvailable ?? this.isAvailable,
      isCurrentlyOpen: isCurrentlyOpen ?? this.isCurrentlyOpen,
      isUnderMaintenance: isUnderMaintenance ?? this.isUnderMaintenance,
      minCapacity: minCapacity ?? this.minCapacity,
      maxCapacity: maxCapacity ?? this.maxCapacity,
    );
  }

  bool get hasActiveFilters {
    return selectedTypes.isNotEmpty ||
        selectedFloors.isNotEmpty ||
        capacityRange != null ||
        isAvailable != null ||
        isCurrentlyOpen != null ||
        isUnderMaintenance != null;
  }

  void clearAll() {
    selectedTypes.clear();
    selectedFloors.clear();
    capacityRange = null;
    isAvailable = null;
    isCurrentlyOpen = null;
    isUnderMaintenance = null;
    minCapacity = null;
    maxCapacity = null;
  }
}

class ClassroomFilterDrawer extends StatefulWidget {
  final ClassroomFilterOptions filterOptions;
  final List<ClassroomModel> allClassrooms;
  final Function(ClassroomFilterOptions) onFiltersChanged;

  const ClassroomFilterDrawer({
    super.key,
    required this.filterOptions,
    required this.allClassrooms,
    required this.onFiltersChanged,
  });

  @override
  State<ClassroomFilterDrawer> createState() => _ClassroomFilterDrawerState();
}

class _ClassroomFilterDrawerState extends State<ClassroomFilterDrawer> {
  late ClassroomFilterOptions _currentFilters;
  late RangeValues _capacityRange;
  late double _minCapacity;
  late double _maxCapacity;

  @override
  void initState() {
    super.initState();
    _currentFilters = ClassroomFilterOptions(
      selectedTypes: Set.from(widget.filterOptions.selectedTypes),
      selectedFloors: Set.from(widget.filterOptions.selectedFloors),
      capacityRange: widget.filterOptions.capacityRange,
      isAvailable: widget.filterOptions.isAvailable,
      isCurrentlyOpen: widget.filterOptions.isCurrentlyOpen,
      isUnderMaintenance: widget.filterOptions.isUnderMaintenance,
    );

    // Calculate capacity range from all classrooms
    if (widget.allClassrooms.isNotEmpty) {
      final capacities = widget.allClassrooms.map((c) => c.capacity).toList();
      _minCapacity = capacities.reduce((a, b) => a < b ? a : b).toDouble();
      _maxCapacity = capacities.reduce((a, b) => a > b ? a : b).toDouble();

      _capacityRange =
          _currentFilters.capacityRange ??
          RangeValues(_minCapacity, _maxCapacity);
    } else {
      _minCapacity = 0;
      _maxCapacity = 100;
      _capacityRange = const RangeValues(0, 100);
    }
  }

  List<String> get _availableFloors {
    return widget.allClassrooms.map((c) => c.floor).toSet().toList()..sort();
  }

  void _applyFilters() {
    widget.onFiltersChanged(
      _currentFilters.copyWith(capacityRange: _capacityRange),
    );
    Navigator.of(context).pop();
  }

  void _clearAllFilters() {
    setState(() {
      _currentFilters.clearAll();
      _capacityRange = RangeValues(_minCapacity, _maxCapacity);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          // Header
          Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppTheme.primary, AppTheme.primary.withOpacity(0.8)],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'Filter Classrooms',
                      style: AppTheme.headlineMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Filter Content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // Classroom Type Filter
                _buildSectionTitle('Classroom Type'),
                ...ClassroomType.values.map((type) {
                  return CheckboxListTile(
                    title: Text(_getTypeDisplayName(type)),
                    value: _currentFilters.selectedTypes.contains(type),
                    onChanged: (bool? value) {
                      setState(() {
                        if (value == true) {
                          _currentFilters.selectedTypes.add(type);
                        } else {
                          _currentFilters.selectedTypes.remove(type);
                        }
                      });
                    },
                    dense: true,
                  );
                }),

                const SizedBox(height: 16),

                // Floor Filter
                _buildSectionTitle('Floor'),
                ..._availableFloors.map((floor) {
                  return CheckboxListTile(
                    title: Text('Floor $floor'),
                    value: _currentFilters.selectedFloors.contains(floor),
                    onChanged: (bool? value) {
                      setState(() {
                        if (value == true) {
                          _currentFilters.selectedFloors.add(floor);
                        } else {
                          _currentFilters.selectedFloors.remove(floor);
                        }
                      });
                    },
                    dense: true,
                  );
                }),

                const SizedBox(height: 16),

                // Capacity Range Filter
                _buildSectionTitle('Capacity Range'),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    children: [
                      RangeSlider(
                        values: _capacityRange,
                        min: _minCapacity,
                        max: _maxCapacity,
                        divisions: (_maxCapacity - _minCapacity).round(),
                        labels: RangeLabels(
                          '${_capacityRange.start.round()}',
                          '${_capacityRange.end.round()}',
                        ),
                        onChanged: (RangeValues values) {
                          setState(() {
                            _capacityRange = values;
                          });
                        },
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${_capacityRange.start.round()}'),
                          Text('${_capacityRange.end.round()}'),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Status Filters
                _buildSectionTitle('Status'),
                SwitchListTile(
                  title: const Text('Available Only'),
                  subtitle: const Text('Show only available classrooms'),
                  value: _currentFilters.isAvailable ?? false,
                  onChanged: (bool value) {
                    setState(() {
                      _currentFilters.isAvailable = value ? true : null;
                    });
                  },
                  dense: true,
                ),
                SwitchListTile(
                  title: const Text('Currently Open'),
                  subtitle: const Text(
                    'Show only classrooms that are open now',
                  ),
                  value: _currentFilters.isCurrentlyOpen ?? false,
                  onChanged: (bool value) {
                    setState(() {
                      _currentFilters.isCurrentlyOpen = value ? true : null;
                    });
                  },
                  dense: true,
                ),
                SwitchListTile(
                  title: const Text('Exclude Under Maintenance'),
                  subtitle: const Text('Hide classrooms under maintenance'),
                  value: _currentFilters.isUnderMaintenance ?? false,
                  onChanged: (bool value) {
                    setState(() {
                      _currentFilters.isUnderMaintenance = value ? false : null;
                    });
                  },
                  dense: true,
                ),
              ],
            ),
          ),

          // Action Buttons
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Column(
              children: [
                // Active filters indicator
                if (_currentFilters.hasActiveFilters)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12.0,
                      vertical: 8.0,
                    ),
                    margin: const EdgeInsets.only(bottom: 12.0),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppTheme.primary.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      '${_getActiveFiltersCount()} filter(s) active',
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _clearAllFilters,
                        child: const Text('Clear All'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _applyFilters,
                        child: const Text('Apply'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: AppTheme.titleLarge.copyWith(
          fontWeight: FontWeight.w600,
          color: AppTheme.primary,
        ),
      ),
    );
  }

  String _getTypeDisplayName(ClassroomType type) {
    switch (type) {
      case ClassroomType.lab:
        return 'Laboratory';
      case ClassroomType.classroom:
        return 'Classroom';
      case ClassroomType.auditorium:
        return 'Auditorium';
    }
  }

  int _getActiveFiltersCount() {
    int count = 0;
    if (_currentFilters.selectedTypes.isNotEmpty) count++;
    if (_currentFilters.selectedFloors.isNotEmpty) count++;
    if (_capacityRange.start != _minCapacity ||
        _capacityRange.end != _maxCapacity)
      count++;
    if (_currentFilters.isAvailable == true) count++;
    if (_currentFilters.isCurrentlyOpen == true) count++;
    if (_currentFilters.isUnderMaintenance == false) count++;
    return count;
  }
}
