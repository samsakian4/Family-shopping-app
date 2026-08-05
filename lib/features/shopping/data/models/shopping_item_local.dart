import 'package:isar/isar.dart';

import 'package:family_shopping_app/core/local/sync_status.dart';
import 'package:family_shopping_app/features/shopping/domain/entities/shopping_item_entity.dart';

part 'shopping_item_local.g.dart';

/// Local cache mirror of `shopping_items`
/// (27_LOCAL_DATABASE_AND_OFFLINE_SYNC.md - ShoppingItemCollection).
@collection
class ShoppingItemLocal {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String remoteId;

  @Index()
  late String shoppingListId;

  String? categoryId;
  late String name;
  late double quantity;
  String? unit;
  String? brand;
  String? notes;
  double? estimatedPrice;
  double? purchasedPrice;
  late bool purchased;
  late int sortOrder;
  late DateTime updatedAt;

  @enumerated
  SyncStatus syncStatus = SyncStatus.synced;

  ShoppingItemEntity toEntity() => ShoppingItemEntity(
        id: remoteId,
        shoppingListId: shoppingListId,
        categoryId: categoryId,
        name: name,
        quantity: quantity,
        unit: unit,
        brand: brand,
        notes: notes,
        estimatedPrice: estimatedPrice,
        purchasedPrice: purchasedPrice,
        purchased: purchased,
        sortOrder: sortOrder,
        updatedAt: updatedAt,
      );

  static ShoppingItemLocal fromEntity(ShoppingItemEntity e) => ShoppingItemLocal()
    ..remoteId = e.id
    ..shoppingListId = e.shoppingListId
    ..categoryId = e.categoryId
    ..name = e.name
    ..quantity = e.quantity
    ..unit = e.unit
    ..brand = e.brand
    ..notes = e.notes
    ..estimatedPrice = e.estimatedPrice
    ..purchasedPrice = e.purchasedPrice
    ..purchased = e.purchased
    ..sortOrder = e.sortOrder
    ..updatedAt = e.updatedAt
    ..syncStatus = SyncStatus.synced;
}
