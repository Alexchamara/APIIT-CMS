import 'package:apiit_cms/features/auth/domain/models/user_model.dart';

abstract class ProfileState {}

class ProfileInitial extends ProfileState {}

class ProfileLoading extends ProfileState {}

class ProfileLoaded extends ProfileState {
  final UserModel user;

  ProfileLoaded(this.user);
}

class ProfileUpdateSuccess extends ProfileState {
  final String message;

  ProfileUpdateSuccess(this.message);
}

class ProfilePasswordResetSuccess extends ProfileState {
  final String message;

  ProfilePasswordResetSuccess(this.message);
}

class ProfileError extends ProfileState {
  final String message;

  ProfileError(this.message);
}
