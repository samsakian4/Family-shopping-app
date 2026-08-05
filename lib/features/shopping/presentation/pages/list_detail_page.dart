import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:family_shopping_app/core/constants/app_constants.dart';
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _AddItemSheet(listId: listId),
    );
  }
}

/// Extracted as its own stateful widget so the search debounce
/// (17_PRODUCT_SEARCH_AND_AUTOCOMPLETE.md - "Recommended: 300ms debounce")
/// has somewhere to live without leaking Timers into the page state.
class _AddItemSheet extends ConsumerStatefulWidget {
  final String listId;
  const _AddItemSheet({required this.listId});

  @override
  ConsumerState<_AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends ConsumerState<_AddItemSheet> {
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _priceController = TextEditingController();
  String? _selectedCategoryId;

  Timer? _debounce;
  List<String> _suggestions = [];

  @override
  void dispose() {
    _debounce?.cancel();
    _nameController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _onNameChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(AppConstants.searchDebounce, () async {
      final results = await ref.read(searchProductNamesUseCaseProvider)(query);
      if (mounted) setState(() => _suggestions = results);
    });
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('افزودن محصول', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: _nameController,
            label: 'نام محصول',
            onChanged: _onNameChanged,
          ),
          if (_suggestions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Wrap(
                spacing: AppSpacing.xs,
                children: _suggestions
                    .map((s) => ActionChip(
                          label: Text(s),
                          onPressed: () {
                            _nameController.text = s;
                            setState(() => _suggestions = []);
                          },
                        ))
                    .toList(),
              ),
            ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  controller: _quantityController,
                  label: 'تعداد',
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppTextField(
                  controller: _priceController,
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
              value: _selectedCategoryId,
              decoration: const InputDecoration(labelText: 'دسته‌بندی (اختیاری)'),
              items: categories
                  .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedCategoryId = v),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton(
            onPressed: () {
              final quantity = double.tryParse(_quantityController.text) ?? 1;
              final price = double.tryParse(_priceController.text);
              Navigator.pop(context);
              ref.read(shoppingItemControllerProvider.notifier).addItem(
                    shoppingListId: widget.listId,
                    name: _nameController.text,
                    quantity: quantity,
                    categoryId: _selectedCategoryId,
                    estimatedPrice: price,
                  );
            },
            child: const Text('افزودن'),
          ),
        ],
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
