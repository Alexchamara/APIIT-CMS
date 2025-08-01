import 'dart:async';
import 'package:apiit_cms/features/auth/domain/models/user_model.dart';
import 'package:apiit_cms/features/users/domain/models/user_filter.dart';
import 'package:apiit_cms/features/users/domain/usecases/user_usecases.dart';
import 'package:apiit_cms/features/users/presentation/cubit/user_management_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class UserManagementCubit extends Cubit<UserManagementState> {
  final GetUsersStreamUseCase _getUsersStreamUseCase;
  final CreateUserUseCase _createUserUseCase;
  final UpdateUserUseCase _updateUserUseCase;
  final DeleteUserUseCase _deleteUserUseCase;

  StreamSubscription<List<UserModel>>? _usersSubscription;
  List<UserModel> _allUsers = [];
  UserFilter _currentFilter = UserFilter.admins;
  String _searchQuery = '';

  UserManagementCubit({
    required GetUsersStreamUseCase getUsersStreamUseCase,
    required CreateUserUseCase createUserUseCase,
    required UpdateUserUseCase updateUserUseCase,
    required DeleteUserUseCase deleteUserUseCase,
  }) : _getUsersStreamUseCase = getUsersStreamUseCase,
       _createUserUseCase = createUserUseCase,
       _updateUserUseCase = updateUserUseCase,
       _deleteUserUseCase = deleteUserUseCase,
       super(UserManagementInitial());

  void loadUsers() {
    emit(UserManagementLoading());

    _usersSubscription?.cancel();
    _usersSubscription = _getUsersStreamUseCase().listen(
      (users) {
        _allUsers = users;
        _applyFilters();
      },
      onError: (error) {
        emit(UserManagementError(error.toString()));
      },
    );
  }

  void setFilter(UserFilter filter) {
    _currentFilter = filter;
    _applyFilters();
  }

  void searchUsers(String query) {
    _searchQuery = query.toLowerCase();
    _applyFilters();
  }

  void _applyFilters() {
    List<UserModel> filtered = _allUsers;

    // Apply user type filter
    switch (_currentFilter) {
      case UserFilter.admins:
        filtered = filtered
            .where((user) => user.userType == UserType.admin)
            .toList();
        break;
      case UserFilter.lecturers:
        filtered = filtered
            .where((user) => user.userType == UserType.lecturer)
            .toList();
        break;
      case UserFilter.all:
        // No filter needed
        break;
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((user) {
        return user.displayName.toLowerCase().contains(_searchQuery) ||
            user.email.toLowerCase().contains(_searchQuery);
      }).toList();
    }

    emit(
      UserManagementLoaded(
        users: _allUsers,
        filteredUsers: filtered,
        currentFilter: _currentFilter,
        searchQuery: _searchQuery,
      ),
    );
  }

  Future<void> createUser({
    required String email,
    required String displayName,
    required UserType userType,
    String? phoneNumber,
  }) async {
    try {
      emit(UserCreating());

      final user = await _createUserUseCase(
        email: email,
        displayName: displayName,
        userType: userType,
        phoneNumber: phoneNumber,
      );

      if (user != null) {
        emit(UserCreated(user));
        // The stream will automatically update the list
      } else {
        emit(const UserManagementError('Failed to create user'));
      }
    } catch (e) {
      emit(UserManagementError(e.toString()));
    }
  }

  Future<void> updateUser(UserModel user) async {
    try {
      emit(UserUpdating());

      await _updateUserUseCase(user);
      emit(UserUpdated(user));
      // The stream will automatically update the list
    } catch (e) {
      emit(UserManagementError(e.toString()));
    }
  }

  Future<void> deleteUser(String uid) async {
    try {
      emit(UserDeleting());

      await _deleteUserUseCase(uid);
      emit(UserDeleted(uid));
      // The stream will automatically update the list
    } catch (e) {
      emit(UserManagementError(e.toString()));
    }
  }

  @override
  Future<void> close() {
    _usersSubscription?.cancel();
    return super.close();
  }
}
