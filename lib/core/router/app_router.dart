import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:family_shopping_app/core/router/auth_state_provider.dart';
import 'package:family_shopping_app/core/router/route_paths.dart';
import 'package:family_shopping_app/features/dashboard/presentation/pages/splash_page.dart';
import 'package:family_shopping_app/features/dashboard/presentation/pages/not_found_page.dart';
import 'package:family_shopping_app/features/dashboard/presentation/pages/home_page_placeholder.dart';
import 'package:family_shopping_app/features/auth/presentation/pages/welcome_page.dart';
import 'package:family_shopping_app/features/auth/presentation/pages/login_page.dart';
import 'package:family_shopping_app/features/auth/presentation/pages/register_page.dart';
import 'package:family_shopping_app/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:family_shopping_app/features/settings/presentation/pages/settings_page.dart';
import 'package:family_shopping_app/features/settings/presentation/pages/profile_settings_page.dart';
import 'package:family_shopping_app/features/family/presentation/pages/family_page.dart';
import 'package:family_shopping_app/features/family/presentation/pages/family_members_page.dart';
import 'package:family_shopping_app/features/family/presentation/pages/family_invite_page.dart';

part 'app_router.g.dart';

/// Route structure per 12_NAVIGATION.md.
/// Only Phase-1 placeholder pages are wired here; features/auth, /family,
/// /lists etc. register their real pages as those phases land, without
/// requiring changes to this router's guard logic.
@riverpod
GoRouter appRouter(Ref ref) {
  final isAuthenticated = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: RoutePaths.splash,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final isAuthRoute = state.matchedLocation == RoutePaths.welcome ||
          state.matchedLocation == RoutePaths.login ||
          state.matchedLocation == RoutePaths.register ||
          state.matchedLocation == RoutePaths.forgotPassword;
      final isSplash = state.matchedLocation == RoutePaths.splash;

      if (isSplash) return null; // splash decides its own redirect

      if (!isAuthenticated && !isAuthRoute) {
        // Protected route rule (12_NAVIGATION.md - Authentication Guard)
        return RoutePaths.welcome;
      }
      if (isAuthenticated && isAuthRoute) {
        return RoutePaths.home;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: RoutePaths.splash,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: RoutePaths.welcome,
        builder: (context, state) => const WelcomePage(),
      ),
      GoRoute(
        path: RoutePaths.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: RoutePaths.register,
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: RoutePaths.forgotPassword,
        builder: (context, state) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: RoutePaths.home,
        builder: (context, state) => const HomePagePlaceholder(),
      ),
      GoRoute(
        path: RoutePaths.settings,
        builder: (context, state) => const SettingsPage(),
      ),
      GoRoute(
        path: RoutePaths.settingsProfile,
        builder: (context, state) => const ProfileSettingsPage(),
      ),
      GoRoute(
        path: RoutePaths.family,
        builder: (context, state) => const FamilyPage(),
      ),
      GoRoute(
        path: RoutePaths.familyMembers,
        builder: (context, state) => const FamilyMembersPage(),
      ),
      GoRoute(
        path: RoutePaths.familyInvite,
        builder: (context, state) => const FamilyInvitePage(),
      ),
      // Further routes (/lists, /shopping-mode/:id) are added feature-by-
      // feature in later phases (12_NAVIGATION.md).
    ],
    errorBuilder: (context, state) => const NotFoundPage(),
  );
}
