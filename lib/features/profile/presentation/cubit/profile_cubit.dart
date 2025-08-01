import 'package:apiit_cms/features/auth/data/auth_repository.dart';
import 'package:apiit_cms/features/auth/domain/models/user_model.dart';
import 'package:apiit_cms/features/profile/presentation/cubit/profile_state.dart';
import 'package:apiit_cms/features/users/domain/usecases/user_usecases.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProfileCubit extends Cubit<ProfileState> {
  final UpdateUserUseCase _updateUserUseCase;

  ProfileCubit({required UpdateUserUseCase updateUserUseCase})
    : _updateUserUseCase = updateUserUseCase,
      super(ProfileInitial());

  Future<void> loadCurrentUser() async {
    try {
      emit(ProfileLoading());
      final user = await AuthRepository.getCurrentUserModel();
      if (user != null) {
        emit(ProfileLoaded(user));
      } else {
        emit(ProfileError('Failed to load user profile'));
      }
    } catch (e) {
      emit(ProfileError('Failed to load user profile: ${e.toString()}'));
    }
  }

  Future<void> updateProfile(UserModel updatedUser) async {
    try {
      emit(ProfileLoading());

      // Update Firestore first
      await _updateUserUseCase(updatedUser);

      // Update Firebase Auth displayName if it changed
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null &&
          currentUser.displayName != updatedUser.displayName) {
        await currentUser.updateDisplayName(updatedUser.displayName);
      }

      emit(ProfileUpdateSuccess('Profile updated successfully'));
      // Reload the user data after update
      await loadCurrentUser();
    } catch (e) {
      emit(ProfileError('Failed to update profile: ${e.toString()}'));
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      emit(
        ProfilePasswordResetSuccess('Password reset email sent successfully'),
      );
    } catch (e) {
      emit(
        ProfileError('Failed to send password reset email: ${e.toString()}'),
      );
    }
  }

  Future<void> signOut() async {
    try {
      await AuthRepository.signOut();
    } catch (e) {
      emit(ProfileError('Failed to sign out: ${e.toString()}'));
    }
  }
}
