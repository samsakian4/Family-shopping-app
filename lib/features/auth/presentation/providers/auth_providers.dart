import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:family_shopping_app/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:family_shopping_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:family_shopping_app/features/auth/domain/entities/user_entity.dart';
import 'package:family_shopping_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:family_shopping_app/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:family_shopping_app/features/auth/domain/usecases/reset_password_usecase.dart';
import 'package:family_shopping_app/features/auth/domain/usecases/sign_in_usecase.dart';
import 'package:family_shopping_app/features/auth/domain/usecases/sign_out_usecase.dart';
import 'package:family_shopping_app/features/auth/domain/usecases/sign_up_usecase.dart';
import 'package:family_shopping_app/providers/core_providers.dart';

part 'auth_providers.g.dart';

@Riverpod(keepAlive: true)
AuthRemoteDataSource authRemoteDataSource(Ref ref) {
  return AuthRemoteDataSourceImpl(ref.watch(supabaseClientProvider));
}

@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) {
  return AuthRepositoryImpl(
    ref.watch(authRemoteDataSourceProvider),
    ref.watch(networkInfoProvider),
  );
}

@riverpod
SignUpUseCase signUpUseCase(Ref ref) => SignUpUseCase(ref.watch(authRepositoryProvider));

@riverpod
SignInUseCase signInUseCase(Ref ref) => SignInUseCase(ref.watch(authRepositoryProvider));

@riverpod
SignOutUseCase signOutUseCase(Ref ref) => SignOutUseCase(ref.watch(authRepositoryProvider));

@riverpod
ResetPasswordUseCase resetPasswordUseCase(Ref ref) =>
    ResetPasswordUseCase(ref.watch(authRepositoryProvider));

@riverpod
GetCurrentUserUseCase getCurrentUserUseCase(Ref ref) =>
    GetCurrentUserUseCase(ref.watch(authRepositoryProvider));

/// Single source of truth for "who is logged in right now", driven by
/// Supabase's own auth stream (session restore + auto refresh included —
/// 16_AUTH.md Session Management). The router's guard reads this.
@Riverpod(keepAlive: true)
Stream<UserEntity?> currentUserStream(Ref ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
}
