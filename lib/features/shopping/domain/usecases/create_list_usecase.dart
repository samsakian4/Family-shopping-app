import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import 'package:family_shopping_app/core/errors/failures.dart';
import 'package:family_shopping_app/core/usecases/usecase.dart';
import 'package:family_shopping_app/core/utils/typedefs.dart';
import 'package:family_shopping_app/features/shopping/domain/entities/shopping_list_entity.dart';
import 'package:family_shopping_app/features/shopping/domain/repositories/shopping_list_repository.dart';

class CreateListParams extends Equatable {
  final String title;
  final ShoppingListType type;
  final String? familyId;

  const CreateListParams({required this.title, required this.type, this.familyId});

  @override
  List<Object?> get props => [title, type, familyId];
}

class CreateListUseCase implements UseCase<ShoppingListEntity, CreateListParams> {
  final ShoppingListRepository _repository;
  CreateListUseCase(this._repository);

  @override
  ResultFuture<ShoppingListEntity> call(CreateListParams params) async {
    if (params.title.trim().isEmpty) {
      return const Left(ValidationFailure('نام لیست را وارد کنید'));
    }
    if (params.type == ShoppingListType.shared && params.familyId == null) {
      return const Left(ValidationFailure('برای لیست مشترک باید عضو یک خانواده باشید'));
    }
    return _repository.createList(
      title: params.title.trim(),
      type: params.type,
      familyId: params.familyId,
    );
  }
}
