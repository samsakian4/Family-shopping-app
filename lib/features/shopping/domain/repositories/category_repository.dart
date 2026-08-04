import 'package:family_shopping_app/core/utils/typedefs.dart';
import 'package:family_shopping_app/features/shopping/domain/entities/shopping_item_entity.dart';

abstract class CategoryRepository {
  /// Default (system) categories + the current family's custom ones
  /// (FT-022).
  ResultFuture<List<CategoryEntity>> getCategories();
}
