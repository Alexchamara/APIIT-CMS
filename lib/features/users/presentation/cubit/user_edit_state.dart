abstract class UserEditState {}

class UserEditInitial extends UserEditState {}

class UserEditLoading extends UserEditState {}

class UserEditSuccess extends UserEditState {
  final String message;
  final bool shouldPop;

  UserEditSuccess({required this.message, this.shouldPop = false});
}

class UserEditError extends UserEditState {
  final String message;

  UserEditError(this.message);
}
