import 'package:isar/isar.dart';

import 'package:family_shopping_app/core/local/sync_status.dart';
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

  /// Reactive read: emits immediately with whatever is cached, then again
  /// every time the local collection changes — including changes made
  /// purely offline (07_SYNC_ENGINE.md: "UI always reflects local data").
  Stream<List<ShoppingListEntity>> watchCached() {
    return _isar.shoppingListLocals
        .where()
        .watch(fireImmediately: true)
        .map((rows) => rows.map((r) => r.toEntity()).toList());
  }

  /// Reconciles the cache with a fresh server snapshot WITHOUT discarding
  /// rows that only exist locally because they're still queued for sync
  /// (offline creates/edits) — only rows already marked `synced` are
  /// pruned if the server no longer has them.
  Future<void> mergeFromRemote(List<ShoppingListEntity> remoteLists) async {
    await _isar.writeTxn(() async {
      await _isar.shoppingListLocals
          .putAll(remoteLists.map(ShoppingListLocal.fromEntity).toList());

      final remoteIds = remoteLists.map((e) => e.id).toSet();
      final allLocal = await _isar.shoppingListLocals.where().findAll();
      final staleIds = allLocal
          .where((l) => l.syncStatus == SyncStatus.synced && !remoteIds.contains(l.remoteId))
          .map((l) => l.id)
          .toList();
      if (staleIds.isNotEmpty) {
        await _isar.shoppingListLocals.deleteAll(staleIds);
      }
    });
  }

  Future<void> upsert(ShoppingListEntity list, {SyncStatus status = SyncStatus.synced}) async {
    await _isar.writeTxn(() async {
      await _isar.shoppingListLocals
          .put(ShoppingListLocal.fromEntity(list)..syncStatus = status);
    });
  }

  Future<void> removeByRemoteId(String remoteId) async {
    await _isar.writeTxn(() async {
      final row =
          await _isar.shoppingListLocals.filter().remoteIdEqualTo(remoteId).findFirst();
      if (row != null) await _isar.shoppingListLocals.delete(row.id);
    });
  }
}
