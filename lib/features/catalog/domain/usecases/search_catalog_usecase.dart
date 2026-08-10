import 'package:family_shopping_app/core/utils/typedefs.dart';
import 'package:family_shopping_app/features/catalog/domain/entities/catalog_product_entity.dart';
import 'package:family_shopping_app/features/catalog/domain/repositories/catalog_repository.dart';

class SearchCatalogUseCase {
  final CatalogRepository _repository;
  SearchCatalogUseCase(this._repository);

  ResultFuture<List<CatalogProductEntity>> call(String query) {
    return _repository.searchProducts(query);
  }
}
