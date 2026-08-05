import 'package:family_shopping_app/features/shopping/domain/repositories/shopping_item_repository.dart';

/// Not wrapped in the usual Either<Failure,...> shape on purpose — this is
/// a pure local read with no failure modes worth modeling (empty query ->
/// empty list, that's it). Matches 17_PRODUCT_SEARCH_AND_AUTOCOMPLETE.md's
/// "Offline Behavior: local search always available".
class SearchProductNamesUseCase {
  final ShoppingItemRepository _repository;
  SearchProductNamesUseCase(this._repository);

  Future<List<String>> call(String query) => _repository.searchProductNames(query);
}
