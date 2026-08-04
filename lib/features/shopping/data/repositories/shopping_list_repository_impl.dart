import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'package:uuid/uuid.dart';

import 'package:family_shopping_app/core/errors/exceptions.dart';
import 'package:family_shopping_app/core/errors/failures.dart';
import 'package:family_shopping_app/core/local/sync_queue_service.dart';
import 'package:family_shopping_app/core/local/sync_status.dart';
import 'package:family_shopping_app/core/network/network_info.dart';
import 'package:family_shopping_app/core/utils/typedefs.dart';
import 'package:family_shopping_app/features/shopping/data/datasources/shopping_list_local_cache.dart';
import 'package:family_shopping_app/features/shopping/data/datasources/shopping_list_remote_data_source.dart';
import 'package:family_shopping_app/features/shopping/domain/entities/shopping_list_entity.dart';
import 'package:family_shopping_app/features/shopping/domain/repositories/shopping_list_repository.dart';

/// Cache-centric, offline-first implementation
/// (27_LOCAL_DATABASE_AND_OFFLINE_SYNC.md + 07_SYNC_ENGINE.md).
///
/// Reads: the UI always watches [ShoppingListLocalCache.watchCached] — the
/// remote realtime stream is only ever used to keep that cache fresh, never
/// read directly by the UI.
///
/// Writes: applied to the cache immediately (optimistic), then either sent
/// to Supabase right away (if online) or queued in [SyncQueueService] for
/// the sync engine to replay once connectivity returns (Phase 8).
class ShoppingListRepositoryImpl implements ShoppingListRepository {
  final ShoppingListRemoteDataSource _remote;
  final NetworkInfo _networkInfo;
  final ShoppingListLocalCache _cache;
  final SyncQueueService _syncQueue;
  final sb.SupabaseClient _supabaseClient;

  ShoppingListRepositoryImpl(
    this._remote,
    this._networkInfo,
    this._cache,
    this._syncQueue,
    this._supabaseClient,
  );

  bool _remoteSubscriptionStarted = false;

  @override
  Stream<List<ShoppingListEntity>> watchMyLists() {
    _ensureRemoteSubscription();
    return _cache.watchCached();
  }

  /// Idempotent: only subscribes to the realtime stream once per repository
  /// instance (the repository is a `keepAlive` singleton).
  void _ensureRemoteSubscription() {
    if (_remoteSubscriptionStarted) return;
    _remoteSubscriptionStarted = true;

    _networkInfo.isConnected.then((online) {
      if (!online) return;
      _remote.watchMyLists().listen(
        (remoteLists) => _cache.mergeFromRemote(remoteLists),
        onError: (_) {}, // connection drop — cache stays as last-known-good
      );
    });
  }

  @override
  ResultFuture<ShoppingListEntity> createList({
    required String title,
    required ShoppingListType type,
    String? familyId,
  }) async {
    final online = await _networkInfo.isConnected;
    final id = const Uuid().v4();

    if (online) {
      try {
        final created =
            await _remote.createList(id: id, title: title, type: type, familyId: familyId);
        await _cache.upsert(created);
        return Right(created);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (_) {
        return const Left(UnknownFailure());
      }
    }

    // Offline: create optimistically with the same client-generated id
    // the sync engine will later use to create the row on the server —
    // keeping ids identical avoids ever having two different ids for the
    // same logical list.
    final ownerId = _supabaseClient.auth.currentUser?.id;
    if (ownerId == null) return const Left(AuthFailure('کاربر وارد نشده است'));

    final entity = ShoppingListEntity(
      id: id,
      ownerId: ownerId,
      title: title,
      type: type,
      archived: false,
      estimatedTotal: 0,
      updatedAt: DateTime.now(),
      familyId: type == ShoppingListType.shared ? familyId : null,
    );
    await _cache.upsert(entity, status: SyncStatus.pending);
    await _syncQueue.enqueue(
      entityType: 'shopping_list',
      entityId: id,
      operation: 'create',
      payload: {'title': title, 'type': type.name, 'family_id': entity.familyId},
    );
    return Right(entity);
  }

  @override
  ResultFuture<void> renameList({required String listId, required String newTitle}) {
    return _optimisticUpdate(
      listId: listId,
      apply: (e) => ShoppingListEntity(
        id: e.id,
        familyId: e.familyId,
        ownerId: e.ownerId,
        title: newTitle,
        type: e.type,
        archived: e.archived,
        estimatedTotal: e.estimatedTotal,
        updatedAt: DateTime.now(),
      ),
      remoteCall: () => _remote.renameList(listId: listId, newTitle: newTitle),
      payload: {'title': newTitle},
    );
  }

  @override
  ResultFuture<void> setArchived({required String listId, required bool archived}) {
    return _optimisticUpdate(
      listId: listId,
      apply: (e) => ShoppingListEntity(
        id: e.id,
        familyId: e.familyId,
        ownerId: e.ownerId,
        title: e.title,
        type: e.type,
        archived: archived,
        estimatedTotal: e.estimatedTotal,
        updatedAt: DateTime.now(),
      ),
      remoteCall: () => _remote.setArchived(listId: listId, archived: archived),
      payload: {'archived': archived},
    );
  }

  @override
  ResultFuture<void> softDeleteList({required String listId}) async {
    final online = await _networkInfo.isConnected;
    if (online) {
      try {
        await _remote.softDeleteList(listId: listId);
        await _cache.removeByRemoteId(listId);
        return const Right(null);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (_) {
        return const Left(UnknownFailure());
      }
    }
    // Offline: hide it locally right away and queue the real delete.
    await _cache.removeByRemoteId(listId);
    await _syncQueue.enqueue(
      entityType: 'shopping_list',
      entityId: listId,
      operation: 'delete',
      payload: const {},
    );
    return const Right(null);
  }

  // Restore / permanent delete / trash listing are used from the rarely-
  // offline Trash screen — kept online-only for this scope (documented in
  // docs/LOOP_ENGINEERING_LOG.md, Phase 8 entry).
  @override
  ResultFuture<void> restoreList({required String listId}) =>
      _onlineOnly(() => _remote.restoreList(listId: listId));

  @override
  ResultFuture<void> permanentlyDeleteList({required String listId}) =>
      _onlineOnly(() => _remote.permanentlyDeleteList(listId: listId));

  @override
  ResultFuture<List<ShoppingListEntity>> getTrashedLists() async {
    if (!await _networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      return Right(await _remote.getTrashedLists());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  /// Shared helper for the two `update`-style mutations above: apply
  /// [apply] to the cached row immediately, then either push to Supabase
  /// now or queue [payload] for later.
  Future<Either<Failure, void>> _optimisticUpdate({
    required String listId,
    required ShoppingListEntity Function(ShoppingListEntity current) apply,
    required Future<void> Function() remoteCall,
    required Map<String, dynamic> payload,
  }) async {
    final current = (await _cache.getCached()).where((l) => l.id == listId);
    if (current.isEmpty) return const Left(CacheFailure('لیست در کش محلی یافت نشد'));
    final updated = apply(current.first);

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
      entityType: 'shopping_list',
      entityId: listId,
      operation: 'update',
      payload: payload,
    );
    return const Right(null);
  }

  Future<Either<Failure, void>> _onlineOnly(Future<void> Function() action) async {
    if (!await _networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      await action();
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }
}
