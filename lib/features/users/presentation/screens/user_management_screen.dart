import 'package:apiit_cms/features/auth/data/auth_repository.dart';
import 'package:apiit_cms/features/auth/domain/models/user_model.dart';
import 'package:apiit_cms/features/users/data/repositories/user_repository_impl.dart';
import 'package:apiit_cms/features/users/domain/models/user_filter.dart';
import 'package:apiit_cms/features/users/domain/usecases/user_usecases.dart';
import 'package:apiit_cms/features/users/presentation/cubit/user_management_cubit.dart';
import 'package:apiit_cms/features/users/presentation/cubit/user_management_state.dart';
import 'package:apiit_cms/features/users/presentation/screens/add_user_screen.dart';
import 'package:apiit_cms/features/users/presentation/screens/user_edit_screen.dart';
import 'package:apiit_cms/features/users/presentation/widgets/user_list_item.dart';
import 'package:apiit_cms/shared/theme.dart';
import 'package:apiit_cms/shared/widgets/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class UserManagementScreen extends StatelessWidget {
  const UserManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final repository = UserRepositoryImpl();
        return UserManagementCubit(
          getUsersStreamUseCase: GetUsersStreamUseCase(repository),
          createUserUseCase: CreateUserUseCase(repository),
          updateUserUseCase: UpdateUserUseCase(repository),
          deleteUserUseCase: DeleteUserUseCase(repository),
        )..loadUsers();
      },
      child: const UserManagementView(),
    );
  }
}

class UserManagementView extends StatefulWidget {
  const UserManagementView({super.key});

  @override
  State<UserManagementView> createState() => _UserManagementViewState();
}

class _UserManagementViewState extends State<UserManagementView> {
  final TextEditingController _searchController = TextEditingController();
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool get _isAdmin => _currentUser?.userType == UserType.admin;

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
      return const Scaffold(
        backgroundColor: AppTheme.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock, size: 64, color: AppTheme.grey),
              SizedBox(height: 16),
              Text('Access Denied', style: AppTheme.headlineMedium),
              SizedBox(height: 8),
              Text(
                'You need admin privileges to access this screen.',
                style: AppTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.white,
      appBar: AppBarStyles.primary(
        title: 'User Management',
        showBackButton: false,
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSearchBar(),
            _buildFilterTabs(),
            Expanded(child: _buildUsersList()),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddUserScreen(context),
        backgroundColor: AppTheme.primary,
        foregroundColor: AppTheme.white,
        icon: const Icon(Icons.person_add),
        label: const Text('Add new user'),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          context.read<UserManagementCubit>().searchUsers(value);
        },
        decoration: InputDecoration(
          hintText: 'Search',
          prefixIcon: const Icon(Icons.search, color: AppTheme.grey),
          filled: true,
          fillColor: AppTheme.lightGrey,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterTabs() {
    return BlocBuilder<UserManagementCubit, UserManagementState>(
      builder: (context, state) {
        final currentFilter = state is UserManagementLoaded
            ? state.currentFilter
            : UserFilter.admins;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              _buildFilterChip(
                label: 'Admins',
                isSelected: currentFilter == UserFilter.admins,
                onTap: () => context.read<UserManagementCubit>().setFilter(
                  UserFilter.admins,
                ),
              ),
              const SizedBox(width: 12),
              _buildFilterChip(
                label: 'Lecturers',
                isSelected: currentFilter == UserFilter.lecturers,
                onTap: () => context.read<UserManagementCubit>().setFilter(
                  UserFilter.lecturers,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.grey,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppTheme.white : AppTheme.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildUsersList() {
    return BlocBuilder<UserManagementCubit, UserManagementState>(
      builder: (context, state) {
        if (state is UserManagementLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is UserManagementError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: AppTheme.error),
                const SizedBox(height: 16),
                Text('Error loading users', style: AppTheme.headlineMedium),
                const SizedBox(height: 8),
                Text(
                  state.message,
                  style: AppTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () =>
                      context.read<UserManagementCubit>().loadUsers(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (state is UserManagementLoaded) {
          if (state.filteredUsers.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.people_outline,
                    size: 64,
                    color: AppTheme.grey,
                  ),
                  const SizedBox(height: 16),
                  Text('No users found', style: AppTheme.headlineMedium),
                  const SizedBox(height: 8),
                  Text(
                    state.searchQuery.isNotEmpty
                        ? 'Try adjusting your search'
                        : 'No ${state.currentFilter.displayName.toLowerCase()} yet',
                    style: AppTheme.bodyMedium,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: state.filteredUsers.length,
            itemBuilder: (context, index) {
              final user = state.filteredUsers[index];
              return UserListItem(
                user: user,
                onTap: () => _showUserDetails(context, user),
              );
            },
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  void _showAddUserScreen(BuildContext context) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (context) => const AddUserScreen()),
    );

    // If user was created, refresh the list
    if (result == true) {
      if (mounted) {
        context.read<UserManagementCubit>().loadUsers();
      }
    }
  }

  void _showUserDetails(BuildContext context, UserModel user) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (context) => UserEditScreen(user: user)),
    );

    // If user was deleted or updated, refresh the list
    if (result == true) {
      if (mounted) {
        context.read<UserManagementCubit>().loadUsers();
      }
    }
  }
}
