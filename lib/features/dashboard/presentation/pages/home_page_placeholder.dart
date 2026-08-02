import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:family_shopping_app/core/router/route_paths.dart';

/// Placeholder for the real Dashboard (FT-060). Built out in the
/// Dashboard phase; kept minimal here so routing/auth guard can be tested.
/// A settings shortcut is included so Phase 3 (Profile) is reachable.
class HomePagePlaceholder extends StatelessWidget {
  const HomePagePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('داشبورد (به‌زودی)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push(RoutePaths.settings),
          ),
        ],
      ),
      body: const Center(child: Text('داشبورد (به‌زودی)')),
    );
  }
}
