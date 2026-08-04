import 'package:isar/isar.dart';

import 'package:family_shopping_app/core/local/sync_status.dart';
import 'package:family_shopping_app/features/shopping/domain/entities/shopping_list_entity.dart';

part 'shopping_list_local.g.dart';

/// Local cache mirror of `shopping_lists` (27_LOCAL_DATABASE_AND_OFFLINE_SYNC.md
/// - ShoppingListCollection). The UI reads from this collection first;
/// Supabase writes update it via the repository's write-through cache.
@collection
class ShoppingListLocal {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String remoteId;

  String? familyId;
  late String ownerId;
  late String title;
  late String type; // 'personal' | 'shared'
  late bool archived;
  late double estimatedTotal;
  late DateTime updatedAt;

  @enumerated
  SyncStatus syncStatus = SyncStatus.synced;

  ShoppingListEntity toEntity() => ShoppingListEntity(
        id: remoteId,
        familyId: familyId,
        ownerId: ownerId,
        title: title,
        type: shoppingListTypeFromString(type),
        archived: archived,
        estimatedTotal: estimatedTotal,
        updatedAt: updatedAt,
      );

  static ShoppingListLocal fromEntity(ShoppingListEntity e) => ShoppingListLocal()
    ..remoteId = e.id
    ..familyId = e.familyId
    ..ownerId = e.ownerId
    ..title = e.title
    ..type = e.type.name
    ..archived = e.archived
    ..estimatedTotal = e.estimatedTotal
    ..updatedAt = e.updatedAt
    ..syncStatus = SyncStatus.synced;
}
