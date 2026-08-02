import 'dart:async';
import 'dart:typed_data';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:family_shopping_app/features/settings/domain/usecases/update_profile_usecase.dart';
import 'package:family_shopping_app/features/settings/domain/usecases/upload_avatar_usecase.dart';
import 'package:family_shopping_app/features/settings/presentation/providers/profile_providers.dart';

part 'profile_controller.g.dart';

@riverpod
class ProfileController extends _$ProfileController {
  @override
  FutureOr<void> build() {}

  Future<bool> updateProfile({String? displayName, String? language, String? theme}) async {
    state = const AsyncLoading();
    final useCase = ref.read(updateProfileUseCaseProvider);
    final result = await useCase(
      UpdateProfileParams(displayName: displayName, language: language, theme: theme),
    );
    return result.fold(
      (failure) {
        state = AsyncError(failure.message, StackTrace.current);
        return false;
      },
      (_) {
        state = const AsyncData(null);
        return true;
      },
    );
  }

  Future<bool> uploadAvatar(Uint8List bytes, String fileExtension) async {
    state = const AsyncLoading();
    final useCase = ref.read(uploadAvatarUseCaseProvider);
    final result = await useCase(
      UploadAvatarParams(bytes: bytes, fileExtension: fileExtension),
    );
    return result.fold(
      (failure) {
        state = AsyncError(failure.message, StackTrace.current);
        return false;
      },
      (_) {
        state = const AsyncData(null);
        return true;
      },
    );
  }
}
