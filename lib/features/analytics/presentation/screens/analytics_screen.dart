import 'package:flutter/material.dart';
import 'package:apiit_cms/features/analytics/data/analytics_repository.dart';
import 'package:apiit_cms/features/analytics/domain/models/analytics_data.dart';
import 'package:apiit_cms/features/analytics/presentation/widgets/analytics_widgets.dart';
import 'package:apiit_cms/shared/theme.dart';
import 'package:apiit_cms/shared/widgets/custom_app_bar.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  AnalyticsData? _analyticsData;
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAnalytics();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAnalytics() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final data = await AnalyticsRepository.getAnalyticsData();
      
      setState(() {
        _analyticsData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBarStyles.primary(
        title: 'Analytics',
        showBackButton: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnalytics,
            tooltip: 'Refresh Analytics',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppTheme.primary),
                  SizedBox(height: 16),
                  Text(
                    'Loading analytics...',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            )
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: AppTheme.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading analytics',
                        style: AppTheme.headlineMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _errorMessage,
                        textAlign: TextAlign.center,
                        style: AppTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadAnalytics,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Container(
                      color: AppTheme.white,
                      child: TabBar(
                        controller: _tabController,
                        labelColor: AppTheme.primary,
                        dividerColor: Colors.transparent,
                        unselectedLabelColor: AppTheme.textSecondary,
                        indicatorColor: AppTheme.primary,
                        tabs: const [
                          Tab(
                            icon: Icon(Icons.desk),
                            text: 'Classrooms',
                          ),
                          Tab(
                            icon: Icon(Icons.book),
                            text: 'Reservations',
                          ),
                          Tab(
                            icon: Icon(Icons.people),
                            text: 'Users',
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildClassroomAnalytics(),
                          _buildReservationAnalytics(),
                          _buildUserAnalytics(),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildClassroomAnalytics() {
    if (_analyticsData == null) return const SizedBox.shrink();
    
    final classrooms = _analyticsData!.classrooms;
    
    return RefreshIndicator(
      onRefresh: _loadAnalytics,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Overview Cards
            Text(
              'Overview',
              style: AppTheme.titleLarge.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.2,
              children: [
                StatCard(
                  title: 'Total Classrooms',
                  value: classrooms.totalClassrooms.toString(),
                  icon: Icons.desk,
                  iconColor: AppTheme.primary,
                ),
                StatCard(
                  title: 'Available',
                  value: classrooms.availableClassrooms.toString(),
                  icon: Icons.check_circle,
                  iconColor: AppTheme.success,
                ),
                StatCard(
                  title: 'Unavailable',
                  value: classrooms.unavailableClassrooms.toString(),
                  icon: Icons.cancel,
                  iconColor: AppTheme.error,
                ),
                StatCard(
                  title: 'Maintenance',
                  value: classrooms.maintenanceClassrooms.toString(),
                  icon: Icons.build,
                  iconColor: Colors.orange,
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Capacity Information
            Text(
              'Capacity',
              style: AppTheme.titleLarge.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    title: 'Total Capacity',
                    value: classrooms.totalCapacity.toString(),
                    subtitle: 'seats across all classrooms',
                    icon: Icons.event_seat,
                    iconColor: AppTheme.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: StatCard(
                    title: 'Average Capacity',
                    value: classrooms.averageCapacity.toStringAsFixed(0),
                    subtitle: 'seats per classroom',
                    icon: Icons.analytics,
                    iconColor: AppTheme.secondary,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Availability Rate
            PercentageCard(
              title: 'Availability Rate',
              percentage: classrooms.availabilityRate,
              description: '${classrooms.availableClassrooms} out of ${classrooms.totalClassrooms} classrooms are available',
              icon: Icons.schedule,
              color: AppTheme.success,
            ),
            
            const SizedBox(height: 24),
            
            // Distribution Charts
            Text(
              'Distribution',
              style: AppTheme.titleLarge.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: TopItemsList(
                    title: 'By Type',
                    items: classrooms.classroomsByType,
                    icon: Icons.category,
                    color: AppTheme.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TopItemsList(
                    title: 'By Floor',
                    items: classrooms.classroomsByFloor,
                    icon: Icons.layers,
                    color: AppTheme.secondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReservationAnalytics() {
    if (_analyticsData == null) return const SizedBox.shrink();
    
    final reservations = _analyticsData!.reservations;
    
    return RefreshIndicator(
      onRefresh: _loadAnalytics,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Overview Cards
            Text(
              'Overview',
              style: AppTheme.titleLarge.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.2,
              children: [
                StatCard(
                  title: 'Total Reservations',
                  value: reservations.totalReservations.toString(),
                  icon: Icons.book,
                  iconColor: AppTheme.primary,
                ),
                StatCard(
                  title: 'Approved',
                  value: reservations.approvedReservations.toString(),
                  icon: Icons.check_circle,
                  iconColor: AppTheme.success,
                ),
                StatCard(
                  title: 'Pending',
                  value: reservations.pendingReservations.toString(),
                  icon: Icons.pending,
                  iconColor: Colors.orange,
                ),
                StatCard(
                  title: 'Cancelled',
                  value: reservations.cancelledReservations.toString(),
                  icon: Icons.cancel,
                  iconColor: AppTheme.error,
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Rates
            Text(
              'Performance Metrics',
              style: AppTheme.titleLarge.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            Column(
              children: [
                PercentageCard(
                  title: 'Approval Rate',
                  percentage: reservations.approvalRate,
                  description: '${reservations.approvedReservations} out of ${reservations.totalReservations} reservations approved',
                  icon: Icons.thumb_up,
                  color: AppTheme.success,
                ),
                const SizedBox(height: 16),
                PercentageCard(
                  title: 'Cancellation Rate',
                  percentage: reservations.cancellationRate,
                  description: '${reservations.cancelledReservations} out of ${reservations.totalReservations} reservations cancelled',
                  icon: Icons.thumb_down,
                  color: AppTheme.error,
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Activity
            StatCard(
              title: 'Daily Average',
              value: reservations.averageReservationsPerDay.toStringAsFixed(1),
              subtitle: 'reservations per day (last 30 days)',
              icon: Icons.today,
              iconColor: AppTheme.secondary,
            ),
            
            const SizedBox(height: 24),
            
            // Distribution
            Text(
              'Distribution',
              style: AppTheme.titleLarge.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            TopItemsList(
              title: 'By Reservation Type',
              items: reservations.reservationsByType,
              icon: Icons.category,
              color: AppTheme.primary,
            ),
            
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: TopItemsList(
                    title: 'Most Booked Classrooms',
                    items: reservations.mostBookedClassrooms,
                    icon: Icons.star,
                    color: Colors.amber[700],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TopItemsList(
                    title: 'Active Lecturers',
                    items: reservations.activeLecturers,
                    icon: Icons.person,
                    color: AppTheme.secondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserAnalytics() {
    if (_analyticsData == null) return const SizedBox.shrink();
    
    final users = _analyticsData!.users;
    
    return RefreshIndicator(
      onRefresh: _loadAnalytics,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Overview Cards
            Text(
              'Overview',
              style: AppTheme.titleLarge.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.2,
              children: [
                StatCard(
                  title: 'Total Users',
                  value: users.totalUsers.toString(),
                  icon: Icons.people,
                  iconColor: AppTheme.primary,
                ),
                StatCard(
                  title: 'Administrators',
                  value: users.adminUsers.toString(),
                  icon: Icons.admin_panel_settings,
                  iconColor: Colors.purple,
                ),
                StatCard(
                  title: 'Lecturers',
                  value: users.lecturerUsers.toString(),
                  icon: Icons.school,
                  iconColor: AppTheme.secondary,
                ),
                StatCard(
                  title: 'Active Users',
                  value: users.activeUsers.toString(),
                  icon: Icons.check_circle,
                  iconColor: AppTheme.success,
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // User Distribution
            Text(
              'User Distribution',
              style: AppTheme.titleLarge.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            Column(
              children: [
                PercentageCard(
                  title: 'Administrator Percentage',
                  percentage: users.adminPercentage,
                  description: '${users.adminUsers} out of ${users.totalUsers} users are administrators',
                  icon: Icons.admin_panel_settings,
                  color: Colors.purple,
                ),
                const SizedBox(height: 16),
                PercentageCard(
                  title: 'Lecturer Percentage',
                  percentage: users.lecturerPercentage,
                  description: '${users.lecturerUsers} out of ${users.totalUsers} users are lecturers',
                  icon: Icons.school,
                  color: AppTheme.secondary,
                ),
                const SizedBox(height: 16),
                PercentageCard(
                  title: 'Active User Rate',
                  percentage: users.activeUserRate,
                  description: '${users.activeUsers} out of ${users.totalUsers} users are active',
                  icon: Icons.trending_up,
                  color: AppTheme.success,
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Most Active User
            if (users.mostActiveUser != 'None') ...[
              Text(
                'Activity Leader',
                style: AppTheme.titleLarge.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              StatCard(
                title: 'Most Active User',
                value: users.mostActiveUser,
                subtitle: '${users.mostActiveUserReservations} reservations',
                icon: Icons.star,
                iconColor: Colors.amber[700],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
