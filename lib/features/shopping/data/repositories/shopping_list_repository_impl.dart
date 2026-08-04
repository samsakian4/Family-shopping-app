import 'package:dartz/dartz.dart';

import 'package:family_shopping_app/core/errors/exceptions.dart';
import 'package:family_shopping_app/core/errors/failures.dart';
import 'package:family_shopping_app/core/network/network_info.dart';
import 'package:family_shopping_app/core/utils/typedefs.dart';
import 'package:family_shopping_app/features/shopping/data/datasources/shopping_list_local_cache.dart';
import 'package:family_shopping_app/features/shopping/data/datasources/shopping_list_remote_data_source.dart';
import 'package:family_shopping_app/features/shopping/domain/entities/shopping_list_entity.dart';
import 'package:family_shopping_app/features/shopping/domain/repositories/shopping_list_repository.dart';

class ShoppingListRepositoryImpl implements ShoppingListRepository {
  final ShoppingListRemoteDataSource _remote;
  final NetworkInfo _networkInfo;
  final ShoppingListLocalCache _cache;

  ShoppingListRepositoryImpl(this._remote, this._networkInfo, this._cache);

  @override
  ResultFuture<ShoppingListEntity> createList({
    required String title,
    required ShoppingListType type,
    String? familyId,
  }) async {
    if (!await _networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      return Right(await _remote.createList(title: title, type: type, familyId: familyId));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  ResultFuture<void> renameList({required String listId, required String newTitle}) =>
      _guard(() => _remote.renameList(listId: listId, newTitle: newTitle));

  @override
  ResultFuture<void> setArchived({required String listId, required bool archived}) =>
      _guard(() => _remote.setArchived(listId: listId, archived: archived));

  @override
  ResultFuture<void> softDeleteList({required String listId}) =>
      _guard(() => _remote.softDeleteList(listId: listId));

  @override
  ResultFuture<void> restoreList({required String listId}) =>
      _guard(() => _remote.restoreList(listId: listId));

  @override
  ResultFuture<void> permanentlyDeleteList({required String listId}) =>
      _guard(() => _remote.permanentlyDeleteList(listId: listId));

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

  @override
  Stream<List<ShoppingListEntity>> watchMyLists() async* {
    // Offline-first read (27_LOCAL_DATABASE_AND_OFFLINE_SYNC.md - "Local
    // database is always written first. UI always reflects local data.").
    yield await _cache.getCached();

    if (!await _networkInfo.isConnected) return;

    await for (final remoteLists in _remote.watchMyLists()) {
      await _cache.replaceAll(remoteLists);
      yield remoteLists;
    }
  }

  Future<Either<Failure, void>> _guard(Future<void> Function() action) async {
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
