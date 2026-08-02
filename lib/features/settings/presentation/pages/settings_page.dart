import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:family_shopping_app/core/router/route_paths.dart';
import 'package:family_shopping_app/features/auth/presentation/providers/auth_controller.dart';

/// Settings screen (10_UI_UX.md - Settings UX). Appearance / Notifications
/// / Developer sections are wired as their phases land.
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('تنظیمات')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('پروفایل من'),
            trailing: const Icon(Icons.chevron_left),
            onTap: () => context.push(RoutePaths.settingsProfile),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('خروج از حساب کاربری', style: TextStyle(color: Colors.red)),
            onTap: () async {
              await ref.read(authControllerProvider.notifier).signOut();
              // Router redirect handles navigation back to /welcome once
              // the auth stream flips to unauthenticated.
            },
          ),
        ],
      ),
    );
  }
}
