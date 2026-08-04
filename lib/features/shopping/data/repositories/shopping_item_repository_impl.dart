import 'package:dartz/dartz.dart';

import 'package:family_shopping_app/core/errors/exceptions.dart';
import 'package:family_shopping_app/core/errors/failures.dart';
import 'package:family_shopping_app/core/network/network_info.dart';
import 'package:family_shopping_app/core/utils/typedefs.dart';
import 'package:family_shopping_app/features/shopping/data/datasources/shopping_item_remote_data_source.dart';
import 'package:family_shopping_app/features/shopping/domain/entities/shopping_item_entity.dart';
import 'package:family_shopping_app/features/shopping/domain/repositories/shopping_item_repository.dart';

class ShoppingItemRepositoryImpl implements ShoppingItemRepository {
  final ShoppingItemRemoteDataSource _remote;
  final NetworkInfo _networkInfo;

  ShoppingItemRepositoryImpl(this._remote, this._networkInfo);

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
  }) async {
    if (!await _networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      return Right(await _remote.addItem(
        shoppingListId: shoppingListId,
        name: name,
        quantity: quantity,
        unit: unit,
        categoryId: categoryId,
        brand: brand,
        notes: notes,
        estimatedPrice: estimatedPrice,
      ));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
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
  }) => _guard(() => _remote.updateItem(
        itemId: itemId,
        name: name,
        quantity: quantity,
        unit: unit,
        categoryId: categoryId,
        brand: brand,
        notes: notes,
        estimatedPrice: estimatedPrice,
      ));

  @override
  ResultFuture<void> deleteItem({required String itemId}) =>
      _guard(() => _remote.deleteItem(itemId: itemId));

  @override
  ResultFuture<void> setPurchased({
    required String itemId,
    required bool purchased,
    double? purchasedPrice,
  }) =>
      _guard(() => _remote.setPurchased(
            itemId: itemId,
            purchased: purchased,
            purchasedPrice: purchasedPrice,
          ));

  @override
  Stream<List<ShoppingItemEntity>> watchItems({required String shoppingListId}) {
    return _remote.watchItems(shoppingListId: shoppingListId);
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
