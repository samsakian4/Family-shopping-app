import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:family_shopping_app/features/auth/presentation/providers/auth_providers.dart';

part 'auth_state_provider.g.dart';

/// Router-guard-facing boolean, derived from the real Supabase auth stream
/// (features/auth/presentation/providers/auth_providers.dart).
/// While the stream is loading, the user is treated as unauthenticated —
/// the splash screen is what covers that brief window
/// (12_NAVIGATION.md - Splash Screen).
@riverpod
class AuthState extends _$AuthState {
  @override
  bool build() {
    final userAsync = ref.watch(currentUserStreamProvider);
    return userAsync.maybeWhen(
      data: (user) => user != null,
      orElse: () => false,
    );
  }
}
