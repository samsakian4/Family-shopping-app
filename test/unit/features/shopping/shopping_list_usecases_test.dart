import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:family_shopping_app/core/errors/failures.dart';
import 'package:family_shopping_app/features/shopping/domain/entities/shopping_list_entity.dart';
import 'package:family_shopping_app/features/shopping/domain/repositories/shopping_list_repository.dart';
import 'package:family_shopping_app/features/shopping/domain/usecases/create_list_usecase.dart';
import 'package:family_shopping_app/features/shopping/domain/usecases/manage_list_usecases.dart';

class MockShoppingListRepository extends Mock implements ShoppingListRepository {}

void main() {
  late MockShoppingListRepository repository;

  final fakeList = ShoppingListEntity(
    id: 'l1',
    ownerId: 'u1',
    title: 'خرید هفتگی',
    type: ShoppingListType.personal,
    archived: false,
    estimatedTotal: 0,
    updatedAt: DateTime(2026),
  );

  setUp(() => repository = MockShoppingListRepository());

  group('CreateListUseCase', () {
    late CreateListUseCase useCase;
    setUp(() => useCase = CreateListUseCase(repository));

    test('rejects empty title', () async {
      final result = await useCase(
        const CreateListParams(title: '  ', type: ShoppingListType.personal),
      );
      expect(result, isA<Left<Failure, ShoppingListEntity>>());
    });

    test('rejects shared list without familyId', () async {
      final result = await useCase(
        const CreateListParams(title: 'خرید', type: ShoppingListType.shared),
      );
      expect(result, isA<Left<Failure, ShoppingListEntity>>());
      verifyNever(() => repository.createList(
            title: any(named: 'title'),
            type: any(named: 'type'),
            familyId: any(named: 'familyId'),
          ));
    });

    test('creates a personal list without needing a familyId', () async {
      when(() => repository.createList(
            title: any(named: 'title'),
            type: any(named: 'type'),
            familyId: any(named: 'familyId'),
          )).thenAnswer((_) async => Right(fakeList));

      final result = await useCase(
        const CreateListParams(title: '  خرید هفتگی  ', type: ShoppingListType.personal),
      );

      expect(result, Right<Failure, ShoppingListEntity>(fakeList));
      verify(() => repository.createList(
            title: 'خرید هفتگی',
            type: ShoppingListType.personal,
            familyId: null,
          )).called(1);
    });
  });

  group('RenameListUseCase', () {
    late RenameListUseCase useCase;
    setUp(() => useCase = RenameListUseCase(repository));

    test('rejects empty new title', () async {
      final result =
          await useCase(const RenameListParams(listId: 'l1', newTitle: '   '));
      expect(result, isA<Left<Failure, void>>());
      verifyNever(() => repository.renameList(
            listId: any(named: 'listId'),
            newTitle: any(named: 'newTitle'),
          ));
    });
  });
}
