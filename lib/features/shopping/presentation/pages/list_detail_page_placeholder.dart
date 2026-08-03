import 'package:flutter/material.dart';

/// Placeholder for List Detail (12_NAVIGATION.md - /lists/detail/:id).
/// Product items, add/edit/complete flows land in the Shopping Items
/// phase (Milestone 1, Phase 6).
class ListDetailPagePlaceholder extends StatelessWidget {
  final String listId;
  const ListDetailPagePlaceholder({super.key, required this.listId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('جزئیات لیست')),
      body: Center(child: Text('آیتم‌های خرید (به‌زودی) — لیست $listId')),
    );
  }
}
