import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import 'package:family_shopping_app/core/errors/failures.dart';
import 'package:family_shopping_app/core/usecases/usecase.dart';
import 'package:family_shopping_app/core/utils/typedefs.dart';
import 'package:family_shopping_app/features/shopping/domain/repositories/shopping_list_repository.dart';

class RenameListParams extends Equatable {
  final String listId;
  final String newTitle;
  const RenameListParams({required this.listId, required this.newTitle});

  @override
  List<Object?> get props => [listId, newTitle];
}

class RenameListUseCase implements UseCase<void, RenameListParams> {
  final ShoppingListRepository _repository;
  RenameListUseCase(this._repository);

  @override
  ResultFuture<void> call(RenameListParams params) async {
    if (params.newTitle.trim().isEmpty) {
      return const Left(ValidationFailure('نام لیست نمی‌تواند خالی باشد'));
    }
    return _repository.renameList(listId: params.listId, newTitle: params.newTitle.trim());
  }
}

class SetArchivedParams extends Equatable {
  final String listId;
  final bool archived;
  const SetArchivedParams({required this.listId, required this.archived});

  @override
  List<Object?> get props => [listId, archived];
}

class SetArchivedUseCase implements UseCase<void, SetArchivedParams> {
  final ShoppingListRepository _repository;
  SetArchivedUseCase(this._repository);

  @override
  ResultFuture<void> call(SetArchivedParams params) {
    return _repository.setArchived(listId: params.listId, archived: params.archived);
  }
}

class ListIdParams extends Equatable {
  final String listId;
  const ListIdParams({required this.listId});

  @override
  List<Object?> get props => [listId];
}

class SoftDeleteListUseCase implements UseCase<void, ListIdParams> {
  final ShoppingListRepository _repository;
  SoftDeleteListUseCase(this._repository);

  @override
  ResultFuture<void> call(ListIdParams params) => _repository.softDeleteList(listId: params.listId);
}

class RestoreListUseCase implements UseCase<void, ListIdParams> {
  final ShoppingListRepository _repository;
  RestoreListUseCase(this._repository);

  @override
  ResultFuture<void> call(ListIdParams params) => _repository.restoreList(listId: params.listId);
}

class PermanentlyDeleteListUseCase implements UseCase<void, ListIdParams> {
  final ShoppingListRepository _repository;
  PermanentlyDeleteListUseCase(this._repository);

  @override
  ResultFuture<void> call(ListIdParams params) =>
      _repository.permanentlyDeleteList(listId: params.listId);
}
