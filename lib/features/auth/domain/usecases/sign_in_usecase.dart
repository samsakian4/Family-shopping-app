import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import 'package:family_shopping_app/core/errors/failures.dart';
import 'package:family_shopping_app/core/usecases/usecase.dart';
import 'package:family_shopping_app/core/utils/typedefs.dart';
import 'package:family_shopping_app/features/auth/domain/entities/user_entity.dart';
import 'package:family_shopping_app/features/auth/domain/repositories/auth_repository.dart';

class SignInParams extends Equatable {
  final String email;
  final String password;

  const SignInParams({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

class SignInUseCase implements UseCase<UserEntity, SignInParams> {
  final AuthRepository _repository;

  SignInUseCase(this._repository);

  @override
  ResultFuture<UserEntity> call(SignInParams params) async {
    if (params.email.trim().isEmpty || params.password.isEmpty) {
      return const Left(ValidationFailure('ایمیل و رمز عبور را وارد کنید'));
    }
    return _repository.signIn(
      email: params.email.trim().toLowerCase(),
      password: params.password,
    );
  }
}
