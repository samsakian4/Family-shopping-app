import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:family_shopping_app/core/errors/failures.dart';
import 'package:family_shopping_app/features/family/domain/entities/family_entity.dart';
import 'package:family_shopping_app/features/family/domain/repositories/family_repository.dart';
import 'package:family_shopping_app/features/family/domain/usecases/create_family_usecase.dart';
import 'package:family_shopping_app/features/family/domain/usecases/join_family_usecase.dart';

class MockFamilyRepository extends Mock implements FamilyRepository {}

void main() {
  late MockFamilyRepository repository;

  const fakeFamily = FamilyEntity(
    id: 'f1',
    name: 'خانواده تست',
    ownerId: 'u1',
    invitationCode: 'ABC123',
  );

  setUp(() {
    repository = MockFamilyRepository();
  });

  group('CreateFamilyUseCase', () {
    late CreateFamilyUseCase useCase;
    setUp(() => useCase = CreateFamilyUseCase(repository));

    test('rejects empty name without calling the repository', () async {
      final result = await useCase(const CreateFamilyParams(name: '   '));
      expect(result, isA<Left<Failure, FamilyEntity>>());
      verifyNever(() => repository.createFamily(name: any(named: 'name')));
    });

    test('trims name and delegates to repository', () async {
      when(() => repository.createFamily(name: any(named: 'name')))
          .thenAnswer((_) async => const Right(fakeFamily));

      final result = await useCase(const CreateFamilyParams(name: '  خانواده تست  '));

      expect(result, const Right<Failure, FamilyEntity>(fakeFamily));
      verify(() => repository.createFamily(name: 'خانواده تست')).called(1);
    });
  });

  group('JoinFamilyUseCase', () {
    late JoinFamilyUseCase useCase;
    setUp(() => useCase = JoinFamilyUseCase(repository));

    test('rejects empty invitation code without calling the repository', () async {
      final result = await useCase(const JoinFamilyParams(invitationCode: ''));
      expect(result, isA<Left<Failure, FamilyEntity>>());
      verifyNever(() => repository.joinFamily(invitationCode: any(named: 'invitationCode')));
    });

    test('delegates trimmed code to repository', () async {
      when(() => repository.joinFamily(invitationCode: any(named: 'invitationCode')))
          .thenAnswer((_) async => const Right(fakeFamily));

      final result = await useCase(const JoinFamilyParams(invitationCode: '  ABC123  '));

      expect(result, const Right<Failure, FamilyEntity>(fakeFamily));
      verify(() => repository.joinFamily(invitationCode: 'ABC123')).called(1);
    });
  });
}
