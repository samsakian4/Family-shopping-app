import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:family_shopping_app/core/constants/app_spacing.dart';
import 'package:family_shopping_app/features/shopping/presentation/providers/shopping_list_controller.dart';
import 'package:family_shopping_app/features/shopping/presentation/providers/shopping_list_providers.dart';
import 'package:family_shopping_app/shared/widgets/errors/app_empty_state.dart';

/// Trash screen (FT-025: 30-day retention, restore, permanent delete).
class TrashPage extends ConsumerWidget {
  const TrashPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trashedAsync = ref.watch(trashedListsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('سطل زباله')),
      body: trashedAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (lists) {
          if (lists.isEmpty) {
            return const AppEmptyState(
              icon: Icons.delete_outline,
              message: 'سطل زباله خالی است',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: lists.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final list = lists[index];
              return ListTile(
                title: Text(list.title),
                subtitle: const Text('حداکثر تا ۳۰ روز قابل بازیابی است'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.restore),
                      tooltip: 'بازیابی',
                      onPressed: () => ref
                          .read(shoppingListControllerProvider.notifier)
                          .restore(list.id),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_forever, color: Colors.red),
                      tooltip: 'حذف دائم',
                      onPressed: () => ref
                          .read(shoppingListControllerProvider.notifier)
                          .permanentlyDelete(list.id),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
