import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import 'package:family_shopping_app/core/errors/failures.dart';
import 'package:family_shopping_app/core/usecases/usecase.dart';
import 'package:family_shopping_app/core/utils/typedefs.dart';
import 'package:family_shopping_app/features/shopping/domain/repositories/shopping_item_repository.dart';

class UpdateItemParams extends Equatable {
  final String itemId;
  final String? name;
  final double? quantity;
  final String? unit;
  final String? categoryId;
  final String? brand;
  final String? notes;
  final double? estimatedPrice;

  const UpdateItemParams({
    required this.itemId,
    this.name,
    this.quantity,
    this.unit,
    this.categoryId,
    this.brand,
    this.notes,
    this.estimatedPrice,
  });

  @override
  List<Object?> get props =>
      [itemId, name, quantity, unit, categoryId, brand, notes, estimatedPrice];
}

class UpdateItemUseCase implements UseCase<void, UpdateItemParams> {
  final ShoppingItemRepository _repository;
  UpdateItemUseCase(this._repository);

  @override
  ResultFuture<void> call(UpdateItemParams params) async {
    if (params.name != null && params.name!.trim().isEmpty) {
      return const Left(ValidationFailure('نام محصول نمی‌تواند خالی باشد'));
    }
    if (params.quantity != null && params.quantity! <= 0) {
      return const Left(ValidationFailure('تعداد باید بزرگ‌تر از صفر باشد'));
    }
    return _repository.updateItem(
      itemId: params.itemId,
      name: params.name?.trim(),
      quantity: params.quantity,
      unit: params.unit,
      categoryId: params.categoryId,
      brand: params.brand,
      notes: params.notes,
      estimatedPrice: params.estimatedPrice,
    );
  }
}

class DeleteItemParams extends Equatable {
  final String itemId;
  const DeleteItemParams({required this.itemId});

  @override
  List<Object?> get props => [itemId];
}

class DeleteItemUseCase implements UseCase<void, DeleteItemParams> {
  final ShoppingItemRepository _repository;
  DeleteItemUseCase(this._repository);

  @override
  ResultFuture<void> call(DeleteItemParams params) => _repository.deleteItem(itemId: params.itemId);
}

class SetPurchasedParams extends Equatable {
  final String itemId;
  final bool purchased;
  final double? purchasedPrice;

  const SetPurchasedParams({
    required this.itemId,
    required this.purchased,
    this.purchasedPrice,
  });

  @override
  List<Object?> get props => [itemId, purchased, purchasedPrice];
}

class SetPurchasedUseCase implements UseCase<void, SetPurchasedParams> {
  final ShoppingItemRepository _repository;
  SetPurchasedUseCase(this._repository);

  @override
  ResultFuture<void> call(SetPurchasedParams params) {
    return _repository.setPurchased(
      itemId: params.itemId,
      purchased: params.purchased,
      purchasedPrice: params.purchasedPrice,
    );
  }
}
