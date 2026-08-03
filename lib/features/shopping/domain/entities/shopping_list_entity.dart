import 'package:equatable/equatable.dart';

enum ShoppingListType { personal, shared }

ShoppingListType shoppingListTypeFromString(String value) {
  return ShoppingListType.values.firstWhere(
    (t) => t.name == value,
    orElse: () => ShoppingListType.personal,
  );
}

class ShoppingListEntity extends Equatable {
  final String id;
  final String? familyId;
  final String ownerId;
  final String title;
  final ShoppingListType type;
  final bool archived;
  final double estimatedTotal;
  final DateTime updatedAt;

  const ShoppingListEntity({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.type,
    required this.archived,
    required this.estimatedTotal,
    required this.updatedAt,
    this.familyId,
  });

  @override
  List<Object?> get props =>
      [id, familyId, ownerId, title, type, archived, estimatedTotal, updatedAt];
}
