import 'package:isar/isar.dart';

import 'package:family_shopping_app/features/shopping/domain/entities/shopping_item_entity.dart';

part 'category_local.g.dart';

/// Categories change rarely — cached so the Add Product bottom sheet
/// (10_UI_UX.md) works offline (27_LOCAL_DATABASE_AND_OFFLINE_SYNC.md -
/// Product Data: recent products / search cache).
@collection
class CategoryLocal {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String remoteId;

  String? familyId;
  late String name;
  late int sortOrder;

  CategoryEntity toEntity() =>
      CategoryEntity(id: remoteId, familyId: familyId, name: name, sortOrder: sortOrder);

  static CategoryLocal fromEntity(CategoryEntity e) => CategoryLocal()
    ..remoteId = e.id
    ..familyId = e.familyId
    ..name = e.name
    ..sortOrder = e.sortOrder;
}
