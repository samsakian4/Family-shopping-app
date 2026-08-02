import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:family_shopping_app/core/router/route_paths.dart';

/// Placeholder for the real Dashboard (FT-060). Built out in the
/// Dashboard phase; kept minimal here so routing/auth guard can be tested.
/// Shortcuts to Settings and Family are included so those phases are
/// reachable before the real dashboard/bottom-nav exist.
class HomePagePlaceholder extends StatelessWidget {
  const HomePagePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('داشبورد (به‌زودی)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.family_restroom_outlined),
            tooltip: 'خانواده',
            onPressed: () => context.push(RoutePaths.family),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'تنظیمات',
            onPressed: () => context.push(RoutePaths.settings),
          ),
        ],
      ),
      body: const Center(child: Text('داشبورد (به‌زودی)')),
    );
  }
}
