import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:family_shopping_app/core/errors/failures.dart';
import 'package:family_shopping_app/features/auth/domain/entities/user_entity.dart';
import 'package:family_shopping_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:family_shopping_app/features/auth/domain/usecases/sign_in_usecase.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository repository;
  late SignInUseCase useCase;

  const fakeUser = UserEntity(id: 'u1', email: 'user@example.com');

  setUp(() {
    repository = MockAuthRepository();
    useCase = SignInUseCase(repository);
  });

  test('rejects empty email without calling the repository', () async {
    final result = await useCase(const SignInParams(email: '', password: 'x'));
    expect(result, isA<Left<Failure, UserEntity>>());
    verifyNever(
        () => repository.signIn(email: any(named: 'email'), password: any(named: 'password')));
  });

  test('rejects empty password without calling the repository', () async {
    final result =
        await useCase(const SignInParams(email: 'user@example.com', password: ''));
    expect(result, isA<Left<Failure, UserEntity>>());
  });

  test('normalizes email casing/whitespace before delegating', () async {
    when(() => repository.signIn(
          email: any(named: 'email'),
          password: any(named: 'password'),
        )).thenAnswer((_) async => const Right(fakeUser));

    final result =
        await useCase(const SignInParams(email: '  User@Example.com ', password: 'pw'));

    expect(result, const Right<Failure, UserEntity>(fakeUser));
    verify(() => repository.signIn(email: 'user@example.com', password: 'pw')).called(1);
  });
}
