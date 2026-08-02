import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:family_shopping_app/core/constants/app_spacing.dart';
import 'package:family_shopping_app/core/router/route_paths.dart';

/// Error navigation page (12_NAVIGATION.md - Error Navigation).
class NotFoundPage extends StatelessWidget {
  const NotFoundPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('صفحه مورد نظر پیدا نشد'),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton(
              onPressed: () => context.go(RoutePaths.home),
              child: const Text('بازگشت به خانه'),
            ),
          ],
        ),
      ),
    );
  }
}
