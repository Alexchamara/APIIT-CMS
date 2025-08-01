import 'package:apiit_cms/features/auth/domain/models/user_model.dart';
import 'package:apiit_cms/features/users/domain/models/user_filter.dart';
import 'package:equatable/equatable.dart';

abstract class UserManagementState extends Equatable {
  const UserManagementState();

  @override
  List<Object?> get props => [];
}

class UserManagementInitial extends UserManagementState {}

class UserManagementLoading extends UserManagementState {}

class UserManagementLoaded extends UserManagementState {
  final List<UserModel> users;
  final List<UserModel> filteredUsers;
  final UserFilter currentFilter;
  final String searchQuery;

  const UserManagementLoaded({
    required this.users,
    required this.filteredUsers,
    required this.currentFilter,
    required this.searchQuery,
  });

  @override
  List<Object?> get props => [users, filteredUsers, currentFilter, searchQuery];

  UserManagementLoaded copyWith({
    List<UserModel>? users,
    List<UserModel>? filteredUsers,
    UserFilter? currentFilter,
    String? searchQuery,
  }) {
    return UserManagementLoaded(
      users: users ?? this.users,
      filteredUsers: filteredUsers ?? this.filteredUsers,
      currentFilter: currentFilter ?? this.currentFilter,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class UserManagementError extends UserManagementState {
  final String message;

  const UserManagementError(this.message);

  @override
  List<Object?> get props => [message];
}

class UserCreating extends UserManagementState {}

class UserCreated extends UserManagementState {
  final UserModel user;

  const UserCreated(this.user);

  @override
  List<Object?> get props => [user];
}

class UserUpdating extends UserManagementState {}

class UserUpdated extends UserManagementState {
  final UserModel user;

  const UserUpdated(this.user);

  @override
  List<Object?> get props => [user];
}

class UserDeleting extends UserManagementState {}

class UserDeleted extends UserManagementState {
  final String uid;

  const UserDeleted(this.uid);

  @override
  List<Object?> get props => [uid];
}
