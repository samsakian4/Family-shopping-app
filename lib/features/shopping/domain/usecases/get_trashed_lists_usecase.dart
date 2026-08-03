import 'package:family_shopping_app/core/usecases/usecase.dart';
import 'package:family_shopping_app/core/utils/typedefs.dart';
import 'package:family_shopping_app/features/shopping/domain/entities/shopping_list_entity.dart';
import 'package:family_shopping_app/features/shopping/domain/repositories/shopping_list_repository.dart';

class GetTrashedListsUseCase implements UseCase<List<ShoppingListEntity>, NoParams> {
  final ShoppingListRepository _repository;
  GetTrashedListsUseCase(this._repository);

  @override
  ResultFuture<List<ShoppingListEntity>> call(NoParams params) =>
      _repository.getTrashedLists();
}
