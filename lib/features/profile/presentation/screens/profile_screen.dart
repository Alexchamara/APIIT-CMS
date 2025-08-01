import 'package:apiit_cms/features/auth/domain/models/user_model.dart';
import 'package:apiit_cms/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:apiit_cms/features/profile/presentation/cubit/profile_state.dart';
import 'package:apiit_cms/features/users/data/repositories/user_repository_impl.dart';
import 'package:apiit_cms/features/users/domain/usecases/user_usecases.dart';
import 'package:apiit_cms/shared/theme.dart';
import 'package:apiit_cms/shared/widgets/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final repository = UserRepositoryImpl();
        return ProfileCubit(updateUserUseCase: UpdateUserUseCase(repository))
          ..loadCurrentUser();
      },
      child: const ProfileView(),
    );
  }
}

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  bool _isEditing = false;
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _updateControllers(UserModel user) {
    _nameController.text = user.displayName;
    _emailController.text = user.email;
    _phoneController.text = user.phoneNumber ?? '';
    _currentUser = user;
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProfileCubit, ProfileState>(
      listener: (context, state) {
        if (state is ProfileUpdateSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppTheme.success,
            ),
          );
          setState(() {
            _isEditing = false;
          });
        } else if (state is ProfilePasswordResetSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppTheme.success,
            ),
          );
        } else if (state is ProfileError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppTheme.error,
            ),
          );
        } else if (state is ProfileLoaded) {
          _updateControllers(state.user);
        }
      },
      child: BlocBuilder<ProfileCubit, ProfileState>(
        builder: (context, state) {
          final currentUser = state is ProfileLoaded
              ? state.user
              : _currentUser;

          return Scaffold(
            backgroundColor: AppTheme.white,
            appBar: AppBarStyles.primary(
              title: _isEditing ? 'Edit Profile' : 'My Profile',
              showBackButton: false,
              actions: [
                if (!_isEditing && currentUser != null)
                  IconButton(
                    icon: const Icon(Icons.edit, color: AppTheme.white),
                    onPressed: () {
                      setState(() {
                        _isEditing = true;
                      });
                    },
                  ),
              ],
            ),
            body: BlocBuilder<ProfileCubit, ProfileState>(
              builder: (context, state) {
                if (state is ProfileLoading && _currentUser == null) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is ProfileError && _currentUser == null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error,
                          size: 64,
                          color: AppTheme.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading profile',
                          style: AppTheme.headlineMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          state.message,
                          style: AppTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () =>
                              context.read<ProfileCubit>().loadCurrentUser(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                // Set current user from state if available
                if (state is ProfileLoaded && _currentUser == null) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _updateControllers(state.user);
                  });
                }

                if (_currentUser == null) {
                  return const Center(child: CircularProgressIndicator());
                }

                final isLoading = state is ProfileLoading;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildProfileSection(),
                        const SizedBox(height: 32),
                        _buildFormFields(isLoading),
                        const SizedBox(height: 32),
                        if (_isEditing) _buildActionButtons(isLoading),
                        if (!_isEditing) _buildSignOutButton(isLoading),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileSection() {
    if (_currentUser == null) return const SizedBox.shrink();

    // Extract initials from display name
    String initials = _currentUser!.displayName
        .split(' ')
        .map((name) => name.isNotEmpty ? name[0].toUpperCase() : '')
        .take(2)
        .join();

    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: const BoxDecoration(
            color: AppTheme.primary,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              initials,
              style: const TextStyle(
                color: AppTheme.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          _currentUser!.displayName,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _currentUser!.email,
          style: const TextStyle(fontSize: 16, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: _currentUser!.userType == UserType.admin
                ? AppTheme.primary.withValues(alpha: 0.1)
                : AppTheme.secondary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            _currentUser!.userType == UserType.admin ? 'Admin' : 'Lecturer',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _currentUser!.userType == UserType.admin
                  ? AppTheme.primary
                  : AppTheme.secondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFormFields(bool isLoading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Name field - always visible, editable when editing
        _buildEditableField(
          controller: _nameController,
          label: 'Name',
          enabled: _isEditing && !isLoading,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Name is required';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        // Phone field - always visible, editable when editing
        _buildEditableField(
          controller: _phoneController,
          label: 'Phone',
          enabled: _isEditing && !isLoading,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 16),

        // Non-editable information fields
        _buildInfoField('Email', _currentUser!.email),
        const SizedBox(height: 16),
        _buildInfoField(
          'Role',
          _currentUser!.userType == UserType.admin ? 'Admin' : 'Lecturer',
        ),
        const SizedBox(height: 16),
        _buildInfoField(
          'Account Status',
          _currentUser!.isActive ? 'Active' : 'Inactive',
        ),
        const SizedBox(height: 16),
        _buildInfoField('Member Since', _formatDate(_currentUser!.createdAt)),

        // Reset password section
        if (!_isEditing) ...[
          const SizedBox(height: 24),
          _buildResetPasswordSection(isLoading),
        ],
      ],
    );
  }

  Widget _buildEditableField({
    required TextEditingController controller,
    required String label,
    bool enabled = true,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        if (_isEditing)
          TextFormField(
            controller: controller,
            enabled: enabled,
            keyboardType: keyboardType,
            validator: validator,
            decoration: InputDecoration(
              filled: true,
              fillColor: enabled ? AppTheme.white : AppTheme.lightGrey,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppTheme.grey),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppTheme.grey),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppTheme.primary, width: 2),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppTheme.lightGrey),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.grey, width: 1),
            ),
            child: Text(
              controller.text.isEmpty ? 'Not provided' : controller.text,
              style: TextStyle(
                fontSize: 16,
                color: controller.text.isEmpty
                    ? AppTheme.textSecondary
                    : AppTheme.textPrimary,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInfoField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.grey, width: 1),
          ),
          child: Text(
            value,
            style: const TextStyle(fontSize: 16, color: AppTheme.textPrimary),
          ),
        ),
      ],
    );
  }

  Widget _buildResetPasswordSection(bool isLoading) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.grey.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.security, color: AppTheme.primary, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Password',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Change your password by receiving a reset link via email',
            style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: isLoading ? null : _sendPasswordResetEmail,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primary,
                side: const BorderSide(color: AppTheme.primary),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.email, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Send Reset Link',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(bool isLoading) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isLoading ? null : _saveProfile,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: AppTheme.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.white),
                    ),
                  )
                : const Text(
                    'Save changes',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: isLoading
                ? null
                : () {
                    setState(() {
                      _isEditing = false;
                      // Reset form fields to original values
                      if (_currentUser != null) {
                        _updateControllers(_currentUser!);
                      }
                    });
                  },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.textPrimary,
              side: const BorderSide(color: AppTheme.grey),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Cancel',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSignOutButton(bool isLoading) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: isLoading ? null : _showSignOutConfirmation,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.error,
          side: const BorderSide(color: AppTheme.error),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout, size: 20),
            SizedBox(width: 8),
            Text(
              'Sign Out',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  void _saveProfile() {
    if (_formKey.currentState!.validate() && _currentUser != null) {
      final updatedUser = _currentUser!.copyWith(
        displayName: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
      );

      context.read<ProfileCubit>().updateProfile(updatedUser);
    }
  }

  void _sendPasswordResetEmail() {
    if (_currentUser != null) {
      context.read<ProfileCubit>().sendPasswordResetEmail(_currentUser!.email);
    }
  }

  void _showSignOutConfirmation() {
    // Store reference to the cubit before showing dialog
    final profileCubit = context.read<ProfileCubit>();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Sign Out'),
          content: const Text('Are you sure you want to sign out?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                // Use the stored cubit reference instead of trying to read from dialog context
                profileCubit.signOut();
              },
              style: TextButton.styleFrom(foregroundColor: AppTheme.error),
              child: const Text('Sign Out'),
            ),
          ],
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
