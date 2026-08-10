import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:family_shopping_app/features/catalog/data/datasources/catalog_remote_data_source.dart';
import 'package:family_shopping_app/features/catalog/data/repositories/catalog_repository_impl.dart';
import 'package:family_shopping_app/features/catalog/domain/repositories/catalog_repository.dart';
import 'package:family_shopping_app/features/catalog/domain/usecases/search_catalog_usecase.dart';
import 'package:family_shopping_app/features/catalog/domain/usecases/toggle_favorite_product_usecase.dart';
import 'package:family_shopping_app/providers/core_providers.dart';

part 'catalog_providers.g.dart';

@Riverpod(keepAlive: true)
CatalogRemoteDataSource catalogRemoteDataSource(Ref ref) {
  return CatalogRemoteDataSourceImpl(ref.watch(supabaseClientProvider));
}

@Riverpod(keepAlive: true)
CatalogRepository catalogRepository(Ref ref) {
  return CatalogRepositoryImpl(
    ref.watch(catalogRemoteDataSourceProvider),
    ref.watch(networkInfoProvider),
  );
}

@riverpod
SearchCatalogUseCase searchCatalogUseCase(Ref ref) =>
    SearchCatalogUseCase(ref.watch(catalogRepositoryProvider));

@riverpod
ToggleFavoriteProductUseCase toggleFavoriteProductUseCase(Ref ref) =>
    ToggleFavoriteProductUseCase(ref.watch(catalogRepositoryProvider));
