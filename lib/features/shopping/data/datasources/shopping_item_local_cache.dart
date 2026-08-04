import 'package:isar/isar.dart';

import 'package:family_shopping_app/core/local/sync_status.dart';
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

  Stream<List<ShoppingItemEntity>> watchForList(String shoppingListId) {
    return _isar.shoppingItemLocals
        .filter()
        .shoppingListIdEqualTo(shoppingListId)
        .watch(fireImmediately: true)
        .map((rows) => rows.map((r) => r.toEntity()).toList());
  }

  Future<void> upsert(ShoppingItemEntity item, {SyncStatus status = SyncStatus.synced}) async {
    await _isar.writeTxn(() async {
      await _isar.shoppingItemLocals
          .put(ShoppingItemLocal.fromEntity(item)..syncStatus = status);
    });
  }

  Future<void> removeByRemoteId(String remoteId) async {
    await _isar.writeTxn(() async {
      final row =
          await _isar.shoppingItemLocals.filter().remoteIdEqualTo(remoteId).findFirst();
      if (row != null) await _isar.shoppingItemLocals.delete(row.id);
    });
  }

  /// Same reconciliation strategy as [ShoppingListLocalCache.mergeFromRemote]
  /// — keeps not-yet-synced local rows for this list, updates/removes
  /// everything else to match the server.
  Future<void> mergeForList(String shoppingListId, List<ShoppingItemEntity> items) async {
    await _isar.writeTxn(() async {
      await _isar.shoppingItemLocals.putAll(items.map(ShoppingItemLocal.fromEntity).toList());

      final remoteIds = items.map((e) => e.id).toSet();
      final allLocal = await _isar.shoppingItemLocals
          .filter()
          .shoppingListIdEqualTo(shoppingListId)
          .findAll();
      final staleIds = allLocal
          .where((i) => i.syncStatus == SyncStatus.synced && !remoteIds.contains(i.remoteId))
          .map((i) => i.id)
          .toList();
      if (staleIds.isNotEmpty) {
        await _isar.shoppingItemLocals.deleteAll(staleIds);
      }
    });
  }
}
