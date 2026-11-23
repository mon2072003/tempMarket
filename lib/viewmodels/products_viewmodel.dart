import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../core/services/supabase_service.dart';
import '../data/models/product_model.dart';
import '../data/models/category_model.dart';
import '../data/models/review_model.dart';

class ProductsViewModel extends ChangeNotifier {
  List<CategoryModel> _categories = [];
  List<ProductModel> _products = []; // ONLY Supabase products

  String? _selectedCategoryId;
  String _searchQuery = '';
  String? _filterBusinessType;
  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<ProductModel> get allProducts => List.unmodifiable(_products);

  ProductsViewModel() {
    loadProductsFromSupabase();
  }

  List<CategoryModel> get categories {
    if (_filterBusinessType == null || _filterBusinessType == 'all') {
      return _categories;
    }
    return _categories
        .where(
          (c) =>
              c.businessType == _filterBusinessType || c.businessType == 'all',
        )
        .toList();
  }

  List<ProductModel> get products {
    return _products.where((p) {
      final matchesBusiness =
          _filterBusinessType == null ||
          _filterBusinessType == 'all' ||
          p.businessType == _filterBusinessType;

      final matchesCategory =
          _selectedCategoryId == null || p.categoryId == _selectedCategoryId;

      final matchesSearch =
          _searchQuery.isEmpty ||
          p.nameAr.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.nameEn.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.descriptionAr.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.descriptionEn.toLowerCase().contains(_searchQuery.toLowerCase());

      return matchesBusiness && matchesCategory && matchesSearch;
    }).toList();
  }

  List<ProductModel> get featuredProducts =>
      products.where((p) => p.isFeatured).toList();

  String? get selectedCategoryId => _selectedCategoryId;
  String get searchQuery => _searchQuery;
  String? get filterBusinessType => _filterBusinessType;

  void selectCategory(String? categoryId) {
    if (_selectedCategoryId == categoryId) {
      _selectedCategoryId = null; // Toggle unselect to show all
    } else {
      _selectedCategoryId = categoryId;
    }
    loadProductsFromSupabase();
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setBusinessType(String? type) {
    _filterBusinessType = type;
    _selectedCategoryId = null;
    loadProductsFromSupabase();
    notifyListeners();
  }

  ProductModel? findProductById(String id) {
    try {
      return _products.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  // ==========================================
  // SUPABASE: FETCH PRODUCTS (ONLY FROM SUPABASE)
  // ==========================================
  Future<void> loadProductsFromSupabase() async {
    final supabase = SupabaseService();
    if (!supabase.isInitialized) {
      _isLoading = false;
      _errorMessage = 'Service is unavailable. Please try again later.';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final rows = await supabase.getProducts(
        categoryId: _selectedCategoryId,
        businessType: _filterBusinessType,
        searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
      );

      _products = rows.map((json) => ProductModel.fromJson(json)).toList();
      try {
        final reviewRows = await supabase.getReviewRatingRows();
        final ratingsByProduct = <String, List<double>>{};
        for (final row in reviewRows) {
          final productId = row['product_id']?.toString();
          final rating = (row['rating'] as num?)?.toDouble();
          if (productId != null &&
              rating != null &&
              rating >= 1 &&
              rating <= 5) {
            ratingsByProduct.putIfAbsent(productId, () => []).add(rating);
          }
        }
        _products = _products.map((product) {
          final ratings = ratingsByProduct[product.id] ?? const <double>[];
          final average = ratings.isEmpty
              ? 0.0
              : ratings.reduce((a, b) => a + b) / ratings.length;
          return product.copyWith(rating: average, reviewCount: ratings.length);
        }).toList();
      } catch (_) {
        // Never fall back to stale rating/review_count columns as if they were live.
        _products = _products
            .map((product) => product.copyWith(rating: 0, reviewCount: 0))
            .toList();
      }
      final categoryRows = await supabase.getCategories(
        businessType: _filterBusinessType,
      );
      _categories = categoryRows
          .map(
            (json) => CategoryModel(
              id: json['id']?.toString() ?? '',
              nameAr: json['name_ar']?.toString() ?? '',
              nameEn: json['name_en']?.toString() ?? '',
              businessType: json['business_type']?.toString() ?? 'all',
              productCount: (json['product_count'] as num?)?.toInt() ?? 0,
              icon: _iconForBusinessType(json['business_type']?.toString()),
            ),
          )
          .where((category) => category.id.isNotEmpty)
          .toList();
    } catch (e) {
      _errorMessage = 'تعذر تحميل المنتجات. حاول مرة أخرى.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  IconData _iconForBusinessType(String? businessType) {
    switch (businessType) {
      case 'factory':
        return Icons.factory_outlined;
      case 'mall':
        return Icons.shopping_bag_outlined;
      case 'pharmacy':
        return Icons.local_pharmacy_outlined;
      case 'restaurant':
        return Icons.restaurant_outlined;
      default:
        return Icons.category_outlined;
    }
  }

  // ==========================================
  // SUPABASE: ADD PRODUCT & UPLOAD IMAGE
  // ==========================================
  Future<bool> addProductToSupabase(
    ProductModel product, {
    Uint8List? imageBytes,
    String? imageFileName,
    List<Uint8List>? imageBytesList,
    List<String>? imageFileNames,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final supabase = SupabaseService();
      final uploadedImageUrls = <String>[];

      // 1. Upload image to Supabase Storage if binary bytes are provided
      if (imageBytes != null &&
          imageFileName != null &&
          supabase.isInitialized) {
        final uploadedImageUrl = await supabase.uploadProductImage(
          imageBytes: imageBytes,
          fileName: imageFileName,
        );
        if (uploadedImageUrl != null) uploadedImageUrls.add(uploadedImageUrl);
      }

      if (imageBytesList != null && imageFileNames != null) {
        for (var i = 0; i < imageBytesList.length; i++) {
          final url = await supabase.uploadProductImage(
            imageBytes: imageBytesList[i],
            fileName: i < imageFileNames.length
                ? imageFileNames[i]
                : 'product_$i.jpg',
          );
          if (url == null)
            throw Exception('Could not upload product image ${i + 1}.');
          uploadedImageUrls.add(url);
        }
      }

      // If we got a public URL from Supabase Storage, use it
      final finalProduct = uploadedImageUrls.isNotEmpty
          ? product.copyWith(images: uploadedImageUrls)
          : product;

      // 2. Insert into Supabase PostgreSQL table
      await supabase.insertProduct(finalProduct);

      // 3. Reload all products directly from Supabase
      await loadProductsFromSupabase();
      return true;
    } catch (e) {
      _errorMessage = 'تعذر إضافة المنتج. حاول مرة أخرى.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ==========================================
  // SUPABASE: UPDATE PRODUCT
  // ==========================================
  Future<bool> updateProductInSupabase(
    ProductModel product, {
    List<({Uint8List bytes, String name})> newImages = const [],
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final supabase = SupabaseService();
      final uploadedImageUrls = <String>[];

      for (var index = 0; index < newImages.length; index++) {
        final image = newImages[index];
        final url = await supabase.uploadProductImage(
          imageBytes: image.bytes,
          fileName: image.name,
        );
        if (url == null) {
          throw Exception('Could not upload product image ${index + 1}.');
        }
        uploadedImageUrls.add(url);
      }

      final finalProduct = uploadedImageUrls.isEmpty
          ? product
          : product.copyWith(images: [...product.images, ...uploadedImageUrls]);
      final success = await supabase.updateProduct(finalProduct);
      if (success) {
        await loadProductsFromSupabase();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = 'Product update failed: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==========================================
  // SUPABASE: DELETE PRODUCT
  // ==========================================
  Future<bool> deleteProductFromSupabase(String productId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final supabase = SupabaseService();
      final success = await supabase.deleteProduct(productId);
      if (success) {
        _products.removeWhere((p) => p.id == productId);
        notifyListeners();
        return true;
      }
      _errorMessage =
          'Could not delete product. Check your connection and permissions.';
      return false;
    } catch (error) {
      _errorMessage = 'Could not delete product: $error';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> refreshProductsFromSupabase() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final supabase = SupabaseService();
      if (!supabase.isInitialized) {
        throw Exception('Service is unavailable');
      }
      await loadProductsFromSupabase();
      return true;
    } catch (e) {
      _errorMessage = 'تعذر تحديث المنتجات. حاول مرة أخرى.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Admin capability: Add a new custom category
  Future<bool> addAdminCategory(CategoryModel newCategory) async {
    try {
      _errorMessage = null;
      final success = await SupabaseService().insertCategory(newCategory);
      if (success) await loadProductsFromSupabase();
      return success;
    } catch (error) {
      _errorMessage = error.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateAdminCategory(CategoryModel category) async {
    try {
      final success = await SupabaseService().updateCategory(category);
      if (success) await loadProductsFromSupabase();
      return success;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteAdminCategory(String categoryId) async {
    try {
      final success = await SupabaseService().deleteCategory(categoryId);
      if (success) await loadProductsFromSupabase();
      return success;
    } catch (_) {
      return false;
    }
  }

  // Add review and recalculate rating
  Future<bool> addReviewToProduct(String productId, ReviewModel review) async {
    final supabase = SupabaseService();
    if (!supabase.isInitialized) return false;
    final inserted = await supabase.insertReview(productId, review);
    if (!inserted) return false;
    await loadReviewsForProduct(productId);
    return true;
  }

  // Load reviews from Supabase for a specific product
  Future<void> loadReviewsForProduct(String productId) async {
    final supabase = SupabaseService();
    if (!supabase.isInitialized) return;

    try {
      final reviewsData = await supabase.getReviews(productId);
      final reviews = reviewsData
          .where((row) {
            final rating = (row['rating'] as num?)?.toDouble();
            return rating != null && rating >= 1 && rating <= 5;
          })
          .map((row) => ReviewModel.fromJson(row))
          .toList();
      final index = _products.indexWhere((p) => p.id == productId);
      if (index != -1) {
        final product = _products[index];
        final totalRating = reviews.fold(0.0, (sum, r) => sum + r.rating);
        final newRating = reviews.isEmpty ? 0.0 : totalRating / reviews.length;

        _products[index] = product.copyWith(
          reviews: reviews,
          rating: newRating,
          reviewCount: reviews.length,
        );
        notifyListeners();
      }
    } catch (_) {}
  }
}
