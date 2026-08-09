import 'package:equatable/equatable.dart';

/// A catalog entry, distinct from [ShoppingItemEntity] — this represents
/// the shared reference product (17_PRODUCT_SEARCH_AND_AUTOCOMPLETE.md),
/// not a line on any particular shopping list.
class CatalogProductEntity extends Equatable {
  final String id;
  final String name;
  final String? brandName;
  final String? packageSize;
  final String? categoryId;
  final String? imageUrl;
  final String? defaultUnit;
  final bool isFavorite;

  const CatalogProductEntity({
    required this.id,
    required this.name,
    required this.isFavorite,
    this.brandName,
    this.packageSize,
    this.categoryId,
    this.imageUrl,
    this.defaultUnit,
  });

  /// Display label matching the Product Suggestion Card format
  /// (17_PRODUCT_SEARCH_AND_AUTOCOMPLETE.md): "پنیر کاله 100 گرم".
  String get displayLabel {
    final parts = [name, if (packageSize != null) packageSize!];
    return parts.join(' ');
  }

  @override
  List<Object?> get props =>
      [id, name, brandName, packageSize, categoryId, imageUrl, defaultUnit, isFavorite];
}
