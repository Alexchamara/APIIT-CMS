import 'package:apiit_cms/features/auth/domain/models/user_model.dart';
import 'package:apiit_cms/features/users/domain/usecases/user_usecases.dart';
import 'package:apiit_cms/features/users/presentation/cubit/add_user_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AddUserCubit extends Cubit<AddUserState> {
  final CreateUserUseCase _createUserUseCase;

  AddUserCubit({required CreateUserUseCase createUserUseCase})
    : _createUserUseCase = createUserUseCase,
      super(AddUserInitial());

  Future<void> createUser({
    required String email,
    required String displayName,
    required UserType userType,
    String? phoneNumber,
  }) async {
    try {
      emit(AddUserLoading());

      final user = await _createUserUseCase(
        email: email,
        displayName: displayName,
        userType: userType,
        phoneNumber: phoneNumber,
      );

      if (user != null) {
        emit(
          AddUserSuccess(
            'User ${user.displayName} created successfully! '
            'A password reset email has been sent to ${user.email}.',
          ),
        );
      } else {
        emit(AddUserError('Failed to create user. Please try again.'));
      }
    } catch (e) {
      emit(AddUserError('Failed to create user: ${e.toString()}'));
    }
  }
}
