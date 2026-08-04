import 'package:equatable/equatable.dart';

class CategoryEntity extends Equatable {
  final String id;
  final String? familyId;
  final String name;
  final int sortOrder;

  const CategoryEntity({
    required this.id,
    required this.name,
    required this.sortOrder,
    this.familyId,
  });

  @override
  List<Object?> get props => [id, familyId, name, sortOrder];
}

class ShoppingItemEntity extends Equatable {
  final String id;
  final String shoppingListId;
  final String? categoryId;
  final String name;
  final double quantity;
  final String? unit;
  final String? brand;
  final String? notes;
  final double? estimatedPrice;
  final double? purchasedPrice;
  final bool purchased;
  final int sortOrder;

  const ShoppingItemEntity({
    required this.id,
    required this.shoppingListId,
    required this.name,
    required this.quantity,
    required this.purchased,
    required this.sortOrder,
    this.categoryId,
    this.unit,
    this.brand,
    this.notes,
    this.estimatedPrice,
    this.purchasedPrice,
  });

  @override
  List<Object?> get props => [
        id,
        shoppingListId,
        categoryId,
        name,
        quantity,
        unit,
        brand,
        notes,
        estimatedPrice,
        purchasedPrice,
        purchased,
        sortOrder,
      ];
}
