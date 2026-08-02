import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:family_shopping_app/core/errors/failures.dart';
import 'package:family_shopping_app/features/auth/domain/entities/user_entity.dart';
import 'package:family_shopping_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:family_shopping_app/features/auth/domain/usecases/sign_up_usecase.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository repository;
  late SignUpUseCase useCase;

  setUp(() {
    repository = MockAuthRepository();
    useCase = SignUpUseCase(repository);
  });

  const validParams = SignUpParams(
    email: 'user@example.com',
    password: 'StrongPass1!',
    displayName: 'Saki',
  );

  const fakeUser = UserEntity(id: 'u1', email: 'user@example.com');

  group('SignUpUseCase - client-side validation', () {
    test('rejects invalid email format without calling the repository', () async {
      final result = await useCase(
        const SignUpParams(email: 'not-an-email', password: 'StrongPass1!', displayName: 'Saki'),
      );

      expect(result, isA<Left<Failure, UserEntity>>());
      verifyNever(() => repository.signUp(
            email: any(named: 'email'),
            password: any(named: 'password'),
            displayName: any(named: 'displayName'),
          ));
    });

    test('rejects password shorter than 8 characters', () async {
      final result = await useCase(
        const SignUpParams(email: 'user@example.com', password: '123', displayName: 'Saki'),
      );

      expect(result, isA<Left<Failure, UserEntity>>());
    });

    test('rejects empty display name', () async {
      final result = await useCase(
        const SignUpParams(email: 'user@example.com', password: 'StrongPass1!', displayName: '  '),
      );

      expect(result, isA<Left<Failure, UserEntity>>());
    });

    test('delegates to repository with normalized email when valid', () async {
      when(() => repository.signUp(
            email: any(named: 'email'),
            password: any(named: 'password'),
            displayName: any(named: 'displayName'),
          )).thenAnswer((_) async => const Right(fakeUser));

      final result = await useCase(
        const SignUpParams(
          email: '  User@Example.com  ',
          password: 'StrongPass1!',
          displayName: '  Saki  ',
        ),
      );

      expect(result, const Right<Failure, UserEntity>(fakeUser));
      verify(() => repository.signUp(
            email: 'user@example.com',
            password: 'StrongPass1!',
            displayName: 'Saki',
          )).called(1);
    });
  });
}
