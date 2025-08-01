import 'package:apiit_cms/features/auth/data/auth_repository.dart';
import 'package:apiit_cms/features/auth/domain/models/user_model.dart';
import 'package:apiit_cms/features/class/presentation/screens/classes_screen.dart';
import 'package:apiit_cms/features/reservations/presentation/screens/reservations_screen.dart';
import 'package:apiit_cms/shared/theme.dart';
import 'package:flutter/material.dart';

class ManagementScreen extends StatefulWidget {
  const ManagementScreen({super.key});

  @override
  State<ManagementScreen> createState() => _ManagementScreenState();
}

class _ManagementScreenState extends State<ManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  UserModel? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    _currentUser = await AuthRepository.getCurrentUserModel();
    setState(() {
      _isLoading = false;
    });
  }

  bool get _isAdmin => _currentUser?.userType == UserType.admin;

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Only show management screen for admins
    if (!_isAdmin) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.admin_panel_settings_outlined,
                size: 64,
                color: Colors.grey,
              ),
              SizedBox(height: 16),
              Text(
                'Access Denied',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'This section is only available for administrators',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Management'),
        backgroundColor: AppTheme.primary,
        foregroundColor: AppTheme.white,
        elevation: 0,
        bottom: TabBar(
          dividerColor: Colors.transparent,
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.event_note),
              text: 'Reservations',
            ),
            Tab(
              icon: Icon(Icons.school),
              text: 'Classrooms',
            ),
          ],
          indicatorColor: AppTheme.white,
          labelColor: AppTheme.white,
          unselectedLabelColor: AppTheme.white.withOpacity(0.7),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          ReservationsScreen(showAppBar: false),
          ClassroomsScreen(showAppBar: false),
        ],
      ),
    );
  }
}
