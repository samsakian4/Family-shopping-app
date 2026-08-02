import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import 'package:family_shopping_app/core/constants/app_constants.dart';
import 'package:family_shopping_app/core/errors/failures.dart';
import 'package:family_shopping_app/core/usecases/usecase.dart';
import 'package:family_shopping_app/core/utils/typedefs.dart';
import 'package:family_shopping_app/features/auth/domain/entities/user_entity.dart';
import 'package:family_shopping_app/features/auth/domain/repositories/auth_repository.dart';

class SignUpParams extends Equatable {
  final String email;
  final String password;
  final String displayName;

  const SignUpParams({
    required this.email,
    required this.password,
    required this.displayName,
  });

  @override
  List<Object?> get props => [email, password, displayName];
}

class SignUpUseCase implements UseCase<UserEntity, SignUpParams> {
  final AuthRepository _repository;

  SignUpUseCase(this._repository);

  @override
  ResultFuture<UserEntity> call(SignUpParams params) async {
    final validation = _validate(params);
    if (validation != null) return Left(validation);

    return _repository.signUp(
      email: params.email.trim().toLowerCase(),
      password: params.password,
      displayName: params.displayName.trim(),
    );
  }

  /// Repeats client-side validation on... well, this IS the app-side rule;
  /// the backend (Supabase Auth + RLS) repeats it again server-side per
  /// 08_SECURITY.md Principle 3 (Never Trust Client Input).
  Failure? _validate(SignUpParams p) {
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(p.email.trim())) {
      return const ValidationFailure('ایمیل وارد شده معتبر نیست');
    }
    if (p.password.length < AppConstants.passwordMinLength) {
      return const ValidationFailure('رمز عبور باید حداقل ۸ کاراکتر باشد');
    }
    if (p.displayName.trim().isEmpty) {
      return const ValidationFailure('نام نمایشی را وارد کنید');
    }
    return null;
  }
}
