abstract class AddUserState {}

class AddUserInitial extends AddUserState {}

class AddUserLoading extends AddUserState {}

class AddUserSuccess extends AddUserState {
  final String message;

  AddUserSuccess(this.message);
}

class AddUserError extends AddUserState {
  final String message;

  AddUserError(this.message);
}
