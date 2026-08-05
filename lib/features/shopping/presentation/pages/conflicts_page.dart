import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:family_shopping_app/core/constants/app_spacing.dart';
import 'package:family_shopping_app/core/local/sync_queue_entry.dart';
import 'package:family_shopping_app/features/shopping/presentation/providers/sync_engine_provider.dart';

/// Conflict resolution screen (07_SYNC_ENGINE.md - "If automatic
/// resolution is impossible: Preserve both versions. Prompt the user to
/// choose." / Future Enhancements: "Manual conflict center").
class ConflictsPage extends ConsumerWidget {
  const ConflictsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conflictsAsync = ref.watch(syncConflictsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('تعارض‌های همگام‌سازی')),
      body: conflictsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (conflicts) {
          if (conflicts.isEmpty) {
            return const Center(child: Text('هیچ تعارضی وجود ندارد'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: conflicts.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) => _ConflictCard(entry: conflicts[index]),
          );
        },
      ),
    );
  }
}

class _ConflictCard extends ConsumerWidget {
  final SyncQueueEntry entry;
  const _ConflictCard({required this.entry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payload = jsonDecode(entry.payloadJson) as Map<String, dynamic>;
    final typeLabel = entry.entityType == 'shopping_list' ? 'لیست' : 'محصول';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'تغییر آفلاین شما روی یک $typeLabel با نسخه جدیدتر روی سرور تداخل دارد',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'تغییر شما: ${payload.entries.where((e) => e.key != 'base_updated_at').map((e) => '${e.key}=${e.value}').join('، ')}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () =>
                        ref.read(syncEngineProvider).resolveDiscardLocal(entry),
                    child: const Text('نسخه سرور را نگه دار'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: FilledButton(
                    onPressed: () => ref.read(syncEngineProvider).resolveKeepLocal(entry),
                    child: const Text('تغییر من را اعمال کن'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
