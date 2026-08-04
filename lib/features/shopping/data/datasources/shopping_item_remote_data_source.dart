import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import 'package:family_shopping_app/core/errors/exceptions.dart';
import 'package:family_shopping_app/features/shopping/data/models/shopping_item_model.dart';

abstract class ShoppingItemRemoteDataSource {
  Future<ShoppingItemModel> addItem({
    required String id,
    required String shoppingListId,
    required String name,
    required double quantity,
    String? unit,
    String? categoryId,
    String? brand,
    String? notes,
    double? estimatedPrice,
  });

  Future<void> updateItem({
    required String itemId,
    String? name,
    double? quantity,
    String? unit,
    String? categoryId,
    String? brand,
    String? notes,
    double? estimatedPrice,
  });

  Future<void> deleteItem({required String itemId});

  Future<void> setPurchased({
    required String itemId,
    required bool purchased,
    double? purchasedPrice,
  });

  Stream<List<ShoppingItemModel>> watchItems({required String shoppingListId});
}

class ShoppingItemRemoteDataSourceImpl implements ShoppingItemRemoteDataSource {
  final sb.SupabaseClient _client;
  ShoppingItemRemoteDataSourceImpl(this._client);

  @override
  Future<ShoppingItemModel> addItem({
    required String id,
    required String shoppingListId,
    required String name,
    required double quantity,
    String? unit,
    String? categoryId,
    String? brand,
    String? notes,
    double? estimatedPrice,
  }) async {
    try {
      final row = await _client
          .from('shopping_items')
          .insert({
            'id': id,
            'shopping_list_id': shoppingListId,
            'name': name,
            'quantity': quantity,
            'unit': unit,
            'category_id': categoryId,
            'brand': brand,
            'notes': notes,
            'estimated_price': estimatedPrice,
          })
          .select()
          .single();
      return ShoppingItemModel.fromJson(row);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> updateItem({
    required String itemId,
    String? name,
    double? quantity,
    String? unit,
    String? categoryId,
    String? brand,
    String? notes,
    double? estimatedPrice,
  }) async {
    try {
      final updates = <String, dynamic>{
        if (name != null) 'name': name,
        if (quantity != null) 'quantity': quantity,
        if (unit != null) 'unit': unit,
        if (categoryId != null) 'category_id': categoryId,
        if (brand != null) 'brand': brand,
        if (notes != null) 'notes': notes,
        if (estimatedPrice != null) 'estimated_price': estimatedPrice,
      };
      if (updates.isEmpty) return;
      await _client.from('shopping_items').update(updates).eq('id', itemId);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> deleteItem({required String itemId}) async {
    try {
      await _client.from('shopping_items').delete().eq('id', itemId);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> setPurchased({
    required String itemId,
    required bool purchased,
    double? purchasedPrice,
  }) async {
    try {
      await _client.rpc('mark_item_purchased', params: {
        'p_item_id': itemId,
        'p_purchased': purchased,
        'p_purchased_price': purchasedPrice,
      });
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Stream<List<ShoppingItemModel>> watchItems({required String shoppingListId}) {
    return _client
        .from('shopping_items')
        .stream(primaryKey: ['id'])
        .eq('shopping_list_id', shoppingListId)
        .order('sort_order')
        .map((rows) => rows.map((r) => ShoppingItemModel.fromJson(r)).toList());
  }
}
