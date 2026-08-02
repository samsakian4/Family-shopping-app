import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:family_shopping_app/features/settings/data/datasources/profile_remote_data_source.dart';
import 'package:family_shopping_app/features/settings/data/repositories/profile_repository_impl.dart';
import 'package:family_shopping_app/features/settings/domain/repositories/profile_repository.dart';
import 'package:family_shopping_app/features/settings/domain/usecases/update_profile_usecase.dart';
import 'package:family_shopping_app/features/settings/domain/usecases/upload_avatar_usecase.dart';
import 'package:family_shopping_app/providers/core_providers.dart';

part 'profile_providers.g.dart';

@Riverpod(keepAlive: true)
ProfileRemoteDataSource profileRemoteDataSource(Ref ref) {
  return ProfileRemoteDataSourceImpl(ref.watch(supabaseClientProvider));
}

@Riverpod(keepAlive: true)
ProfileRepository profileRepository(Ref ref) {
  return ProfileRepositoryImpl(
    ref.watch(profileRemoteDataSourceProvider),
    ref.watch(networkInfoProvider),
  );
}

@riverpod
UpdateProfileUseCase updateProfileUseCase(Ref ref) =>
    UpdateProfileUseCase(ref.watch(profileRepositoryProvider));

@riverpod
UploadAvatarUseCase uploadAvatarUseCase(Ref ref) =>
    UploadAvatarUseCase(ref.watch(profileRepositoryProvider));
