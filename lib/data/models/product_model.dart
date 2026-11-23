import 'review_model.dart';

class ProductModel {
  final String id;
  final String nameAr;
  final String nameEn;
  final String descriptionAr;
  final String descriptionEn;
  final double price;
  final double? oldPrice;
  final String categoryId;
  final String businessType;
  final List<String> images;
  final double rating;
  final int reviewCount;
  final bool inStock;
  final int stockCount;
  final String unitAr;
  final String unitEn;
  final Map<String, String> specificationsAr;
  final Map<String, String> specificationsEn;
  final bool isFeatured;
  final List<ReviewModel> reviews;

  const ProductModel({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.descriptionAr,
    required this.descriptionEn,
    required this.price,
    this.oldPrice,
    required this.categoryId,
    required this.businessType,
    required this.images,
    this.rating = 0,
    this.reviewCount = 0,
    this.inStock = true,
    this.stockCount = 100,
    required this.unitAr,
    required this.unitEn,
    this.specificationsAr = const {},
    this.specificationsEn = const {},
    this.isFeatured = false,
    this.reviews = const [],
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id']?.toString() ?? '',
      nameAr: json['name_ar']?.toString() ?? '',
      nameEn:
          json['name_en']?.toString() ?? (json['name_ar']?.toString() ?? ''),
      descriptionAr: json['description_ar']?.toString() ?? '',
      descriptionEn: json['description_en']?.toString() ?? '',
      price: (json['price'] is num)
          ? (json['price'] as num).toDouble()
          : double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      oldPrice: (json['old_price'] != null)
          ? ((json['old_price'] is num)
                ? (json['old_price'] as num).toDouble()
                : double.tryParse(json['old_price'].toString()))
          : null,
      categoryId: json['category_id']?.toString() ?? 'cat_raw_materials',
      businessType: json['business_type']?.toString() ?? 'factory',
      images: (json['images'] is List)
          ? (json['images'] as List).map((e) => e.toString()).toList()
          : (json['images'] != null ? [json['images'].toString()] : []),
      rating: (json['rating'] is num)
          ? (json['rating'] as num).toDouble()
          : 0.0,
      reviewCount: (json['review_count'] is num)
          ? (json['review_count'] as num).toInt()
          : 0,
      inStock: json['in_stock'] ?? true,
      stockCount: (json['stock_count'] is num)
          ? (json['stock_count'] as num).toInt()
          : 100,
      unitAr: json['unit_ar']?.toString() ?? 'قطعة',
      unitEn: json['unit_en']?.toString() ?? 'Piece',
      specificationsAr: (json['specifications_ar'] is Map)
          ? Map<String, String>.from(
              (json['specifications_ar'] as Map).map(
                (k, v) => MapEntry(k.toString(), v.toString()),
              ),
            )
          : {},
      specificationsEn: (json['specifications_en'] is Map)
          ? Map<String, String>.from(
              (json['specifications_en'] as Map).map(
                (k, v) => MapEntry(k.toString(), v.toString()),
              ),
            )
          : {},
      isFeatured: json['is_featured'] ?? false,
      reviews: const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name_ar': nameAr,
      'name_en': nameEn,
      'description_ar': descriptionAr,
      'description_en': descriptionEn,
      'price': price,
      'old_price': oldPrice,
      'category_id': categoryId,
      'business_type': businessType,
      'images': images,
      'rating': rating,
      'review_count': reviewCount,
      'in_stock': inStock,
      'stock_count': stockCount,
      'unit_ar': unitAr,
      'unit_en': unitEn,
      'specifications_ar': specificationsAr,
      'specifications_en': specificationsEn,
      'is_featured': isFeatured,
    };
  }

  String localizedName(bool isArabic) => isArabic ? nameAr : nameEn;
  String localizedDesc(bool isArabic) =>
      isArabic ? descriptionAr : descriptionEn;
  String localizedUnit(bool isArabic) => isArabic ? unitAr : unitEn;
  Map<String, String> localizedSpecs(bool isArabic) =>
      isArabic ? specificationsAr : specificationsEn;

  bool get hasDiscount => oldPrice != null && oldPrice! > price;
  int get discountPercentage =>
      hasDiscount ? (((oldPrice! - price) / oldPrice!) * 100).round() : 0;

  ProductModel copyWith({
    String? id,
    String? nameAr,
    String? nameEn,
    String? descriptionAr,
    String? descriptionEn,
    double? price,
    double? oldPrice,
    bool clearOldPrice = false,
    String? categoryId,
    String? businessType,
    List<String>? images,
    double? rating,
    int? reviewCount,
    bool? inStock,
    int? stockCount,
    String? unitAr,
    String? unitEn,
    Map<String, String>? specificationsAr,
    Map<String, String>? specificationsEn,
    bool? isFeatured,
    List<ReviewModel>? reviews,
  }) {
    return ProductModel(
      id: id ?? this.id,
      nameAr: nameAr ?? this.nameAr,
      nameEn: nameEn ?? this.nameEn,
      descriptionAr: descriptionAr ?? this.descriptionAr,
      descriptionEn: descriptionEn ?? this.descriptionEn,
      price: price ?? this.price,
      oldPrice: clearOldPrice ? null : oldPrice ?? this.oldPrice,
      categoryId: categoryId ?? this.categoryId,
      businessType: businessType ?? this.businessType,
      images: images ?? this.images,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      inStock: inStock ?? this.inStock,
      stockCount: stockCount ?? this.stockCount,
      unitAr: unitAr ?? this.unitAr,
      unitEn: unitEn ?? this.unitEn,
      specificationsAr: specificationsAr ?? this.specificationsAr,
      specificationsEn: specificationsEn ?? this.specificationsEn,
      isFeatured: isFeatured ?? this.isFeatured,
      reviews: reviews ?? this.reviews,
    );
  }
}
