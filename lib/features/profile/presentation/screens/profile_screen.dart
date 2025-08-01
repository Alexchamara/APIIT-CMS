import 'package:apiit_cms/features/auth/data/auth_repository.dart';
import 'package:apiit_cms/features/auth/domain/models/user_model.dart';
import 'package:apiit_cms/shared/theme.dart';
import 'package:apiit_cms/shared/widgets/primary_button.dart';
import 'package:apiit_cms/shared/widgets/user_profile_widget.dart';
import 'package:flutter/material.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserModel? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final user = await AuthRepository.getCurrentUserModel();
      if (mounted) {
        setState(() {
          _currentUser = user;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load user profile')),
        );
      }
    }
  }

  Future<void> _signOut() async {
    try {
      await AuthRepository.signOut();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to sign out')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: AppTheme.primary,
        foregroundColor: AppTheme.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _currentUser == null
          ? const Center(child: Text('Failed to load profile'))
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User Profile Section
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: UserProfileWidget(user: _currentUser!, size: 80),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // User Details
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Account Information',
                            style: AppTheme.titleLarge,
                          ),
                          const SizedBox(height: 16),
                          _buildInfoRow('User ID', _currentUser!.uid),
                          const SizedBox(height: 12),
                          _buildInfoRow('Email', _currentUser!.email),
                          const SizedBox(height: 12),
                          _buildInfoRow(
                            'User Type',
                            _currentUser!.userType.name.toUpperCase(),
                          ),
                          const SizedBox(height: 12),
                          _buildInfoRow(
                            'Status',
                            _currentUser!.isActive ? 'Active' : 'Inactive',
                          ),
                          const SizedBox(height: 12),
                          _buildInfoRow(
                            'Created',
                            _formatDate(_currentUser!.createdAt),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Sign Out Button
                  SizedBox(
                    width: double.infinity,
                    child: PrimaryButton(
                      onPressed: _signOut,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.logout, size: 20),
                          SizedBox(width: 8),
                          Text('Sign Out'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        const Text(': ', style: AppTheme.bodyMedium),
        Expanded(child: Text(value, style: AppTheme.bodyLarge)),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
