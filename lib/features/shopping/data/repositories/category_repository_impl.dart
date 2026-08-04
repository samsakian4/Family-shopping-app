import 'package:dartz/dartz.dart';

import 'package:family_shopping_app/core/errors/exceptions.dart';
import 'package:family_shopping_app/core/errors/failures.dart';
import 'package:family_shopping_app/core/network/network_info.dart';
import 'package:family_shopping_app/core/utils/typedefs.dart';
import 'package:family_shopping_app/features/shopping/data/datasources/category_local_cache.dart';
import 'package:family_shopping_app/features/shopping/data/datasources/category_remote_data_source.dart';
import 'package:family_shopping_app/features/shopping/domain/entities/shopping_item_entity.dart';
import 'package:family_shopping_app/features/shopping/domain/repositories/category_repository.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  final CategoryRemoteDataSource _remote;
  final NetworkInfo _networkInfo;
  final CategoryLocalCache _cache;

  CategoryRepositoryImpl(this._remote, this._networkInfo, this._cache);

  @override
  ResultFuture<List<CategoryEntity>> getCategories() async {
    if (!await _networkInfo.isConnected) {
      // Offline fallback so "Add Product" still works without internet
      // (27_LOCAL_DATABASE_AND_OFFLINE_SYNC.md).
      return Right(await _cache.getCached());
    }
    try {
      final categories = await _remote.getCategories();
      await _cache.replaceAll(categories);
      return Right(categories);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }
}
