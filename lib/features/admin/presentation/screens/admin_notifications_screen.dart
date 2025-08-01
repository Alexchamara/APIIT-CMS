import 'package:flutter/material.dart';
import 'package:apiit_cms/shared/models/admin_notification_model.dart';
import 'package:apiit_cms/shared/repositories/admin_notification_repository.dart';
import 'package:apiit_cms/shared/theme.dart';

class AdminNotificationsScreen extends StatefulWidget {
  const AdminNotificationsScreen({super.key});

  @override
  State<AdminNotificationsScreen> createState() =>
      _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState extends State<AdminNotificationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, int> _stats = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadStats();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    final stats = await AdminNotificationRepository.getNotificationStats();
    if (mounted) {
      setState(() {
        _stats = stats;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.white,
      appBar: AppBar(
        title: Text(
          'Admin Notifications',
          style: AppTheme.headlineMedium.copyWith(
            color: AppTheme.white,
            fontSize: 20,
          ),
        ),
        backgroundColor: AppTheme.primary,
        foregroundColor: AppTheme.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.white,
          unselectedLabelColor: AppTheme.white.withOpacity(0.7),
          indicatorColor: AppTheme.white,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Support'),
            Tab(text: 'Reservations'),
            Tab(text: 'Recent'),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildStatsCard(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildNotificationsList(
                  AdminNotificationRepository.getAllNotifications(),
                ),
                _buildNotificationsList(
                  AdminNotificationRepository.getNotificationsByType(
                    'support_ticket',
                  ),
                ),
                _buildNotificationsList(
                  AdminNotificationRepository.getNotificationsByType(
                    'reservation',
                  ),
                ),
                _buildNotificationsList(
                  AdminNotificationRepository.getRecentNotifications(),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _cleanupOldNotifications,
        backgroundColor: AppTheme.primary,
        foregroundColor: AppTheme.white,
        icon: const Icon(Icons.cleaning_services),
        label: const Text('Cleanup'),
      ),
    );
  }

  Widget _buildStatsCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppTheme.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Notification Statistics',
            style: AppTheme.headlineMedium.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Today Total',
                  _stats['today_total']?.toString() ?? '0',
                  Icons.today,
                  AppTheme.primary,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Sent',
                  _stats['today_sent']?.toString() ?? '0',
                  Icons.check_circle,
                  Colors.green,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Failed',
                  _stats['today_failed']?.toString() ?? '0',
                  Icons.error,
                  Colors.red,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'This Week',
                  _stats['week_total']?.toString() ?? '0',
                  Icons.date_range,
                  AppTheme.secondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTheme.headlineMedium.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: AppTheme.bodyMedium.copyWith(color: AppTheme.grey),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildNotificationsList(Stream<List<AdminNotificationModel>> stream) {
    return StreamBuilder<List<AdminNotificationModel>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: AppTheme.bodyMedium.copyWith(color: Colors.red),
            ),
          );
        }

        final notifications = snapshot.data ?? [];

        if (notifications.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.notifications_off, size: 64, color: AppTheme.grey),
                SizedBox(height: 16),
                Text('No notifications found', style: AppTheme.bodyLarge),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            final notification = notifications[index];
            return _buildNotificationCard(notification);
          },
        );
      },
    );
  }

  Widget _buildNotificationCard(AdminNotificationModel notification) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildTypeIcon(notification.type),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.title,
                        style: AppTheme.titleLarge.copyWith(fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.body,
                        style: AppTheme.bodyMedium.copyWith(
                          color: AppTheme.grey,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(notification),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: AppTheme.grey),
                const SizedBox(width: 4),
                Text(
                  '${notification.formattedDate} ${notification.formattedTime}',
                  style: AppTheme.bodyMedium.copyWith(color: AppTheme.grey),
                ),
                const Spacer(),
                if (notification.isFailed)
                  TextButton.icon(
                    onPressed: () => _retryNotification(notification.id),
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Retry'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
              ],
            ),
            if (notification.data.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildDataChips(notification.data),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTypeIcon(String type) {
    IconData icon;
    Color color;

    switch (type) {
      case 'support_ticket':
        icon = Icons.support_agent;
        color = AppTheme.primary;
        break;
      case 'reservation':
        icon = Icons.event_seat;
        color = AppTheme.secondary;
        break;
      default:
        icon = Icons.notifications;
        color = AppTheme.grey;
    }

    return CircleAvatar(
      radius: 20,
      backgroundColor: color.withOpacity(0.1),
      child: Icon(icon, color: color, size: 20),
    );
  }

  Widget _buildStatusChip(AdminNotificationModel notification) {
    Color color;
    String label;
    IconData icon;

    if (notification.isSuccess) {
      color = Colors.green;
      label = 'Sent';
      icon = Icons.check;
    } else if (notification.isFailed) {
      color = Colors.red;
      label = 'Failed';
      icon = Icons.error;
    } else {
      color = Colors.orange;
      label = 'Pending';
      icon = Icons.schedule;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTheme.bodyMedium.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataChips(Map<String, String> data) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: data.entries
          .where((entry) => entry.value.isNotEmpty)
          .map(
            (entry) => Chip(
              label: Text(
                '${entry.key}: ${entry.value}',
                style: AppTheme.bodyMedium.copyWith(fontSize: 12),
              ),
              backgroundColor: AppTheme.grey.withOpacity(0.1),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          )
          .toList(),
    );
  }

  Future<void> _retryNotification(String notificationId) async {
    try {
      await AdminNotificationRepository.retryFailedNotification(notificationId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification retry initiated'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to retry notification: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _cleanupOldNotifications() async {
    try {
      await AdminNotificationRepository.cleanupOldNotifications();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Old notifications cleaned up successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _loadStats(); // Refresh stats
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to cleanup notifications: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
