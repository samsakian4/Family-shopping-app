import 'package:family_shopping_app/core/usecases/usecase.dart';
import 'package:family_shopping_app/core/utils/typedefs.dart';
import 'package:family_shopping_app/features/shopping/domain/entities/shopping_item_entity.dart';
import 'package:family_shopping_app/features/shopping/domain/repositories/category_repository.dart';

class GetCategoriesUseCase implements UseCase<List<CategoryEntity>, NoParams> {
  final CategoryRepository _repository;
  GetCategoriesUseCase(this._repository);

  @override
  ResultFuture<List<CategoryEntity>> call(NoParams params) => _repository.getCategories();
}
