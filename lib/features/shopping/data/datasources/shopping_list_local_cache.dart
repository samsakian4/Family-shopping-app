import 'package:isar/isar.dart';

import 'package:family_shopping_app/features/shopping/data/models/shopping_list_local.dart';
import 'package:family_shopping_app/features/shopping/domain/entities/shopping_list_entity.dart';

/// Write-through cache for shopping lists
/// (27_LOCAL_DATABASE_AND_OFFLINE_SYNC.md - "Local database is always
/// written first. UI always reflects local data.").
class ShoppingListLocalCache {
  final Isar _isar;
  ShoppingListLocalCache(this._isar);

  Future<List<ShoppingListEntity>> getCached() async {
    final rows = await _isar.shoppingListLocals.where().findAll();
    return rows.map((r) => r.toEntity()).toList();
  }

  /// Replaces the full cached set with the latest server snapshot.
  Future<void> replaceAll(List<ShoppingListEntity> lists) async {
    await _isar.writeTxn(() async {
      await _isar.shoppingListLocals.clear();
      await _isar.shoppingListLocals
          .putAll(lists.map(ShoppingListLocal.fromEntity).toList());
    });
  }
}
