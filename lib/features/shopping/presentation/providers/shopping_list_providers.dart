import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:family_shopping_app/core/usecases/usecase.dart';
import 'package:family_shopping_app/features/shopping/data/datasources/shopping_list_local_cache.dart';
import 'package:family_shopping_app/features/shopping/data/datasources/shopping_list_remote_data_source.dart';
import 'package:family_shopping_app/features/shopping/data/repositories/shopping_list_repository_impl.dart';
import 'package:family_shopping_app/features/shopping/domain/entities/shopping_list_entity.dart';
import 'package:family_shopping_app/features/shopping/domain/repositories/shopping_list_repository.dart';
import 'package:family_shopping_app/features/shopping/domain/usecases/create_list_usecase.dart';
import 'package:family_shopping_app/features/shopping/domain/usecases/get_trashed_lists_usecase.dart';
import 'package:family_shopping_app/features/shopping/domain/usecases/manage_list_usecases.dart';
import 'package:family_shopping_app/providers/core_providers.dart';

part 'shopping_list_providers.g.dart';

@Riverpod(keepAlive: true)
ShoppingListRemoteDataSource shoppingListRemoteDataSource(Ref ref) {
  return ShoppingListRemoteDataSourceImpl(ref.watch(supabaseClientProvider));
}

@Riverpod(keepAlive: true)
ShoppingListLocalCache shoppingListLocalCache(Ref ref) {
  return ShoppingListLocalCache(ref.watch(isarProvider));
}

@Riverpod(keepAlive: true)
ShoppingListRepository shoppingListRepository(Ref ref) {
  return ShoppingListRepositoryImpl(
    ref.watch(shoppingListRemoteDataSourceProvider),
    ref.watch(networkInfoProvider),
    ref.watch(shoppingListLocalCacheProvider),
  );
}

@riverpod
CreateListUseCase createListUseCase(Ref ref) =>
    CreateListUseCase(ref.watch(shoppingListRepositoryProvider));

@riverpod
RenameListUseCase renameListUseCase(Ref ref) =>
    RenameListUseCase(ref.watch(shoppingListRepositoryProvider));

@riverpod
SetArchivedUseCase setArchivedUseCase(Ref ref) =>
    SetArchivedUseCase(ref.watch(shoppingListRepositoryProvider));

@riverpod
SoftDeleteListUseCase softDeleteListUseCase(Ref ref) =>
    SoftDeleteListUseCase(ref.watch(shoppingListRepositoryProvider));

@riverpod
RestoreListUseCase restoreListUseCase(Ref ref) =>
    RestoreListUseCase(ref.watch(shoppingListRepositoryProvider));

@riverpod
PermanentlyDeleteListUseCase permanentlyDeleteListUseCase(Ref ref) =>
    PermanentlyDeleteListUseCase(ref.watch(shoppingListRepositoryProvider));

@riverpod
GetTrashedListsUseCase getTrashedListsUseCase(Ref ref) =>
    GetTrashedListsUseCase(ref.watch(shoppingListRepositoryProvider));

@riverpod
Stream<List<ShoppingListEntity>> myShoppingLists(Ref ref) {
  return ref.watch(shoppingListRepositoryProvider).watchMyLists();
}

@riverpod
Future<List<ShoppingListEntity>> trashedLists(Ref ref) async {
  final useCase = ref.watch(getTrashedListsUseCaseProvider);
  final result = await useCase(const NoParams());
  return result.fold((failure) => throw failure.message, (lists) => lists);
}
