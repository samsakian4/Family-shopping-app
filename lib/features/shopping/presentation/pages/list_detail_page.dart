import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:family_shopping_app/core/constants/app_spacing.dart';
import 'package:family_shopping_app/features/shopping/domain/entities/shopping_item_entity.dart';
import 'package:family_shopping_app/features/shopping/presentation/providers/shopping_item_controller.dart';
import 'package:family_shopping_app/features/shopping/presentation/providers/shopping_item_providers.dart';
import 'package:family_shopping_app/features/shopping/presentation/providers/shopping_list_providers.dart';
import 'package:family_shopping_app/shared/widgets/inputs/app_text_field.dart';

/// List Detail — the main shopping workspace (10_UI_UX.md - List Detail
/// Screen, FT-023).
class ListDetailPage extends ConsumerWidget {
  final String listId;
  const ListDetailPage({super.key, required this.listId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listsAsync = ref.watch(myShoppingListsProvider);
    final matchingLists = listsAsync.valueOrNull?.where((l) => l.id == listId);
    final list = (matchingLists != null && matchingLists.isNotEmpty)
        ? matchingLists.first
        : null;
    final itemsAsync = ref.watch(shoppingItemsProvider(listId));

    ref.listen(shoppingItemControllerProvider, (previous, next) {
      if (next.hasError) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(next.error.toString())));
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(list?.title ?? 'لیست خرید'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(28),
          child: Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Text(
              list != null ? 'برآورد کل: ${list.estimatedTotal.toStringAsFixed(0)} تومان' : '',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ),
      ),
      body: itemsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('اولین خرید خود را اضافه کنید'));
          }
          final pending = items.where((i) => !i.purchased).toList();
          final purchased = items.where((i) => i.purchased).toList();

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              ...pending.map((item) => _ItemTile(item: item)),
              if (purchased.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: Text('خریداری‌شده', style: TextStyle(color: Colors.grey)),
                ),
                ...purchased.map((item) => _ItemTile(item: item)),
              ],
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddItemSheet(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddItemSheet(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final quantityController = TextEditingController(text: '1');
    final priceController = TextEditingController();
    String? selectedCategoryId;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          top: AppSpacing.lg,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.lg,
        ),
        child: Consumer(
          builder: (ctx, ref, _) {
            final categoriesAsync = ref.watch(categoriesProvider);
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('افزودن محصول', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: AppSpacing.md),
                AppTextField(controller: nameController, label: 'نام محصول'),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        controller: quantityController,
                        label: 'تعداد',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: AppTextField(
                        controller: priceController,
                        label: 'قیمت تخمینی (اختیاری)',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                categoriesAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (categories) => DropdownButtonFormField<String>(
                    value: selectedCategoryId,
                    decoration: const InputDecoration(labelText: 'دسته‌بندی (اختیاری)'),
                    items: categories
                        .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                        .toList(),
                    onChanged: (v) => selectedCategoryId = v,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                FilledButton(
                  onPressed: () {
                    final quantity = double.tryParse(quantityController.text) ?? 1;
                    final price = double.tryParse(priceController.text);
                    Navigator.pop(ctx);
                    ref.read(shoppingItemControllerProvider.notifier).addItem(
                          shoppingListId: listId,
                          name: nameController.text,
                          quantity: quantity,
                          categoryId: selectedCategoryId,
                          estimatedPrice: price,
                        );
                  },
                  child: const Text('افزودن'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ItemTile extends ConsumerWidget {
  final ShoppingItemEntity item;
  const _ItemTile({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: ListTile(
        leading: Checkbox(
          value: item.purchased,
          onChanged: (v) => ref
              .read(shoppingItemControllerProvider.notifier)
              .setPurchased(item.id, v ?? false),
        ),
        title: Text(
          item.name,
          style: item.purchased
              ? const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.grey)
              : null,
        ),
        subtitle: Text(
          '${item.quantity.toStringAsFixed(item.quantity == item.quantity.roundToDouble() ? 0 : 1)}'
          '${item.unit != null ? ' ${item.unit}' : ''}'
          '${item.estimatedPrice != null ? ' · ${item.estimatedPrice!.toStringAsFixed(0)} تومان' : ''}',
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: () =>
              ref.read(shoppingItemControllerProvider.notifier).deleteItem(item.id),
        ),
      ),
    );
  }
}
