import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:family_shopping_app/core/usecases/usecase.dart';
import 'package:family_shopping_app/features/shopping/domain/entities/shopping_list_entity.dart';
import 'package:family_shopping_app/features/shopping/domain/usecases/create_list_usecase.dart';
import 'package:family_shopping_app/features/shopping/domain/usecases/manage_list_usecases.dart';
import 'package:family_shopping_app/features/shopping/presentation/providers/shopping_list_providers.dart';

part 'shopping_list_controller.g.dart';

@riverpod
class ShoppingListController extends _$ShoppingListController {
  @override
  FutureOr<void> build() {}

  Future<bool> createList({
    required String title,
    required ShoppingListType type,
    String? familyId,
  }) => _run(() => ref.read(createListUseCaseProvider)(
        CreateListParams(title: title, type: type, familyId: familyId),
      ));

  Future<bool> rename(String listId, String newTitle) => _run(
        () => ref.read(renameListUseCaseProvider)(
          RenameListParams(listId: listId, newTitle: newTitle),
        ),
      );

  Future<bool> setArchived(String listId, bool archived) => _run(
        () => ref.read(setArchivedUseCaseProvider)(
          SetArchivedParams(listId: listId, archived: archived),
        ),
      );

  Future<bool> softDelete(String listId) async {
    final ok = await _run(
      () => ref.read(softDeleteListUseCaseProvider)(ListIdParams(listId: listId)),
    );
    if (ok) ref.invalidate(trashedListsProvider);
    return ok;
  }

  Future<bool> restore(String listId) async {
    final ok = await _run(
      () => ref.read(restoreListUseCaseProvider)(ListIdParams(listId: listId)),
    );
    if (ok) ref.invalidate(trashedListsProvider);
    return ok;
  }

  Future<bool> permanentlyDelete(String listId) async {
    final ok = await _run(
      () => ref.read(permanentlyDeleteListUseCaseProvider)(ListIdParams(listId: listId)),
    );
    if (ok) ref.invalidate(trashedListsProvider);
    return ok;
  }

  Future<bool> _run(Future<dynamic> Function() action) async {
    state = const AsyncLoading();
    final result = await action();
    return result.fold(
      (failure) {
        state = AsyncError(failure.message, StackTrace.current);
        return false;
      },
      (_) {
        state = const AsyncData(null);
        return true;
      },
    );
  }
}
