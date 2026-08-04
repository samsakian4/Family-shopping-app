import 'package:isar/isar.dart';

import 'package:family_shopping_app/features/shopping/data/models/category_local.dart';
import 'package:family_shopping_app/features/shopping/domain/entities/shopping_item_entity.dart';

class CategoryLocalCache {
  final Isar _isar;
  CategoryLocalCache(this._isar);

  Future<List<CategoryEntity>> getCached() async {
    final rows = await _isar.categoryLocals.where().findAll();
    return rows.map((r) => r.toEntity()).toList();
  }

  Future<void> replaceAll(List<CategoryEntity> categories) async {
    await _isar.writeTxn(() async {
      await _isar.categoryLocals.clear();
      await _isar.categoryLocals.putAll(categories.map(CategoryLocal.fromEntity).toList());
    });
  }
}
