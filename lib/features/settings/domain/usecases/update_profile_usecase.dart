import 'package:equatable/equatable.dart';

import 'package:family_shopping_app/core/usecases/usecase.dart';
import 'package:family_shopping_app/core/utils/typedefs.dart';
import 'package:family_shopping_app/features/auth/domain/entities/user_entity.dart';
import 'package:family_shopping_app/features/settings/domain/repositories/profile_repository.dart';

class UpdateProfileParams extends Equatable {
  final String? displayName;
  final String? language; // 'fa' | 'en' (FT-121)
  final String? theme; // 'light' | 'dark' | 'system' (FT-120)

  const UpdateProfileParams({this.displayName, this.language, this.theme});

  @override
  List<Object?> get props => [displayName, language, theme];
}

class UpdateProfileUseCase implements UseCase<UserEntity, UpdateProfileParams> {
  final ProfileRepository _repository;

  UpdateProfileUseCase(this._repository);

  @override
  ResultFuture<UserEntity> call(UpdateProfileParams params) {
    return _repository.updateProfile(
      displayName: params.displayName,
      language: params.language,
      theme: params.theme,
    );
  }
}
