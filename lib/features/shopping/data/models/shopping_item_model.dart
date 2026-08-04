import 'package:family_shopping_app/features/shopping/domain/entities/shopping_item_entity.dart';

class CategoryModel extends CategoryEntity {
  const CategoryModel({
    required super.id,
    required super.name,
    required super.sortOrder,
    super.familyId,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as String,
      familyId: json['family_id'] as String?,
      name: json['name'] as String,
      sortOrder: json['sort_order'] as int,
    );
  }
}

class ShoppingItemModel extends ShoppingItemEntity {
  const ShoppingItemModel({
    required super.id,
    required super.shoppingListId,
    required super.name,
    required super.quantity,
    required super.purchased,
    required super.sortOrder,
    super.categoryId,
    super.unit,
    super.brand,
    super.notes,
    super.estimatedPrice,
    super.purchasedPrice,
  });

  factory ShoppingItemModel.fromJson(Map<String, dynamic> json) {
    return ShoppingItemModel(
      id: json['id'] as String,
      shoppingListId: json['shopping_list_id'] as String,
      categoryId: json['category_id'] as String?,
      name: json['name'] as String,
      quantity: (json['quantity'] as num).toDouble(),
      unit: json['unit'] as String?,
      brand: json['brand'] as String?,
      notes: json['notes'] as String?,
      estimatedPrice: (json['estimated_price'] as num?)?.toDouble(),
      purchasedPrice: (json['purchased_price'] as num?)?.toDouble(),
      purchased: json['purchased'] as bool,
      sortOrder: json['sort_order'] as int,
    );
  }
}
