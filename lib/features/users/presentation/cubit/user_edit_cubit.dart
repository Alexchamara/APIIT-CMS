import 'package:apiit_cms/features/auth/domain/models/user_model.dart';
import 'package:apiit_cms/features/users/domain/usecases/user_usecases.dart';
import 'package:apiit_cms/features/users/presentation/cubit/user_edit_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class UserEditCubit extends Cubit<UserEditState> {
  final UpdateUserUseCase _updateUserUseCase;
  final DeleteUserCompletelyUseCase _deleteUserCompletelyUseCase;

  UserEditCubit({
    required UpdateUserUseCase updateUserUseCase,
    required DeleteUserCompletelyUseCase deleteUserCompletelyUseCase,
  }) : _updateUserUseCase = updateUserUseCase,
       _deleteUserCompletelyUseCase = deleteUserCompletelyUseCase,
       super(UserEditInitial());

  Future<void> updateUser(UserModel user) async {
    try {
      emit(UserEditLoading());
      await _updateUserUseCase(user);
      emit(UserEditSuccess(message: 'User updated successfully'));
    } catch (e) {
      emit(UserEditError('Failed to update user: ${e.toString()}'));
    }
  }

  Future<void> deleteUser(String uid) async {
    try {
      emit(UserEditLoading());

      // Use the complete deletion method
      await _deleteUserCompletelyUseCase(uid);

      emit(
        UserEditSuccess(message: 'User deleted successfully', shouldPop: true),
      );
    } catch (e) {
      emit(UserEditError('Failed to delete user: ${e.toString()}'));
    }
  }
}
