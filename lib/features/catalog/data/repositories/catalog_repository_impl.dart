import 'package:dartz/dartz.dart';

import 'package:family_shopping_app/core/errors/exceptions.dart';
import 'package:family_shopping_app/core/errors/failures.dart';
import 'package:family_shopping_app/core/network/network_info.dart';
import 'package:family_shopping_app/core/utils/typedefs.dart';
import 'package:family_shopping_app/features/catalog/data/datasources/catalog_remote_data_source.dart';
import 'package:family_shopping_app/features/catalog/domain/entities/catalog_product_entity.dart';
import 'package:family_shopping_app/features/catalog/domain/repositories/catalog_repository.dart';

class CatalogRepositoryImpl implements CatalogRepository {
  final CatalogRemoteDataSource _remote;
  final NetworkInfo _networkInfo;

  CatalogRepositoryImpl(this._remote, this._networkInfo);

  @override
  ResultFuture<List<CatalogProductEntity>> searchProducts(String query) async {
    if (query.trim().isEmpty) return const Right([]);
    if (!await _networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      return Right(await _remote.searchProducts(query.trim()));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  ResultFuture<void> toggleFavorite({required String productId, required bool favorite}) async {
    if (!await _networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      await _remote.toggleFavorite(productId: productId, favorite: favorite);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  ResultFuture<void> recordPurchase({required String productId, required double quantity}) async {
    // Best-effort: never let history tracking block the caller.
    if (!await _networkInfo.isConnected) return const Right(null);
    try {
      await _remote.recordPurchase(productId: productId, quantity: quantity);
      return const Right(null);
    } catch (_) {
      return const Right(null);
    }
  }
}
