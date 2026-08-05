import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:family_shopping_app/core/errors/failures.dart';
import 'package:family_shopping_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:family_shopping_app/features/auth/domain/usecases/reset_password_usecase.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository repository;
  late ResetPasswordUseCase useCase;

  setUp(() {
    repository = MockAuthRepository();
    useCase = ResetPasswordUseCase(repository);
  });

  test('rejects an invalid email format', () async {
    final result = await useCase(const ResetPasswordParams(email: 'not-an-email'));
    expect(result, isA<Left<Failure, void>>());
    verifyNever(() => repository.resetPassword(email: any(named: 'email')));
  });

  test('normalizes and delegates a valid email', () async {
    when(() => repository.resetPassword(email: any(named: 'email')))
        .thenAnswer((_) async => const Right(null));

    final result = await useCase(const ResetPasswordParams(email: '  User@Example.com  '));

    expect(result, const Right<Failure, void>(null));
    verify(() => repository.resetPassword(email: 'user@example.com')).called(1);
  });
}
