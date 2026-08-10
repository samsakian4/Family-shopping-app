import 'package:family_shopping_app/features/catalog/domain/entities/catalog_product_entity.dart';

class CatalogProductModel extends CatalogProductEntity {
  const CatalogProductModel({
    required super.id,
    required super.name,
    required super.isFavorite,
    super.brandName,
    super.packageSize,
    super.categoryId,
    super.imageUrl,
    super.defaultUnit,
  });

  /// Built from a row returned by the `search_products` RPC
  /// (011_smart_search.sql).
  factory CatalogProductModel.fromJson(Map<String, dynamic> json) {
    return CatalogProductModel(
      id: json['id'] as String,
      name: json['name'] as String,
      brandName: json['brand_name'] as String?,
      packageSize: json['package_size'] as String?,
      categoryId: json['category_id'] as String?,
      imageUrl: json['image_url'] as String?,
      defaultUnit: json['default_unit'] as String?,
      isFavorite: json['is_favorite'] as bool,
    );
  }
}
