import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import 'package:family_shopping_app/core/errors/exceptions.dart';
import 'package:family_shopping_app/features/shopping/data/models/shopping_item_model.dart';

abstract class CategoryRemoteDataSource {
  Future<List<CategoryModel>> getCategories();
}

class CategoryRemoteDataSourceImpl implements CategoryRemoteDataSource {
  final sb.SupabaseClient _client;
  CategoryRemoteDataSourceImpl(this._client);

  @override
  Future<List<CategoryModel>> getCategories() async {
    try {
      // RLS already scopes rows to: system defaults (family_id null) +
      // the caller's own family's custom categories.
      final rows =
          await _client.from('categories').select().order('sort_order');
      return (rows as List)
          .map((r) => CategoryModel.fromJson(r as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
