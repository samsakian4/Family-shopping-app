import 'package:isar/isar.dart';

import 'package:family_shopping_app/features/shopping/data/models/shopping_item_local.dart';
import 'package:family_shopping_app/features/shopping/domain/entities/shopping_item_entity.dart';

class ShoppingItemLocalCache {
  final Isar _isar;
  ShoppingItemLocalCache(this._isar);

  Future<List<ShoppingItemEntity>> getCached(String shoppingListId) async {
    final rows = await _isar.shoppingItemLocals
        .filter()
        .shoppingListIdEqualTo(shoppingListId)
        .findAll();
    return rows.map((r) => r.toEntity()).toList();
  }

  Future<void> replaceForList(String shoppingListId, List<ShoppingItemEntity> items) async {
    await _isar.writeTxn(() async {
      await _isar.shoppingItemLocals
          .filter()
          .shoppingListIdEqualTo(shoppingListId)
          .deleteAll();
      await _isar.shoppingItemLocals
          .putAll(items.map(ShoppingItemLocal.fromEntity).toList());
    });
  }
}
