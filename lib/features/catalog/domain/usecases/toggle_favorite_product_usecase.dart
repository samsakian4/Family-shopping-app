import 'package:equatable/equatable.dart';

import 'package:family_shopping_app/core/usecases/usecase.dart';
import 'package:family_shopping_app/core/utils/typedefs.dart';
import 'package:family_shopping_app/features/catalog/domain/repositories/catalog_repository.dart';

class ToggleFavoriteParams extends Equatable {
  final String productId;
  final bool favorite;
  const ToggleFavoriteParams({required this.productId, required this.favorite});

  @override
  List<Object?> get props => [productId, favorite];
}

class ToggleFavoriteProductUseCase implements UseCase<void, ToggleFavoriteParams> {
  final CatalogRepository _repository;
  ToggleFavoriteProductUseCase(this._repository);

  @override
  ResultFuture<void> call(ToggleFavoriteParams params) {
    return _repository.toggleFavorite(productId: params.productId, favorite: params.favorite);
  }
}
