import 'package:dartz/dartz.dart';
import 'package:uuid/uuid.dart';

import 'package:family_shopping_app/core/errors/exceptions.dart';
import 'package:family_shopping_app/core/errors/failures.dart';
import 'package:family_shopping_app/core/local/sync_queue_service.dart';
import 'package:family_shopping_app/core/local/sync_status.dart';
import 'package:family_shopping_app/core/network/network_info.dart';
import 'package:family_shopping_app/core/utils/typedefs.dart';
import 'package:family_shopping_app/features/shopping/data/datasources/shopping_item_local_cache.dart';
import 'package:family_shopping_app/features/shopping/data/datasources/shopping_item_remote_data_source.dart';
import 'package:family_shopping_app/features/shopping/domain/entities/shopping_item_entity.dart';
import 'package:family_shopping_app/features/shopping/domain/repositories/shopping_item_repository.dart';

/// Same cache-centric, offline-first shape as
/// [ShoppingListRepositoryImpl] — see that file's doc comment.
class ShoppingItemRepositoryImpl implements ShoppingItemRepository {
  final ShoppingItemRemoteDataSource _remote;
  final NetworkInfo _networkInfo;
  final ShoppingItemLocalCache _cache;
  final SyncQueueService _syncQueue;

  ShoppingItemRepositoryImpl(this._remote, this._networkInfo, this._cache, this._syncQueue);

  final Set<String> _subscribedLists = {};

  @override
  Stream<List<ShoppingItemEntity>> watchItems({required String shoppingListId}) {
    _ensureRemoteSubscription(shoppingListId);
    return _cache.watchForList(shoppingListId);
  }

  void _ensureRemoteSubscription(String shoppingListId) {
    if (_subscribedLists.contains(shoppingListId)) return;
    _subscribedLists.add(shoppingListId);

    _networkInfo.isConnected.then((online) {
      if (!online) return;
      _remote.watchItems(shoppingListId: shoppingListId).listen(
        (remoteItems) => _cache.mergeForList(shoppingListId, remoteItems),
        onError: (_) {},
      );
    });
  }

  @override
  ResultFuture<ShoppingItemEntity> addItem({
    required String shoppingListId,
    required String name,
    required double quantity,
    String? unit,
    String? categoryId,
    String? brand,
    String? notes,
    double? estimatedPrice,
    String? productId,
  }) async {
    final online = await _networkInfo.isConnected;
    final id = const Uuid().v4();

    if (online) {
      try {
        final created = await _remote.addItem(
          id: id,
          shoppingListId: shoppingListId,
          name: name,
          quantity: quantity,
          unit: unit,
          categoryId: categoryId,
          brand: brand,
          notes: notes,
          estimatedPrice: estimatedPrice,
          productId: productId,
        );
        await _cache.upsert(created);
        return Right(created);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (_) {
        return const Left(UnknownFailure());
      }
    }

    // Offline: not linked to a catalog product_id yet — the item is
    // still fully usable, it just won't count toward catalog purchase
    // history/favorites until synced (documented limitation, consistent
    // with the rest of the offline-write scope from Milestone 1 Phase 8).

    final entity = ShoppingItemEntity(
      id: id,
      shoppingListId: shoppingListId,
      categoryId: categoryId,
      name: name,
      quantity: quantity,
      unit: unit,
      brand: brand,
      notes: notes,
      estimatedPrice: estimatedPrice,
      purchased: false,
      sortOrder: 0,
      updatedAt: DateTime.now(),
    );
    await _cache.upsert(entity, status: SyncStatus.pending);
    await _syncQueue.enqueue(
      entityType: 'shopping_item',
      entityId: id,
      operation: 'create',
      payload: {
        'shopping_list_id': shoppingListId,
        'name': name,
        'quantity': quantity,
        'unit': unit,
        'category_id': categoryId,
        'brand': brand,
        'notes': notes,
        'estimated_price': estimatedPrice,
      },
    );
    return Right(entity);
  }

  @override
  ResultFuture<void> updateItem({
    required String itemId,
    String? name,
    double? quantity,
    String? unit,
    String? categoryId,
    String? brand,
    String? notes,
    double? estimatedPrice,
  }) async {
    final payload = <String, dynamic>{
      if (name != null) 'name': name,
      if (quantity != null) 'quantity': quantity,
      if (unit != null) 'unit': unit,
      if (categoryId != null) 'category_id': categoryId,
      if (brand != null) 'brand': brand,
      if (notes != null) 'notes': notes,
      if (estimatedPrice != null) 'estimated_price': estimatedPrice,
    };
    return _optimisticUpdate(
      itemId: itemId,
      apply: (e) => ShoppingItemEntity(
        id: e.id,
        shoppingListId: e.shoppingListId,
        categoryId: categoryId ?? e.categoryId,
        name: name ?? e.name,
        quantity: quantity ?? e.quantity,
        unit: unit ?? e.unit,
        brand: brand ?? e.brand,
        notes: notes ?? e.notes,
        estimatedPrice: estimatedPrice ?? e.estimatedPrice,
        purchasedPrice: e.purchasedPrice,
        purchased: e.purchased,
        sortOrder: e.sortOrder,
        updatedAt: DateTime.now(),
      ),
      remoteCall: () => _remote.updateItem(
        itemId: itemId,
        name: name,
        quantity: quantity,
        unit: unit,
        categoryId: categoryId,
        brand: brand,
        notes: notes,
        estimatedPrice: estimatedPrice,
      ),
      payload: payload,
    );
  }

  @override
  ResultFuture<void> setPurchased({
    required String itemId,
    required bool purchased,
    double? purchasedPrice,
  }) {
    return _optimisticUpdate(
      itemId: itemId,
      apply: (e) => ShoppingItemEntity(
        id: e.id,
        shoppingListId: e.shoppingListId,
        categoryId: e.categoryId,
        name: e.name,
        quantity: e.quantity,
        unit: e.unit,
        brand: e.brand,
        notes: e.notes,
        estimatedPrice: e.estimatedPrice,
        purchasedPrice: purchased ? purchasedPrice : null,
        purchased: purchased,
        sortOrder: e.sortOrder,
        updatedAt: DateTime.now(),
      ),
      remoteCall: () => _remote.setPurchased(
        itemId: itemId,
        purchased: purchased,
        purchasedPrice: purchasedPrice,
      ),
      payload: {'purchased': purchased, 'purchased_price': purchasedPrice},
      operationOverride: 'mark_purchased',
    );
  }

  @override
  ResultFuture<void> deleteItem({required String itemId}) async {
    final online = await _networkInfo.isConnected;
    if (online) {
      try {
        await _remote.deleteItem(itemId: itemId);
        await _cache.removeByRemoteId(itemId);
        return const Right(null);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (_) {
        return const Left(UnknownFailure());
      }
    }
    await _cache.removeByRemoteId(itemId);
    await _syncQueue.enqueue(
      entityType: 'shopping_item',
      entityId: itemId,
      operation: 'delete',
      payload: const {},
    );
    return const Right(null);
  }

  Future<Either<Failure, void>> _optimisticUpdate({
    required String itemId,
    required ShoppingItemEntity Function(ShoppingItemEntity current) apply,
    required Future<void> Function() remoteCall,
    required Map<String, dynamic> payload,
    String operationOverride = 'update',
  }) async {
    // Items are cached per-list; search across the lists we've already
    // subscribed to for this item's current cached state.
    ShoppingItemEntity? current;
    for (final listId in _subscribedLists) {
      final items = await _cache.getCached(listId);
      final match = items.where((i) => i.id == itemId);
      if (match.isNotEmpty) {
        current = match.first;
        break;
      }
    }
    if (current == null) return const Left(CacheFailure('آیتم در کش محلی یافت نشد'));
    final updated = apply(current);

    final online = await _networkInfo.isConnected;
    if (online) {
      try {
        await remoteCall();
        await _cache.upsert(updated);
        return const Right(null);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (_) {
        return const Left(UnknownFailure());
      }
    }

    await _cache.upsert(updated, status: SyncStatus.pending);
    await _syncQueue.enqueue(
      entityType: 'shopping_item',
      entityId: itemId,
      operation: operationOverride,
      // base_updated_at lets the sync engine detect if someone else
      // changed this item on the server after our offline edit started
      // (07_SYNC_ENGINE.md - Conflict Detection). Only meaningful for
      // 'update'; harmless extra key for 'mark_purchased' (safe-merge
      // field, sync engine never checks it for that operation).
      payload: {...payload, 'base_updated_at': current.updatedAt.toIso8601String()},
    );
    return const Right(null);
  }

  @override
  Future<List<String>> searchProductNames(String query) {
    return _cache.searchItemNames(query);
  }
}
