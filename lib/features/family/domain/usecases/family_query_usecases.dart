import 'package:equatable/equatable.dart';

import 'package:family_shopping_app/core/usecases/usecase.dart';
import 'package:family_shopping_app/core/utils/typedefs.dart';
import 'package:family_shopping_app/features/family/domain/entities/family_entity.dart';
import 'package:family_shopping_app/features/family/domain/repositories/family_repository.dart';

class GetMyFamilyUseCase implements UseCase<FamilyEntity?, NoParams> {
  final FamilyRepository _repository;
  GetMyFamilyUseCase(this._repository);

  @override
  ResultFuture<FamilyEntity?> call(NoParams params) => _repository.getMyFamily();
}

class GetMembersParams extends Equatable {
  final String familyId;
  const GetMembersParams({required this.familyId});

  @override
  List<Object?> get props => [familyId];
}

class GetMembersUseCase
    implements UseCase<List<FamilyMemberEntity>, GetMembersParams> {
  final FamilyRepository _repository;
  GetMembersUseCase(this._repository);

  @override
  ResultFuture<List<FamilyMemberEntity>> call(GetMembersParams params) {
    return _repository.getMembers(familyId: params.familyId);
  }
}

class RegenerateInviteCodeUseCase implements UseCase<String, NoParams> {
  final FamilyRepository _repository;
  RegenerateInviteCodeUseCase(this._repository);

  @override
  ResultFuture<String> call(NoParams params) => _repository.regenerateInviteCode();
}
