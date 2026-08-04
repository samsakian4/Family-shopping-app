import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:family_shopping_app/core/router/auth_state_provider.dart';
import 'package:family_shopping_app/core/router/route_paths.dart';
import 'package:family_shopping_app/features/shopping/presentation/providers/sync_engine_provider.dart';

/// Splash screen: application initialization (12_NAVIGATION.md).
/// Tasks (as later phases land): load configuration, check auth,
/// initialize local database, start sync service, load theme/language.
/// Duration must stay as short as possible.
class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  Future<void> _init() async {
    // Start background sync (07_SYNC_ENGINE.md - triggers: "App launch").
    ref.read(syncEngineProvider).start();

    // TODO(auth-feature): await real session restore here.
    final isAuthenticated = ref.read(authStateProvider);
    if (!mounted) return;
    context.go(isAuthenticated ? RoutePaths.home : RoutePaths.welcome);
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
