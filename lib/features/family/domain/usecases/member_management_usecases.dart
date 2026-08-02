import 'package:equatable/equatable.dart';

import 'package:family_shopping_app/core/usecases/usecase.dart';
import 'package:family_shopping_app/core/utils/typedefs.dart';
import 'package:family_shopping_app/features/family/domain/repositories/family_repository.dart';

class LeaveFamilyUseCase implements UseCase<void, NoParams> {
  final FamilyRepository _repository;
  LeaveFamilyUseCase(this._repository);

  @override
  ResultFuture<void> call(NoParams params) => _repository.leaveFamily();
}

class RemoveMemberParams extends Equatable {
  final String memberUserId;
  const RemoveMemberParams({required this.memberUserId});

  @override
  List<Object?> get props => [memberUserId];
}

class RemoveMemberUseCase implements UseCase<void, RemoveMemberParams> {
  final FamilyRepository _repository;
  RemoveMemberUseCase(this._repository);

  @override
  ResultFuture<void> call(RemoveMemberParams params) {
    return _repository.removeMember(memberUserId: params.memberUserId);
  }
}
