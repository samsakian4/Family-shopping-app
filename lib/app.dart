import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:family_shopping_app/core/constants/app_constants.dart';
import 'package:family_shopping_app/core/router/app_router.dart';
import 'package:family_shopping_app/core/theme/app_theme.dart';

class FamilyShoppingApp extends ConsumerWidget {
  const FamilyShoppingApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system, // FT-120 — user-overridable in Settings
      routerConfig: router,
      locale: const Locale('fa'), // Persian primary (09_DESIGN_SYSTEM.md)
      supportedLocales: const [Locale('fa'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        // Force RTL for Persian regardless of platform locale detection,
        // until the localization feature (FT-121) is wired.
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
