import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import 'package:family_shopping_app/core/errors/failures.dart';
import 'package:family_shopping_app/core/usecases/usecase.dart';
import 'package:family_shopping_app/core/utils/typedefs.dart';
import 'package:family_shopping_app/features/shopping/domain/entities/shopping_item_entity.dart';
import 'package:family_shopping_app/features/shopping/domain/repositories/shopping_item_repository.dart';

class AddItemParams extends Equatable {
  final String shoppingListId;
  final String name;
  final double quantity;
  final String? unit;
  final String? categoryId;
  final String? brand;
  final String? notes;
  final double? estimatedPrice;

  const AddItemParams({
    required this.shoppingListId,
    required this.name,
    required this.quantity,
    this.unit,
    this.categoryId,
    this.brand,
    this.notes,
    this.estimatedPrice,
  });

  @override
  List<Object?> get props =>
      [shoppingListId, name, quantity, unit, categoryId, brand, notes, estimatedPrice];
}

class AddItemUseCase implements UseCase<ShoppingItemEntity, AddItemParams> {
  final ShoppingItemRepository _repository;
  AddItemUseCase(this._repository);

  @override
  ResultFuture<ShoppingItemEntity> call(AddItemParams params) async {
    if (params.name.trim().isEmpty) {
      return const Left(ValidationFailure('نام محصول را وارد کنید'));
    }
    if (params.quantity <= 0) {
      return const Left(ValidationFailure('تعداد باید بزرگ‌تر از صفر باشد'));
    }
    return _repository.addItem(
      shoppingListId: params.shoppingListId,
      name: params.name.trim(),
      quantity: params.quantity,
      unit: params.unit,
      categoryId: params.categoryId,
      brand: params.brand,
      notes: params.notes,
      estimatedPrice: params.estimatedPrice,
    );
  }
}
