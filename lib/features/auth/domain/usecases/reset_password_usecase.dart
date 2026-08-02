import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import 'package:family_shopping_app/core/errors/failures.dart';
import 'package:family_shopping_app/core/usecases/usecase.dart';
import 'package:family_shopping_app/core/utils/typedefs.dart';
import 'package:family_shopping_app/features/auth/domain/repositories/auth_repository.dart';

class ResetPasswordParams extends Equatable {
  final String email;
  const ResetPasswordParams({required this.email});

  @override
  List<Object?> get props => [email];
}

class ResetPasswordUseCase implements UseCase<void, ResetPasswordParams> {
  final AuthRepository _repository;

  ResetPasswordUseCase(this._repository);

  @override
  ResultFuture<void> call(ResetPasswordParams params) async {
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(params.email.trim())) {
      return const Left(ValidationFailure('ایمیل وارد شده معتبر نیست'));
    }
    return _repository.resetPassword(email: params.email.trim().toLowerCase());
  }
}
