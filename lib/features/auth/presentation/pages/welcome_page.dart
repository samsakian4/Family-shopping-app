import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:family_shopping_app/core/constants/app_constants.dart';
import 'package:family_shopping_app/core/constants/app_spacing.dart';
import 'package:family_shopping_app/core/router/route_paths.dart';
import 'package:family_shopping_app/shared/widgets/buttons/app_primary_button.dart';

/// Welcome screen (12_NAVIGATION.md - Welcome Screen): first experience,
/// offers Login / Register only.
class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.shopping_basket_rounded, size: 72),
              const SizedBox(height: AppSpacing.md),
              Text(
                AppConstants.appName,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xs),
              const Text(
                'خرید خانواده، ساده و هوشمند',
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              AppPrimaryButton(
                label: 'ورود',
                onPressed: () => context.push(RoutePaths.login),
              ),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton(
                onPressed: () => context.push(RoutePaths.register),
                child: const SizedBox(
                  width: double.infinity,
                  child: Text('ساخت حساب کاربری', textAlign: TextAlign.center),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}
