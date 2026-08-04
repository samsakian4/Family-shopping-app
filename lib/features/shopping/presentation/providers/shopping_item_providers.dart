import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:family_shopping_app/core/usecases/usecase.dart';
import 'package:family_shopping_app/features/shopping/data/datasources/category_local_cache.dart';
import 'package:family_shopping_app/features/shopping/data/datasources/category_remote_data_source.dart';
import 'package:family_shopping_app/features/shopping/data/datasources/shopping_item_local_cache.dart';
import 'package:family_shopping_app/features/shopping/data/datasources/shopping_item_remote_data_source.dart';
import 'package:family_shopping_app/features/shopping/data/repositories/category_repository_impl.dart';
import 'package:family_shopping_app/features/shopping/data/repositories/shopping_item_repository_impl.dart';
import 'package:family_shopping_app/features/shopping/domain/entities/shopping_item_entity.dart';
import 'package:family_shopping_app/features/shopping/domain/repositories/category_repository.dart';
import 'package:family_shopping_app/features/shopping/domain/repositories/shopping_item_repository.dart';
import 'package:family_shopping_app/features/shopping/domain/usecases/add_item_usecase.dart';
import 'package:family_shopping_app/features/shopping/domain/usecases/get_categories_usecase.dart';
import 'package:family_shopping_app/features/shopping/domain/usecases/manage_item_usecases.dart';
import 'package:family_shopping_app/providers/core_providers.dart';

part 'shopping_item_providers.g.dart';

@Riverpod(keepAlive: true)
CategoryRemoteDataSource categoryRemoteDataSource(Ref ref) {
  return CategoryRemoteDataSourceImpl(ref.watch(supabaseClientProvider));
}

@Riverpod(keepAlive: true)
CategoryLocalCache categoryLocalCache(Ref ref) {
  return CategoryLocalCache(ref.watch(isarProvider));
}

@Riverpod(keepAlive: true)
CategoryRepository categoryRepository(Ref ref) {
  return CategoryRepositoryImpl(
    ref.watch(categoryRemoteDataSourceProvider),
    ref.watch(networkInfoProvider),
    ref.watch(categoryLocalCacheProvider),
  );
}

@Riverpod(keepAlive: true)
ShoppingItemRemoteDataSource shoppingItemRemoteDataSource(Ref ref) {
  return ShoppingItemRemoteDataSourceImpl(ref.watch(supabaseClientProvider));
}

@Riverpod(keepAlive: true)
ShoppingItemLocalCache shoppingItemLocalCache(Ref ref) {
  return ShoppingItemLocalCache(ref.watch(isarProvider));
}

@Riverpod(keepAlive: true)
ShoppingItemRepository shoppingItemRepository(Ref ref) {
  return ShoppingItemRepositoryImpl(
    ref.watch(shoppingItemRemoteDataSourceProvider),
    ref.watch(networkInfoProvider),
    ref.watch(shoppingItemLocalCacheProvider),
  );
}

@riverpod
AddItemUseCase addItemUseCase(Ref ref) =>
    AddItemUseCase(ref.watch(shoppingItemRepositoryProvider));

@riverpod
UpdateItemUseCase updateItemUseCase(Ref ref) =>
    UpdateItemUseCase(ref.watch(shoppingItemRepositoryProvider));

@riverpod
DeleteItemUseCase deleteItemUseCase(Ref ref) =>
    DeleteItemUseCase(ref.watch(shoppingItemRepositoryProvider));

@riverpod
SetPurchasedUseCase setPurchasedUseCase(Ref ref) =>
    SetPurchasedUseCase(ref.watch(shoppingItemRepositoryProvider));

@riverpod
GetCategoriesUseCase getCategoriesUseCase(Ref ref) =>
    GetCategoriesUseCase(ref.watch(categoryRepositoryProvider));

@riverpod
Future<List<CategoryEntity>> categories(Ref ref) async {
  final useCase = ref.watch(getCategoriesUseCaseProvider);
  final result = await useCase(const NoParams());
  return result.fold((failure) => throw failure.message, (list) => list);
}

@riverpod
Stream<List<ShoppingItemEntity>> shoppingItems(Ref ref, String shoppingListId) {
  return ref.watch(shoppingItemRepositoryProvider).watchItems(shoppingListId: shoppingListId);
}
