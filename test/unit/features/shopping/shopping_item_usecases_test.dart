import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:family_shopping_app/core/errors/failures.dart';
import 'package:family_shopping_app/features/shopping/domain/entities/shopping_item_entity.dart';
import 'package:family_shopping_app/features/shopping/domain/repositories/shopping_item_repository.dart';
import 'package:family_shopping_app/features/shopping/domain/usecases/add_item_usecase.dart';
import 'package:family_shopping_app/features/shopping/domain/usecases/manage_item_usecases.dart';

class MockShoppingItemRepository extends Mock implements ShoppingItemRepository {}

void main() {
  late MockShoppingItemRepository repository;

  const fakeItem = ShoppingItemEntity(
    id: 'i1',
    shoppingListId: 'l1',
    name: 'شیر',
    quantity: 2,
    purchased: false,
    sortOrder: 0,
  );

  setUp(() => repository = MockShoppingItemRepository());

  group('AddItemUseCase', () {
    late AddItemUseCase useCase;
    setUp(() => useCase = AddItemUseCase(repository));

    test('rejects empty product name', () async {
      final result = await useCase(
        const AddItemParams(shoppingListId: 'l1', name: '  ', quantity: 1),
      );
      expect(result, isA<Left<Failure, ShoppingItemEntity>>());
    });

    test('rejects zero or negative quantity', () async {
      final result = await useCase(
        const AddItemParams(shoppingListId: 'l1', name: 'شیر', quantity: 0),
      );
      expect(result, isA<Left<Failure, ShoppingItemEntity>>());
    });

    test('delegates trimmed valid input to repository', () async {
      when(() => repository.addItem(
            shoppingListId: any(named: 'shoppingListId'),
            name: any(named: 'name'),
            quantity: any(named: 'quantity'),
            unit: any(named: 'unit'),
            categoryId: any(named: 'categoryId'),
            brand: any(named: 'brand'),
            notes: any(named: 'notes'),
            estimatedPrice: any(named: 'estimatedPrice'),
          )).thenAnswer((_) async => const Right(fakeItem));

      final result = await useCase(
        const AddItemParams(shoppingListId: 'l1', name: '  شیر  ', quantity: 2),
      );

      expect(result, const Right<Failure, ShoppingItemEntity>(fakeItem));
      verify(() => repository.addItem(
            shoppingListId: 'l1',
            name: 'شیر',
            quantity: 2,
            unit: null,
            categoryId: null,
            brand: null,
            notes: null,
            estimatedPrice: null,
          )).called(1);
    });
  });

  group('UpdateItemUseCase', () {
    late UpdateItemUseCase useCase;
    setUp(() => useCase = UpdateItemUseCase(repository));

    test('rejects blank name when provided', () async {
      final result = await useCase(const UpdateItemParams(itemId: 'i1', name: '   '));
      expect(result, isA<Left<Failure, void>>());
    });

    test('rejects non-positive quantity when provided', () async {
      final result = await useCase(const UpdateItemParams(itemId: 'i1', quantity: -1));
      expect(result, isA<Left<Failure, void>>());
    });
  });
}
