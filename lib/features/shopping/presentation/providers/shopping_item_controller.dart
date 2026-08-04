import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:family_shopping_app/features/shopping/domain/usecases/add_item_usecase.dart';
import 'package:family_shopping_app/features/shopping/domain/usecases/manage_item_usecases.dart';
import 'package:family_shopping_app/features/shopping/presentation/providers/shopping_item_providers.dart';

part 'shopping_item_controller.g.dart';

@riverpod
class ShoppingItemController extends _$ShoppingItemController {
  @override
  FutureOr<void> build() {}

  Future<bool> addItem({
    required String shoppingListId,
    required String name,
    required double quantity,
    String? unit,
    String? categoryId,
    double? estimatedPrice,
  }) => _run(() => ref.read(addItemUseCaseProvider)(AddItemParams(
        shoppingListId: shoppingListId,
        name: name,
        quantity: quantity,
        unit: unit,
        categoryId: categoryId,
        estimatedPrice: estimatedPrice,
      )));

  Future<bool> updateItem(UpdateItemParams params) =>
      _run(() => ref.read(updateItemUseCaseProvider)(params));

  Future<bool> deleteItem(String itemId) =>
      _run(() => ref.read(deleteItemUseCaseProvider)(DeleteItemParams(itemId: itemId)));

  Future<bool> setPurchased(String itemId, bool purchased, {double? purchasedPrice}) =>
      _run(() => ref.read(setPurchasedUseCaseProvider)(SetPurchasedParams(
            itemId: itemId,
            purchased: purchased,
            purchasedPrice: purchasedPrice,
          )));

  Future<bool> _run(Future<dynamic> Function() action) async {
    state = const AsyncLoading();
    final result = await action();
    return result.fold(
      (failure) {
        state = AsyncError(failure.message, StackTrace.current);
        return false;
      },
      (_) {
        state = const AsyncData(null);
        return true;
      },
    );
  }
}
