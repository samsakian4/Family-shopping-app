import 'package:family_shopping_app/core/utils/typedefs.dart';
import 'package:family_shopping_app/features/shopping/domain/entities/shopping_item_entity.dart';

abstract class ShoppingItemRepository {
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
  });

  ResultFuture<void> updateItem({
    required String itemId,
    String? name,
    double? quantity,
    String? unit,
    String? categoryId,
    String? brand,
    String? notes,
    double? estimatedPrice,
  });

  ResultFuture<void> deleteItem({required String itemId});

  ResultFuture<void> setPurchased({
    required String itemId,
    required bool purchased,
    double? purchasedPrice,
  });

  /// Realtime item list for a shopping list (04_SYSTEM_ARCHITECTURE.md -
  /// Realtime Architecture: "Product added/updated/deleted").
  Stream<List<ShoppingItemEntity>> watchItems({required String shoppingListId});

  /// Local-only instant autocomplete (17_PRODUCT_SEARCH_AND_AUTOCOMPLETE.md
  /// - Level 1: Local Cache). Always available, even offline.
  Future<List<String>> searchProductNames(String query);
}
