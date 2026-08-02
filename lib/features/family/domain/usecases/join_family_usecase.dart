import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import 'package:family_shopping_app/core/errors/failures.dart';
import 'package:family_shopping_app/core/usecases/usecase.dart';
import 'package:family_shopping_app/core/utils/typedefs.dart';
import 'package:family_shopping_app/features/family/domain/entities/family_entity.dart';
import 'package:family_shopping_app/features/family/domain/repositories/family_repository.dart';

class JoinFamilyParams extends Equatable {
  final String invitationCode;
  const JoinFamilyParams({required this.invitationCode});

  @override
  List<Object?> get props => [invitationCode];
}

class JoinFamilyUseCase implements UseCase<FamilyEntity, JoinFamilyParams> {
  final FamilyRepository _repository;
  JoinFamilyUseCase(this._repository);

  @override
  ResultFuture<FamilyEntity> call(JoinFamilyParams params) async {
    if (params.invitationCode.trim().isEmpty) {
      return const Left(ValidationFailure('کد دعوت را وارد کنید'));
    }
    return _repository.joinFamily(invitationCode: params.invitationCode.trim());
  }
}
