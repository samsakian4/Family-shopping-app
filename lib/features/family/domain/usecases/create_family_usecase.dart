import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import 'package:family_shopping_app/core/errors/failures.dart';
import 'package:family_shopping_app/core/usecases/usecase.dart';
import 'package:family_shopping_app/core/utils/typedefs.dart';
import 'package:family_shopping_app/features/family/domain/entities/family_entity.dart';
import 'package:family_shopping_app/features/family/domain/repositories/family_repository.dart';

class CreateFamilyParams extends Equatable {
  final String name;
  const CreateFamilyParams({required this.name});

  @override
  List<Object?> get props => [name];
}

class CreateFamilyUseCase implements UseCase<FamilyEntity, CreateFamilyParams> {
  final FamilyRepository _repository;
  CreateFamilyUseCase(this._repository);

  @override
  ResultFuture<FamilyEntity> call(CreateFamilyParams params) async {
    if (params.name.trim().isEmpty) {
      return const Left(ValidationFailure('نام خانواده را وارد کنید'));
    }
    return _repository.createFamily(name: params.name.trim());
  }
}
