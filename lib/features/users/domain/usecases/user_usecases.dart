import 'package:apiit_cms/features/auth/domain/models/user_model.dart';
import 'package:apiit_cms/features/users/domain/repositories/user_repository.dart';

class GetAllUsersUseCase {
  final UserRepository _repository;

  GetAllUsersUseCase(this._repository);

  Future<List<UserModel>> call() async {
    return await _repository.getAllUsers();
  }
}

class GetUsersStreamUseCase {
  final UserRepository _repository;

  GetUsersStreamUseCase(this._repository);

  Stream<List<UserModel>> call() {
    return _repository.getUsersStream();
  }
}

class UpdateUserUseCase {
  final UserRepository _repository;

  UpdateUserUseCase(this._repository);

  Future<void> call(UserModel user) async {
    await _repository.updateUser(user);
  }
}

class DeleteUserUseCase {
  final UserRepository _repository;

  DeleteUserUseCase(this._repository);

  Future<void> call(String uid) async {
    await _repository.deleteUser(uid);
  }
}

class DeleteUserCompletelyUseCase {
  final UserRepository _repository;

  DeleteUserCompletelyUseCase(this._repository);

  Future<void> call(String uid) async {
    await _repository.deleteUserCompletely(uid);
  }
}

class CreateUserUseCase {
  final UserRepository _repository;

  CreateUserUseCase(this._repository);

  Future<UserModel?> call({
    required String email,
    required String displayName,
    required UserType userType,
    String? phoneNumber,
  }) async {
    return await _repository.createUser(
      email: email,
      displayName: displayName,
      userType: userType,
      phoneNumber: phoneNumber,
    );
  }
}
