import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:family_shopping_app/core/constants/app_spacing.dart';
import 'package:family_shopping_app/core/router/route_paths.dart';
import 'package:family_shopping_app/core/local/sync_queue_service.dart';
import 'package:family_shopping_app/providers/core_providers.dart';
import 'package:family_shopping_app/features/shopping/presentation/providers/sync_engine_provider.dart';
import 'package:family_shopping_app/features/family/presentation/providers/family_providers.dart';
import 'package:family_shopping_app/features/shopping/domain/entities/shopping_list_entity.dart';
import 'package:family_shopping_app/features/shopping/presentation/providers/shopping_list_controller.dart';
import 'package:family_shopping_app/features/shopping/presentation/providers/shopping_list_providers.dart';
import 'package:family_shopping_app/shared/widgets/inputs/app_text_field.dart';

/// Shopping Lists screen (10_UI_UX.md - Shopping Lists Screen, FT-020/021).
class ShoppingListsPage extends ConsumerStatefulWidget {
  const ShoppingListsPage({super.key});

  @override
  ConsumerState<ShoppingListsPage> createState() => _ShoppingListsPageState();
}

class _ShoppingListsPageState extends ConsumerState<ShoppingListsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(length: 3, vsync: this);

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final listsAsync = ref.watch(myShoppingListsProvider);
    final controllerState = ref.watch(shoppingListControllerProvider);

    ref.listen(shoppingListControllerProvider, (previous, next) {
      if (next.hasError) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(next.error.toString())));
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('لیست‌های خرید'),
        actions: [
          StreamBuilder<int>(
            stream: ref.watch(syncQueueServiceProvider).watchPendingCount(),
            builder: (context, snapshot) {
              final count = snapshot.data ?? 0;
              if (count == 0) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                child: Chip(
                  avatar: const Icon(Icons.cloud_off, size: 16),
                  label: Text('$count در انتظار ارسال'),
                  visualDensity: VisualDensity.compact,
                ),
              );
            },
          ),
          Consumer(
            builder: (context, ref, _) {
              final conflictsAsync = ref.watch(syncConflictsProvider);
              final count = conflictsAsync.valueOrNull?.length ?? 0;
              if (count == 0) return const SizedBox.shrink();
              return IconButton(
                icon: Badge(
                  label: Text('$count'),
                  child: const Icon(Icons.warning_amber_outlined, color: Colors.orange),
                ),
                tooltip: 'تعارض‌های همگام‌سازی',
                onPressed: () => context.push(RoutePaths.listsConflicts),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'سطل زباله',
            onPressed: () => context.push(RoutePaths.listsTrash),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'شخصی'), Tab(text: 'مشترک'), Tab(text: 'آرشیو')],
        ),
      ),
      body: listsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (lists) {
          final personal = lists
              .where((l) => l.type == ShoppingListType.personal && !l.archived)
              .toList();
          final shared = lists
              .where((l) => l.type == ShoppingListType.shared && !l.archived)
              .toList();
          final archived = lists.where((l) => l.archived).toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _ListView(lists: personal, emptyText: 'هنوز لیستی ایجاد نکرده‌اید'),
              _ListView(lists: shared, emptyText: 'هنوز لیست مشترکی وجود ندارد'),
              _ListView(lists: archived, emptyText: 'موردی در آرشیو نیست'),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: controllerState.isLoading ? null : () => _showCreateDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showCreateDialog(BuildContext context) {
    final titleController = TextEditingController();
    final myFamily = ref.read(myFamilyProvider).valueOrNull;
    var selectedType = ShoppingListType.personal;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('لیست جدید'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(controller: titleController, label: 'نام لیست'),
              const SizedBox(height: AppSpacing.md),
              SegmentedButton<ShoppingListType>(
                segments: const [
                  ButtonSegment(value: ShoppingListType.personal, label: Text('شخصی')),
                  ButtonSegment(value: ShoppingListType.shared, label: Text('مشترک')),
                ],
                selected: {selectedType},
                onSelectionChanged: myFamily == null
                    ? null
                    : (s) => setState(() => selectedType = s.first),
              ),
              if (myFamily == null)
                const Padding(
                  padding: EdgeInsets.only(top: AppSpacing.xs),
                  child: Text(
                    'برای لیست مشترک ابتدا باید عضو یک خانواده شوید',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('انصراف')),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                ref.read(shoppingListControllerProvider.notifier).createList(
                      title: titleController.text,
                      type: selectedType,
                      familyId: myFamily?.id,
                    );
              },
              child: const Text('ساخت'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ListView extends ConsumerWidget {
  final List<ShoppingListEntity> lists;
  final String emptyText;

  const _ListView({required this.lists, required this.emptyText});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (lists.isEmpty) {
      return Center(child: Text(emptyText));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: lists.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final list = lists[index];
        return Card(
          child: ListTile(
            title: Text(list.title),
            subtitle: Text(
              list.type == ShoppingListType.shared ? 'لیست مشترک' : 'لیست شخصی',
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (action) => _handleAction(context, ref, list, action),
              itemBuilder: (ctx) => [
                const PopupMenuItem(value: 'rename', child: Text('تغییر نام')),
                PopupMenuItem(
                  value: 'archive',
                  child: Text(list.archived ? 'خارج از آرشیو' : 'آرشیو'),
                ),
                const PopupMenuItem(value: 'delete', child: Text('حذف')),
              ],
            ),
            onTap: () => context.push(
              RoutePaths.listDetail.replaceFirst(':id', list.id),
            ),
          ),
        );
      },
    );
  }

  void _handleAction(
    BuildContext context,
    WidgetRef ref,
    ShoppingListEntity list,
    String action,
  ) {
    final controller = ref.read(shoppingListControllerProvider.notifier);
    switch (action) {
      case 'rename':
        final textController = TextEditingController(text: list.title);
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('تغییر نام لیست'),
            content: AppTextField(controller: textController, label: 'نام جدید'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('انصراف')),
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  controller.rename(list.id, textController.text);
                },
                child: const Text('ذخیره'),
              ),
            ],
          ),
        );
        break;
      case 'archive':
        controller.setArchived(list.id, !list.archived);
        break;
      case 'delete':
        controller.softDelete(list.id);
        break;
    }
  }
}
