import 'package:flutter/material.dart';

import 'package:family_shopping_app/core/constants/app_spacing.dart';

/// AppErrorView (11_COMPONENT_LIBRARY.md). Every error needs a friendly
/// explanation and a retry action (10_UI_UX.md - Error Experience: never
/// show raw technical messages).
class AppErrorView extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const AppErrorView({
    super.key,
    this.message = 'مشکلی پیش آمد. دوباره تلاش کنید.',
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: AppSpacing.md),
            Text(message, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.md),
              OutlinedButton(onPressed: onRetry, child: const Text('تلاش دوباره')),
            ],
          ],
        ),
      ),
    );
  }
}
