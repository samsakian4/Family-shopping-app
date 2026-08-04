import 'package:flutter_test/flutter_test.dart';

import 'package:family_shopping_app/features/shopping/data/models/shopping_item_local.dart';
import 'package:family_shopping_app/features/shopping/data/models/shopping_list_local.dart';
import 'package:family_shopping_app/features/shopping/domain/entities/shopping_item_entity.dart';
import 'package:family_shopping_app/features/shopping/domain/entities/shopping_list_entity.dart';

void main() {
  group('ShoppingListLocal <-> ShoppingListEntity round trip', () {
    test('fromEntity/toEntity preserves all fields', () {
      final entity = ShoppingListEntity(
        id: 'l1',
        familyId: 'f1',
        ownerId: 'u1',
        title: 'خرید هفتگی',
        type: ShoppingListType.shared,
        archived: true,
        estimatedTotal: 125000.5,
        updatedAt: DateTime(2026, 8, 1, 10, 30),
      );

      final local = ShoppingListLocal.fromEntity(entity);
      final roundTripped = local.toEntity();

      expect(roundTripped, entity);
    });

    test('personal list with null familyId round-trips as null', () {
      final entity = ShoppingListEntity(
        id: 'l2',
        ownerId: 'u1',
        title: 'خرید شخصی',
        type: ShoppingListType.personal,
        archived: false,
        estimatedTotal: 0,
        updatedAt: DateTime(2026),
      );

      final roundTripped = ShoppingListLocal.fromEntity(entity).toEntity();

      expect(roundTripped.familyId, isNull);
      expect(roundTripped.type, ShoppingListType.personal);
    });
  });

  group('ShoppingItemLocal <-> ShoppingItemEntity round trip', () {
    test('fromEntity/toEntity preserves all fields', () {
      const entity = ShoppingItemEntity(
        id: 'i1',
        shoppingListId: 'l1',
        categoryId: 'c1',
        name: 'شیر',
        quantity: 2,
        unit: 'لیتری',
        brand: 'کاله',
        notes: 'کم‌چرب',
        estimatedPrice: 45000,
        purchasedPrice: 43000,
        purchased: true,
        sortOrder: 3,
      );

      final roundTripped = ShoppingItemLocal.fromEntity(entity).toEntity();

      expect(roundTripped, entity);
    });
  });
}
