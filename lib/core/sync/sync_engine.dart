import 'dart:async';
import 'dart:convert';

import 'package:family_shopping_app/core/constants/app_constants.dart';
import 'package:family_shopping_app/core/local/sync_queue_entry.dart';
import 'package:family_shopping_app/core/local/sync_queue_service.dart';
import 'package:family_shopping_app/core/local/sync_status.dart';
import 'package:family_shopping_app/core/network/network_info.dart';
import 'package:family_shopping_app/features/shopping/data/datasources/shopping_item_remote_data_source.dart';
import 'package:family_shopping_app/features/shopping/data/datasources/shopping_list_remote_data_source.dart';
import 'package:family_shopping_app/features/shopping/data/datasources/shopping_item_local_cache.dart';
import 'package:family_shopping_app/features/shopping/data/datasources/shopping_list_local_cache.dart';
import 'package:family_shopping_app/features/shopping/domain/entities/shopping_list_entity.dart';

/// Replays queued offline writes once connectivity returns, and detects
/// conflicts before doing so (07_SYNC_ENGINE.md - Synchronization Flow,
/// Retry Policy, Conflict Detection).
///
/// Conflict rule actually implemented (see docs/LOOP_ENGINEERING_LOG.md,
/// Phase 8 fix-up entry): every queued `update` carries a
/// `base_updated_at` — the server's `updated_at` at the moment the
/// offline edit was made. Before applying, the engine re-fetches the
/// current server row. If the server's `updated_at` is newer than
/// `base_updated_at`, someone else changed it in the meantime: the queue
/// entry is marked `conflict` instead of being applied, and the local
/// cache row is flagged so the UI can show it. The user then resolves it
/// (keep mine / take theirs) via [resolveKeepLocal] / [resolveDiscardLocal].
///
/// `create`, `delete`, and `mark_purchased` are NOT conflict-checked:
/// - `create` always targets a brand-new id, nothing to conflict with.
/// - `delete` is idempotent (deleting an already-deleted row is a no-op).
/// - `mark_purchased` is one of the fields 07_SYNC_ENGINE.md explicitly
///   calls out as safe to auto-merge ("Purchased status ... merge logic
///   should be applied when safe") — last toggle wins by design.
class SyncEngine {
  final SyncQueueService _queue;
  final NetworkInfo _networkInfo;
  final ShoppingListRemoteDataSource _listRemote;
  final ShoppingItemRemoteDataSource _itemRemote;
  final ShoppingListLocalCache _listCache;
  final ShoppingItemLocalCache _itemCache;

  SyncEngine(
    this._queue,
    this._networkInfo,
    this._listRemote,
    this._itemRemote,
    this._listCache,
    this._itemCache,
  );

  StreamSubscription<bool>? _connSub;
  bool _processing = false;

  /// Call once at app startup. Processes any backlog immediately if
  /// already online, then reacts to connectivity changes going forward.
  void start() {
    _networkInfo.isConnected.then((online) {
      if (online) processQueue();
    });
    _connSub = _networkInfo.onConnectivityChanged.listen((online) {
      if (online) processQueue();
    });
  }

  void dispose() => _connSub?.cancel();

  /// Processes every pending entry once, oldest first
  /// (07_SYNC_ENGINE.md - Synchronization Order). Re-entrant calls while
  /// already processing are ignored.
  Future<void> processQueue() async {
    if (_processing) return;
    _processing = true;
    try {
      final pending = await _queue.getPending();
      for (final entry in pending) {
        if (!await _networkInfo.isConnected) break; // connection dropped mid-batch
        await _processOne(entry);
      }
    } finally {
      _processing = false;
    }
  }

  Future<void> _processOne(SyncQueueEntry entry) async {
    final payload = jsonDecode(entry.payloadJson) as Map<String, dynamic>;

    if (entry.operation == 'update') {
      final conflicted = await _hasConflict(entry.entityType, entry.entityId, payload);
      if (conflicted) {
        await _queue.markConflict(entry);
        await _flagCacheConflict(entry.entityType, entry.entityId);
        return;
      }
    }

    try {
      await _apply(entry.entityType, entry.entityId, entry.operation, payload);
      await _queue.markSynced(entry.id);
    } catch (_) {
      await _queue.markFailedAttempt(entry, maxRetries: AppConstants.syncRetryDelays.length);
    }
  }

  /// Returns true if the server's current `updated_at` is newer than the
  /// `base_updated_at` this offline edit started from.
  Future<bool> _hasConflict(
    String entityType,
    String entityId,
    Map<String, dynamic> payload,
  ) async {
    final baseUpdatedAtRaw = payload['base_updated_at'] as String?;
    if (baseUpdatedAtRaw == null) return false; // no base recorded — nothing to compare
    final baseUpdatedAt = DateTime.parse(baseUpdatedAtRaw);

    DateTime? serverUpdatedAt;
    if (entityType == 'shopping_list') {
      final row = await _listRemote.getById(entityId);
      serverUpdatedAt = row?.updatedAt;
    } else if (entityType == 'shopping_item') {
      final row = await _itemRemote.getById(entityId);
      serverUpdatedAt = row?.updatedAt;
    }
    if (serverUpdatedAt == null) return false; // deleted server-side — let delete/update fail naturally

    return serverUpdatedAt.isAfter(baseUpdatedAt);
  }

  Future<void> _flagCacheConflict(String entityType, String entityId) async {
    if (entityType == 'shopping_list') {
      final lists = await _listCache.getCached();
      final match = lists.where((l) => l.id == entityId);
      if (match.isNotEmpty) {
        await _listCache.upsert(match.first, status: SyncStatus.conflict);
      }
    }
    // Item cache lookups need a listId; the UI's conflict screen re-flags
    // items directly from the queue entry instead (it already has enough
    // info to show "this item has a conflict" without a cache round trip).
  }

  Future<void> _apply(
    String entityType,
    String entityId,
    String operation,
    Map<String, dynamic> payload,
  ) async {
    switch (entityType) {
      case 'shopping_list':
        await _applyListOperation(entityId, operation, payload);
        break;
      case 'shopping_item':
        await _applyItemOperation(entityId, operation, payload);
        break;
      default:
        throw StateError('No sync handler for entityType=$entityType');
    }
  }

  Future<void> _applyListOperation(
    String id,
    String operation,
    Map<String, dynamic> payload,
  ) async {
    switch (operation) {
      case 'create':
        await _listRemote.createList(
          id: id,
          title: payload['title'] as String,
          type: shoppingListTypeFromString(payload['type'] as String),
          familyId: payload['family_id'] as String?,
        );
        break;
      case 'update':
        if (payload.containsKey('title')) {
          await _listRemote.renameList(listId: id, newTitle: payload['title'] as String);
        }
        if (payload.containsKey('archived')) {
          await _listRemote.setArchived(listId: id, archived: payload['archived'] as bool);
        }
        break;
      case 'delete':
        await _listRemote.softDeleteList(listId: id);
        break;
    }
  }

  Future<void> _applyItemOperation(
    String id,
    String operation,
    Map<String, dynamic> payload,
  ) async {
    switch (operation) {
      case 'create':
        await _itemRemote.addItem(
          id: id,
          shoppingListId: payload['shopping_list_id'] as String,
          name: payload['name'] as String,
          quantity: (payload['quantity'] as num).toDouble(),
          unit: payload['unit'] as String?,
          categoryId: payload['category_id'] as String?,
          brand: payload['brand'] as String?,
          notes: payload['notes'] as String?,
          estimatedPrice: (payload['estimated_price'] as num?)?.toDouble(),
        );
        break;
      case 'update':
        await _itemRemote.updateItem(
          itemId: id,
          name: payload['name'] as String?,
          quantity: (payload['quantity'] as num?)?.toDouble(),
          unit: payload['unit'] as String?,
          categoryId: payload['category_id'] as String?,
          brand: payload['brand'] as String?,
          notes: payload['notes'] as String?,
          estimatedPrice: (payload['estimated_price'] as num?)?.toDouble(),
        );
        break;
      case 'mark_purchased':
        await _itemRemote.setPurchased(
          itemId: id,
          purchased: payload['purchased'] as bool,
          purchasedPrice: (payload['purchased_price'] as num?)?.toDouble(),
        );
        break;
      case 'delete':
        await _itemRemote.deleteItem(itemId: id);
        break;
    }
  }

  /// User chose "keep my change": force-apply the queued edit, ignoring
  /// the server's newer version, then mark synced.
  Future<void> resolveKeepLocal(SyncQueueEntry entry) async {
    final payload = jsonDecode(entry.payloadJson) as Map<String, dynamic>;
    try {
      await _apply(entry.entityType, entry.entityId, entry.operation, payload);
      await _queue.markSynced(entry.id);
    } catch (_) {
      await _queue.markFailedAttempt(entry, maxRetries: AppConstants.syncRetryDelays.length);
    }
  }

  /// User chose "keep server version": drop the queued edit and refresh
  /// the local cache with whatever the server currently has.
  Future<void> resolveDiscardLocal(SyncQueueEntry entry) async {
    if (entry.entityType == 'shopping_list') {
      final row = await _listRemote.getById(entry.entityId);
      if (row != null) await _listCache.upsert(row);
    } else if (entry.entityType == 'shopping_item') {
      final row = await _itemRemote.getById(entry.entityId);
      if (row != null) await _itemCache.upsert(row);
    }
    await _queue.discard(entry.id);
  }
}
