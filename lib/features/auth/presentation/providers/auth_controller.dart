import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:family_shopping_app/features/auth/domain/usecases/reset_password_usecase.dart';
import 'package:family_shopping_app/features/auth/domain/usecases/sign_in_usecase.dart';
import 'package:family_shopping_app/features/auth/domain/usecases/sign_out_usecase.dart';
import 'package:family_shopping_app/features/auth/domain/usecases/sign_up_usecase.dart';
import 'package:family_shopping_app/core/usecases/usecase.dart';
import 'package:family_shopping_app/features/auth/presentation/providers/auth_providers.dart';

part 'auth_controller.g.dart';

/// Drives Login/Register/ForgotPassword screens. AsyncValue.loading/error
/// map directly to the UI's loading + friendly-error states
/// (10_UI_UX.md - Instant Feedback, Error Experience).
@riverpod
class AuthController extends _$AuthController {
  @override
  FutureOr<void> build() {
    // Idle state — nothing to do until an action is invoked.
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    state = const AsyncLoading();
    final useCase = ref.read(signUpUseCaseProvider);
    final result = await useCase(
      SignUpParams(email: email, password: password, displayName: displayName),
    );
    return result.fold(
      (failure) {
        state = AsyncError(failure.message, StackTrace.current);
        return false;
      },
      (_) {
        state = const AsyncData(null);
        return true;
      },
    );
  }

  Future<bool> signIn({required String email, required String password}) async {
    state = const AsyncLoading();
    final useCase = ref.read(signInUseCaseProvider);
    final result = await useCase(SignInParams(email: email, password: password));
    return result.fold(
      (failure) {
        state = AsyncError(failure.message, StackTrace.current);
        return false;
      },
      (_) {
        state = const AsyncData(null);
        return true;
      },
    );
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    final useCase = ref.read(signOutUseCaseProvider);
    final result = await useCase(const NoParams());
    state = result.fold(
      (failure) => AsyncError(failure.message, StackTrace.current),
      (_) => const AsyncData(null),
    );
  }

  Future<bool> resetPassword({required String email}) async {
    state = const AsyncLoading();
    final useCase = ref.read(resetPasswordUseCaseProvider);
    final result = await useCase(ResetPasswordParams(email: email));
    return result.fold(
      (failure) {
        state = AsyncError(failure.message, StackTrace.current);
        return false;
      },
      (_) {
        state = const AsyncData(null);
        return true;
      },
    );
  }
}
