import 'package:family_shopping_app/core/utils/typedefs.dart';
import 'package:family_shopping_app/features/shopping/domain/entities/shopping_list_entity.dart';

abstract class ShoppingListRepository {
  ResultFuture<ShoppingListEntity> createList({
    required String title,
    required ShoppingListType type,
    String? familyId,
  });

  ResultFuture<void> renameList({required String listId, required String newTitle});

  ResultFuture<void> setArchived({required String listId, required bool archived});

  ResultFuture<void> softDeleteList({required String listId});

  ResultFuture<void> restoreList({required String listId});

  ResultFuture<void> permanentlyDeleteList({required String listId});

  /// Soft-deleted lists still within the 30-day retention window (FT-025).
  ResultFuture<List<ShoppingListEntity>> getTrashedLists();

  /// All lists visible to the current user (own personal + their family's
  /// shared), excluding soft-deleted ones. UI filters into
  /// Personal/Shared/Archived tabs (10_UI_UX.md - Shopping Lists Screen).
  Stream<List<ShoppingListEntity>> watchMyLists();
}
