import 'dart:async';
import 'dart:convert';

import 'package:family_shopping_app/core/constants/app_constants.dart';
import 'package:family_shopping_app/core/local/sync_queue_entry.dart';
import 'package:family_shopping_app/core/local/sync_queue_service.dart';
import 'package:family_shopping_app/core/network/network_info.dart';
import 'package:family_shopping_app/features/shopping/data/datasources/shopping_item_remote_data_source.dart';
import 'package:family_shopping_app/features/shopping/data/datasources/shopping_list_remote_data_source.dart';
import 'package:family_shopping_app/features/shopping/domain/entities/shopping_list_entity.dart';

/// Replays queued offline writes once connectivity returns
/// (07_SYNC_ENGINE.md - Synchronization Flow, Retry Policy).
///
/// Scope for this phase: `shopping_list` and `shopping_item` entities only
/// (the two features with offline-write support so far — see
/// docs/LOOP_ENGINEERING_LOG.md, Phase 8 entry).
class SyncEngine {
  final SyncQueueService _queue;
  final NetworkInfo _networkInfo;
  final ShoppingListRemoteDataSource _listRemote;
  final ShoppingItemRemoteDataSource _itemRemote;

  SyncEngine(this._queue, this._networkInfo, this._listRemote, this._itemRemote);

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
        try {
          await _apply(entry);
          await _queue.markSynced(entry.id);
        } catch (_) {
          await _queue.markFailedAttempt(
            entry,
            maxRetries: AppConstants.syncRetryDelays.length,
          );
        }
      }
    } finally {
      _processing = false;
    }
  }

  Future<void> _apply(SyncQueueEntry entry) async {
    final payload = jsonDecode(entry.payloadJson) as Map<String, dynamic>;

    switch (entry.entityType) {
      case 'shopping_list':
        await _applyListOperation(entry.entityId, entry.operation, payload);
        break;
      case 'shopping_item':
        await _applyItemOperation(entry.entityId, entry.operation, payload);
        break;
      default:
        // Unknown entity type queued by a future feature that hasn't
        // wired its handler here yet — leave it pending rather than lose it.
        throw StateError('No sync handler for entityType=${entry.entityType}');
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
}
