import 'package:family_shopping_app/features/shopping/domain/entities/shopping_list_entity.dart';

class ShoppingListModel extends ShoppingListEntity {
  const ShoppingListModel({
    required super.id,
    required super.ownerId,
    required super.title,
    required super.type,
    required super.archived,
    required super.estimatedTotal,
    required super.updatedAt,
    super.familyId,
  });

  factory ShoppingListModel.fromJson(Map<String, dynamic> json) {
    return ShoppingListModel(
      id: json['id'] as String,
      familyId: json['family_id'] as String?,
      ownerId: json['owner_id'] as String,
      title: json['title'] as String,
      type: shoppingListTypeFromString(json['type'] as String),
      archived: json['archived'] as bool,
      estimatedTotal: (json['estimated_total'] as num).toDouble(),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}
