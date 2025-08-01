import 'package:apiit_cms/features/class/domain/models/class_model.dart';
import 'package:apiit_cms/features/auth/domain/models/user_model.dart';
import 'package:apiit_cms/shared/theme.dart';
import 'package:flutter/material.dart';

class ClassroomCard extends StatelessWidget {
  final ClassroomModel classroomModel;
  final bool isAdmin;
  final VoidCallback onDelete;
  final VoidCallback onToggleAvailability;
  final VoidCallback onEdit;
  final UserModel? currentUser;

  const ClassroomCard({
    super.key,
    required this.classroomModel,
    required this.isAdmin,
    required this.onDelete,
    required this.onToggleAvailability,
    required this.onEdit,
    this.currentUser,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => _showClassroomDetails(context),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  // Classroom Type Icon
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      _getTypeIcon(),
                      color: Colors.grey[700],
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Room Name and Floor
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          classroomModel.roomName,
                          style: AppTheme.titleLarge,
                        ),
                        Text(
                          'Floor ${classroomModel.floor}',
                          style: AppTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),

                  // Status Chip
                  _buildStatusChip(),
                ],
              ),

              const SizedBox(height: 10),

              // Classroom Details with gray background
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _buildInfoChip(
                    icon: Icons.people,
                    label: '${classroomModel.capacity} seats',
                  ),
                  _buildInfoChip(icon: Icons.category, label: _getTypeLabel()),
                  _buildInfoChip(
                    icon: Icons.access_time,
                    label: classroomModel.operatingHours,
                  ),
                ],
              ),

              if (classroomModel.isUnderMaintenance) ...[
                const SizedBox(height: 6),
                _buildInfoChip(icon: Icons.build, label: 'Maintenance'),
              ],

              if (classroomModel.blackoutDays.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  '${classroomModel.blackoutDays.length} blackout day(s)',
                  style: AppTheme.bodyMedium.copyWith(color: Colors.red[600]),
                ),
              ],

              const SizedBox(height: 10),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Edit button (admin only)
                  if (currentUser?.userType == UserType.admin) ...[
                    TextButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  TextButton.icon(
                    onPressed: onToggleAvailability,
                    icon: Icon(
                      classroomModel.isAvailable
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    label: Text(
                      classroomModel.isAvailable
                          ? 'Make Unavailable'
                          : 'Make Available',
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: classroomModel.isAvailable
                          ? Colors.orange
                          : Colors.green,
                    ),
                  ),
                  // Delete button (admin only)
                  if (currentUser?.userType == UserType.admin) ...[
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete),
                      label: const Text('Delete'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip() {
    Color color;
    String label;
    IconData icon;

    if (!classroomModel.isAvailable) {
      color = Colors.red;
      label = 'Unavailable';
      icon = Icons.block;
    } else if (classroomModel.isUnderMaintenance) {
      color = Colors.orange;
      label = 'Maintenance';
      icon = Icons.build;
    } else if (classroomModel.isCurrentlyOpen) {
      color = AppTheme.primary;
      label = 'Open';
      icon = Icons.check_circle;
    } else {
      color = Colors.grey;
      label = 'Closed';
      icon = Icons.access_time;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTheme.bodyMedium.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey[700]),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTheme.bodyMedium.copyWith(
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getTypeIcon() {
    switch (classroomModel.type) {
      case ClassroomType.lab:
        return Icons.computer;
      case ClassroomType.classroom:
        return Icons.school;
      case ClassroomType.auditorium:
        return Icons.groups;
    }
  }

  Color _getTypeColor() {
    switch (classroomModel.type) {
      case ClassroomType.lab:
        return Colors.blue;
      case ClassroomType.classroom:
        return Colors.green;
      case ClassroomType.auditorium:
        return Colors.purple;
    }
  }

  String _getTypeLabel() {
    switch (classroomModel.type) {
      case ClassroomType.lab:
        return 'Computer Lab';
      case ClassroomType.classroom:
        return 'Classroom';
      case ClassroomType.auditorium:
        return 'Auditorium';
    }
  }

  void _showClassroomDetails(BuildContext context) {
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
                const SizedBox(height: 20),

                // Title
                Row(
                  children: [
                    Icon(_getTypeIcon(), color: _getTypeColor(), size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            classroomModel.roomName,
                            style: AppTheme.headlineMedium,
                          ),
                          Text(
                            'Floor ${classroomModel.floor} • ${_getTypeLabel()}',
                            style: AppTheme.bodyLarge.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Details
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    children: [
                      _buildDetailRow(
                        'Capacity',
                        '${classroomModel.capacity} seats',
                      ),
                      _buildDetailRow(
                        'Operating Hours',
                        classroomModel.operatingHours,
                      ),
                      _buildDetailRow(
                        'Availability',
                        classroomModel.isAvailable
                            ? 'Available'
                            : 'Unavailable',
                      ),

                      if (classroomModel.isUnderMaintenance) ...[
                        _buildDetailRow('Status', 'Under Maintenance'),
                        if (classroomModel.maintenanceStart != null)
                          _buildDetailRow(
                            'Maintenance Start',
                            _formatTime(classroomModel.maintenanceStart!),
                          ),
                        if (classroomModel.maintenanceEnd != null)
                          _buildDetailRow(
                            'Maintenance End',
                            _formatTime(classroomModel.maintenanceEnd!),
                          ),
                      ],

                      if (classroomModel.blackoutDays.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text('Blackout Days', style: AppTheme.titleLarge),
                        const SizedBox(height: 8),
                        ...classroomModel.blackoutDays.map(
                          (date) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              '• ${_formatDate(date)}',
                              style: AppTheme.bodyLarge,
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 16),
                      _buildDetailRow(
                        'Created',
                        _formatDate(classroomModel.createdAt),
                      ),
                      _buildDetailRow(
                        'Last Updated',
                        _formatDate(classroomModel.updatedAt),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: AppTheme.bodyMedium.copyWith(
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTheme.bodyLarge,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
