import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:family_shopping_app/core/constants/app_spacing.dart';
import 'package:family_shopping_app/core/router/route_paths.dart';
import 'package:family_shopping_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:family_shopping_app/features/family/presentation/providers/family_providers.dart';
import 'package:family_shopping_app/features/shopping/domain/entities/shopping_list_entity.dart';
import 'package:family_shopping_app/features/shopping/presentation/providers/shopping_list_providers.dart';

/// Home Dashboard (10_UI_UX.md - Dashboard, FT-060). Shows: greeting,
/// shopping summary, budget, quick add, shared list status.
class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserStreamProvider);
    final listsAsync = ref.watch(myShoppingListsProvider);
    final familyAsync = ref.watch(myFamilyProvider);

    final displayName = userAsync.valueOrNull?.displayName ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(displayName.isEmpty ? 'خانه' : 'سلام $displayName 👋'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'تنظیمات',
            onPressed: () => context.push(RoutePaths.settings),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(myFamilyProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            _ShoppingSummaryCard(listsAsync: listsAsync),
            const SizedBox(height: AppSpacing.md),
            _FamilyStatusCard(familyAsync: familyAsync),
            const SizedBox(height: AppSpacing.lg),
            Text('دسترسی سریع', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: AppSpacing.sm,
              mainAxisSpacing: AppSpacing.sm,
              childAspectRatio: 1.5,
              children: [
                _QuickAction(
                  icon: Icons.add_shopping_cart_outlined,
                  label: 'لیست جدید',
                  onTap: () => context.push(RoutePaths.lists),
                ),
                _QuickAction(
                  icon: Icons.family_restroom_outlined,
                  label: 'خانواده',
                  onTap: () => context.push(RoutePaths.family),
                ),
                _QuickAction(
                  icon: Icons.list_alt_outlined,
                  label: 'همه لیست‌ها',
                  onTap: () => context.push(RoutePaths.lists),
                ),
                _QuickAction(
                  icon: Icons.person_outline,
                  label: 'پروفایل',
                  onTap: () => context.push(RoutePaths.settingsProfile),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ShoppingSummaryCard extends StatelessWidget {
  final AsyncValue<List<ShoppingListEntity>> listsAsync;
  const _ShoppingSummaryCard({required this.listsAsync});

  @override
  Widget build(BuildContext context) {
    return listsAsync.when(
      loading: () => const _SummarySkeleton(),
      error: (e, _) => Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Text(e.toString()),
        ),
      ),
      data: (lists) {
        final active = lists.where((l) => !l.archived).toList();
        final totalEstimate = active.fold<double>(0, (sum, l) => sum + l.estimatedTotal);

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: active.isEmpty
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('هنوز لیستی ندارید'),
                      const SizedBox(height: AppSpacing.sm),
                      OutlinedButton(
                        onPressed: () => context.push(RoutePaths.lists),
                        child: const Text('ساخت اولین لیست'),
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${active.length} لیست فعال',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text('برآورد کل: ${totalEstimate.toStringAsFixed(0)} تومان'),
                        ],
                      ),
                      const Icon(Icons.shopping_basket_outlined, size: 32),
                    ],
                  ),
          ),
        );
      },
    );
  }
}

class _FamilyStatusCard extends StatelessWidget {
  final AsyncValue familyAsync;
  const _FamilyStatusCard({required this.familyAsync});

  @override
  Widget build(BuildContext context) {
    return familyAsync.when(
      loading: () => const _SummarySkeleton(),
      error: (e, _) => const SizedBox.shrink(),
      data: (family) {
        return Card(
          child: ListTile(
            leading: const Icon(Icons.family_restroom_outlined),
            title: Text(family == null ? 'هنوز عضو خانواده‌ای نیستید' : family.name),
            subtitle: Text(family == null ? 'برای اشتراک‌گذاری لیست بپیوندید' : 'وضعیت خانواده'),
            trailing: const Icon(Icons.chevron_left),
            onTap: () => context.push(RoutePaths.family),
          ),
        );
      },
    );
  }
}

class _SummarySkeleton extends StatelessWidget {
  const _SummarySkeleton();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: SizedBox(height: 40, child: Center(child: CircularProgressIndicator())),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAction({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.sm),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28),
            const SizedBox(height: AppSpacing.xs),
            Text(label),
          ],
        ),
      ),
    );
  }
}
