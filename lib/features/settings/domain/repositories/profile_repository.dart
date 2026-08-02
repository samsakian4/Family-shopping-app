import 'dart:typed_data';

import 'package:family_shopping_app/core/utils/typedefs.dart';
import 'package:family_shopping_app/features/auth/domain/entities/user_entity.dart';

/// Profile editing lives in its own repository (Settings feature) even
/// though it reads/writes the same `profiles` row Auth created, per
/// Single Responsibility (04_SYSTEM_ARCHITECTURE.md).
abstract class ProfileRepository {
  ResultFuture<UserEntity> updateProfile({
    String? displayName,
    String? language,
    String? theme,
  });

  /// Uploads [bytes] as the user's avatar and returns the new public URL.
  ResultFuture<String> uploadAvatar(Uint8List bytes, {required String fileExtension});
}
