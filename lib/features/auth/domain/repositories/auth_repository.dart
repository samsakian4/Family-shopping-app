import 'package:family_shopping_app/core/utils/typedefs.dart';
import 'package:family_shopping_app/features/auth/domain/entities/user_entity.dart';

/// Repository contract. Business logic depends only on this interface,
/// never on the Supabase implementation directly
/// (04_SYSTEM_ARCHITECTURE.md - Repository Pattern).
abstract class AuthRepository {
  ResultFuture<UserEntity> signUp({
    required String email,
    required String password,
    required String displayName,
  });

  ResultFuture<UserEntity> signIn({
    required String email,
    required String password,
  });

  ResultFuture<void> signOut();

  ResultFuture<void> resetPassword({required String email});

  ResultFuture<void> changePassword({required String newPassword});

  ResultFuture<UserEntity?> getCurrentUser();

  /// Emits the current user (or null) whenever auth state changes,
  /// including automatic token refresh (16_AUTH.md - Session Management).
  Stream<UserEntity?> get authStateChanges;
}
