import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import 'package:family_shopping_app/core/errors/exceptions.dart';
import 'package:family_shopping_app/features/catalog/data/models/catalog_product_model.dart';

abstract class CatalogRemoteDataSource {
  Future<List<CatalogProductModel>> searchProducts(String query);
  Future<void> toggleFavorite({required String productId, required bool favorite});
  Future<void> recordPurchase({required String productId, required double quantity});
}

class CatalogRemoteDataSourceImpl implements CatalogRemoteDataSource {
  final sb.SupabaseClient _client;
  CatalogRemoteDataSourceImpl(this._client);

  @override
  Future<List<CatalogProductModel>> searchProducts(String query) async {
    try {
      final rows = await _client.rpc('search_products', params: {
        'p_query': query,
        'p_limit': 10,
      });
      return (rows as List)
          .map((r) => CatalogProductModel.fromJson(r as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> toggleFavorite({required String productId, required bool favorite}) async {
    try {
      await _client.rpc('toggle_favorite_product', params: {
        'p_product_id': productId,
        'p_favorite': favorite,
      });
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> recordPurchase({required String productId, required double quantity}) async {
    try {
      await _client.rpc('record_product_purchase', params: {
        'p_product_id': productId,
        'p_quantity': quantity,
      });
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
