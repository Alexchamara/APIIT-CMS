import 'package:apiit_cms/features/auth/domain/models/user_model.dart';

abstract class UserRepository {
  Future<List<UserModel>> getAllUsers();
  Future<void> updateUser(UserModel user);
  Future<void> deleteUser(String uid);
  Future<void> deleteUserCompletely(String uid);
  Future<UserModel?> createUser({
    required String email,
    required String displayName,
    required UserType userType,
    String? phoneNumber,
  });
  Stream<List<UserModel>> getUsersStream();
}
