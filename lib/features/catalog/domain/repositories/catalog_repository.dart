import 'package:family_shopping_app/core/utils/typedefs.dart';
import 'package:family_shopping_app/features/catalog/domain/entities/catalog_product_entity.dart';

abstract class CatalogRepository {
  /// Server-side fuzzy/typo-tolerant search across the shared catalog
  /// (17_PRODUCT_SEARCH_AND_AUTOCOMPLETE.md - Level 2+4). Requires
  /// connectivity; callers should fall back to local history search
  /// (features/shopping's SearchProductNamesUseCase) when offline.
  ResultFuture<List<CatalogProductEntity>> searchProducts(String query);

  ResultFuture<void> toggleFavorite({required String productId, required bool favorite});

  /// Fire-and-forget usage tracking — feeds Milestone 2 Phase 5
  /// (frequently-purchased suggestions). Failure here should never block
  /// the shopping-item flow that triggered it.
  ResultFuture<void> recordPurchase({required String productId, required double quantity});
}
