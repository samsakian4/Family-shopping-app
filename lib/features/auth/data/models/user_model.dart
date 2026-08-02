import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import 'package:family_shopping_app/features/auth/domain/entities/user_entity.dart';

/// Data-layer model: knows how to build itself from a Supabase [sb.User]
/// plus the `profiles` row. The domain layer never sees this class.
class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.email,
    super.displayName,
    super.avatarUrl,
    super.language,
    super.theme,
    super.emailVerified,
  });

  factory UserModel.fromSupabase({
    required sb.User authUser,
    Map<String, dynamic>? profileRow,
  }) {
    return UserModel(
      id: authUser.id,
      email: authUser.email ?? '',
      displayName: profileRow?['display_name'] as String? ??
          authUser.userMetadata?['display_name'] as String?,
      avatarUrl: profileRow?['avatar_url'] as String?,
      language: profileRow?['language'] as String? ?? 'fa',
      theme: profileRow?['theme'] as String? ?? 'system',
      emailVerified: authUser.emailConfirmedAt != null,
    );
  }
}
