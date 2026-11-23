import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../config/brand_config.dart';
import '../../data/models/product_model.dart';
import '../../data/models/category_model.dart';
import '../../data/models/order_model.dart';
import '../../data/models/review_model.dart';
import '../../data/models/notification_model.dart';
import '../../data/models/driver_application_model.dart';
import '../../data/models/promo_code_model.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;
  String? lastPromoCodeError;

  SupabaseClient get client => Supabase.instance.client;

  /// Initialize Supabase if credentials are provided
  Future<void> initialize() async {
    if (!SupabaseConfig.isConfigured) return;

    try {
      try {
        final _ = Supabase.instance.client;
        _isInitialized = true;
        return;
      } catch (_) {}

      await Supabase.initialize(
        url: SupabaseConfig.supabaseUrl,
        publishableKey: SupabaseConfig.supabaseAnonKey,
      );
      _isInitialized = true;
    } catch (_) {
      _isInitialized = false;
    }
  }

  // ==========================================
  // STORAGE SERVICE (Upload images & files)
  // ==========================================

  /// Upload product image bytes to Supabase Storage and return public URL
  Future<String?> uploadProductImage({
    required Uint8List imageBytes,
    required String fileName,
  }) async {
    if (!_isInitialized) return null;

    try {
      final path = 'products/${DateTime.now().millisecondsSinceEpoch}_$fileName';
      await client.storage.from(SupabaseConfig.productImagesBucket).uploadBinary(
            path,
            imageBytes,
            fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
          );

      final publicUrl = client.storage
          .from(SupabaseConfig.productImagesBucket)
          .getPublicUrl(path);

      return publicUrl;
    } catch (e) {
      return null;
    }
  }

  /// Upload user profile avatar bytes and return public URL
  Future<String?> uploadUserAvatar({
    required Uint8List imageBytes,
    required String fileName,
  }) async {
    if (!_isInitialized) return null;

    try {
      final path = 'avatars/${DateTime.now().millisecondsSinceEpoch}_$fileName';
      await client.storage.from(SupabaseConfig.avatarsBucket).uploadBinary(
            path,
            imageBytes,
            fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
          );

      return client.storage.from(SupabaseConfig.avatarsBucket).getPublicUrl(path);
    } catch (e) {
      return null;
    }
  }

  // ==========================================
  // DATABASE SERVICE (PostgreSQL CRUD)
  // ==========================================

  Future<BrandConfig?> getBrandSettings() async {
    if (!_isInitialized) return null;
    final row = await client
        .from('app_settings')
        .select('settings')
        .eq('id', 'brand')
        .maybeSingle();
    final settings = row?['settings'];
    if (settings is! Map) return null;
    return BrandConfig.fromJson(Map<String, dynamic>.from(settings));
  }

  Future<void> saveBrandSettings(BrandConfig brand) async {
    if (!_isInitialized) throw Exception('Supabase is not initialized.');
    await client.from('app_settings').upsert({
      'id': 'brand',
      'settings': brand.toJson(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }, onConflict: 'id');
  }

  /// Fetch products from Supabase database
  Future<List<Map<String, dynamic>>> getProducts({
    String? categoryId,
    String? businessType,
    String? searchQuery,
  }) async {
    if (!_isInitialized) {
      throw Exception('Supabase is not initialized');
    }

    var query = client.from('products').select();

    if (businessType != null && businessType != 'all') {
      query = query.eq('business_type', businessType);
    }
    if (categoryId != null) {
      query = query.eq('category_id', categoryId);
    }
    if (searchQuery != null && searchQuery.isNotEmpty) {
      query = query.ilike('name_ar', '%$searchQuery%');
    }

    final response = await query.order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  /// Create a new product in Supabase database
  Future<void> insertProduct(ProductModel product) async {
    if (!_isInitialized) {
      throw Exception('Supabase is not initialized');
    }

    await client.from('products').insert({
      'id': product.id,
      'name_ar': product.nameAr,
      'name_en': product.nameEn,
      'description_ar': product.descriptionAr,
      'description_en': product.descriptionEn,
      'price': product.price,
      'old_price': product.oldPrice,
      if (product.categoryId.isNotEmpty) 'category_id': product.categoryId,
      'business_type': product.businessType,
      'images': product.images,
      'rating': product.rating,
      'review_count': product.reviewCount,
      'in_stock': product.inStock,
      'stock_count': product.stockCount,
      'unit_ar': product.unitAr,
      'unit_en': product.unitEn,
      'specifications_ar': product.specificationsAr,
      'specifications_en': product.specificationsEn,
      'is_featured': product.isFeatured,
    });
  }

  /// Update an existing product in Supabase database
  Future<bool> updateProduct(ProductModel product) async {
    if (!_isInitialized) throw Exception('Supabase is not initialized');
    try {
      await client.from('products').update({
        'name_ar': product.nameAr,
        'name_en': product.nameEn,
        'description_ar': product.descriptionAr,
        'description_en': product.descriptionEn,
        'price': product.price,
        'old_price': product.oldPrice,
        if (product.categoryId.isNotEmpty) 'category_id': product.categoryId,
        'business_type': product.businessType,
        'images': product.images,
        'in_stock': product.inStock,
        'stock_count': product.stockCount,
        'unit_ar': product.unitAr,
        'unit_en': product.unitEn,
        'specifications_ar': product.specificationsAr,
        'specifications_en': product.specificationsEn,
        'is_featured': product.isFeatured,
      }).eq('id', product.id);
      return true;
    } catch (e) {
      try {
        await client.from('products').update({
          'name_ar': product.nameAr,
          'name_en': product.nameEn,
          'description_ar': product.descriptionAr,
          'description_en': product.descriptionEn,
          'price': product.price,
          'images': product.images,
          'in_stock': product.inStock,
          'stock_count': product.stockCount,
        }).eq('id', product.id);
        return true;
      } catch (fallbackError) {
        throw Exception('Product update failed: $fallbackError');
      }
    }
  }

  /// Delete a product permanently from Supabase database
  Future<bool> deleteProduct(String productId) async {
    if (!_isInitialized) return false;
    try {
      await client.from('products').delete().eq('id', productId);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Fetch categories from Supabase
  Future<List<Map<String, dynamic>>> getCategories({String? businessType}) async {
    if (!_isInitialized) throw Exception('Supabase is not initialized');

    try {
      var query = client.from('categories').select();
      if (businessType != null && businessType != 'all') {
        query = query.eq('business_type', businessType);
      }
      final response = await query.order('name_ar');
      return List<Map<String, dynamic>>.from(response);
    } catch (_) {
      rethrow;
    }
  }

  /// Insert a new category in Supabase
  Future<bool> insertCategory(CategoryModel category) async {
    if (!_isInitialized) throw StateError('The data service is not initialized.');

    try {
      await client.from('categories').insert({
        'id': category.id,
        'name_ar': category.nameAr,
        'name_en': category.nameEn,
        'business_type': category.businessType,
        'product_count': category.productCount,
      });
      return true;
    } catch (error) {
      throw Exception('Category insert failed: $error');
    }
  }

  /// Update an existing category in Supabase
  Future<bool> updateCategory(CategoryModel category) async {
    if (!_isInitialized) return false;
    try {
      await client.from('categories').update({
        'name_ar': category.nameAr,
        'name_en': category.nameEn,
        'business_type': category.businessType,
        'product_count': category.productCount,
      }).eq('id', category.id);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Delete a category from Supabase
  Future<bool> deleteCategory(String categoryId) async {
    if (!_isInitialized) return false;
    try {
      await client.from('categories').delete().eq('id', categoryId);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<List<PromoCodeModel>> getPromoCodes() async {
    if (!_isInitialized) throw Exception('The data service is not initialized.');
    final rows = await client.from('promo_codes').select().order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows)
        .map(PromoCodeModel.fromJson)
        .toList();
  }

  Future<PromoCodeModel?> validatePromoCode(String code) async {
    if (!_isInitialized) return null;
    final row = await client
        .from('promo_codes')
        .select()
        .eq('code', code.trim().toUpperCase())
        .eq('is_active', true)
        .maybeSingle();
    if (row == null) return null;
    final promo = PromoCodeModel.fromJson(row);
    if (promo.expiresAt != null && promo.expiresAt!.isBefore(DateTime.now().toUtc())) {
      return null;
    }
    return promo;
  }

  Future<bool> savePromoCode(PromoCodeModel promo, {required bool isNew}) async {
    lastPromoCodeError = null;
    if (!_isInitialized) {
      lastPromoCodeError = 'The data service is not initialized.';
      return false;
    }
    try {
      if (isNew) {
        await client.from('promo_codes').insert(promo.toJson());
      } else {
        await client.from('promo_codes').update(promo.toJson()).eq('code', promo.code);
      }
      return true;
    } catch (error) {
      lastPromoCodeError = error.toString();
      return false;
    }
  }

  Future<bool> deletePromoCode(String code) async {
    lastPromoCodeError = null;
    if (!_isInitialized) {
      lastPromoCodeError = 'The data service is not initialized.';
      return false;
    }
    try {
      await client.from('promo_codes').delete().eq('code', code);
      return true;
    } catch (error) {
      lastPromoCodeError = error.toString();
      return false;
    }
  }

  /// Insert an order into Supabase
  Future<bool> insertOrder(OrderModel order, String userId) async {
    if (!_isInitialized) return false;

    try {
      final orderData = {
        'id': order.id,
        'user_id': userId,
        'subtotal': order.subtotal,
        'tax': order.tax,
        'delivery_fee': order.deliveryFee,
        'discount': order.discount,
        'total': order.total,
        'status': order.status.name,
        'delivery_address': order.deliveryAddress,
        'dest_lat': order.destLat,
        'dest_lng': order.destLng,
        'driver_progress': order.driverProgress,
        'courier_name': order.courier.name,
        'courier_phone': order.courier.phone,
        'courier_vehicle': order.courier.vehicle,
        'courier_avatar': order.courier.avatarUrl,
        'payment_method': order.paymentMethod,
        'estimated_arrival_minutes': order.estimatedArrivalMinutes,
      };

      final itemsToInsert = order.items.map((item) => {
            'product_id': item.product.id,
            'quantity': item.quantity,
            'unit_price': item.product.price,
            'total_price': item.totalPrice,
          }).toList();

      await client.rpc(
        'place_order_with_stock',
        params: {
          'p_order': orderData,
          'p_items': itemsToInsert,
        },
      );
      return true;
    } catch (e) {
      throw Exception('Order insert failed: $e');
    }
  }

  /// Update an order status and courier tracking in Supabase
  Future<bool> updateOrderStatus(
    String orderId,
    String status, {
    double? driverProgress,
    int? estimatedArrivalMinutes,
    String? courierName,
    String? courierPhone,
    String? courierVehicle,
  }) async {
    if (!_isInitialized) return false;
    try {
      await client.from('orders').update({
        'status': status,
        if (driverProgress != null) 'driver_progress': driverProgress,
        if (estimatedArrivalMinutes != null) 'estimated_arrival_minutes': estimatedArrivalMinutes,
        if (courierName != null) 'courier_name': courierName,
        if (courierPhone != null) 'courier_phone': courierPhone,
        if (courierVehicle != null) 'courier_vehicle': courierVehicle,
      }).eq('id', orderId);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Fetch all orders with their items from Supabase
  Future<List<Map<String, dynamic>>> getOrdersWithItems() async {
    if (!_isInitialized) return [];
    try {
      final res = await client
          .from('orders')
          .select('*, order_items(*)')
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(res);
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getCurrentUserOrders() async {
    if (!_isInitialized) throw Exception('Supabase is not initialized');
    final userId = client.auth.currentUser?.id;
    if (userId == null) return [];
    final res = await client
        .from('orders')
        .select('*, order_items(*)')
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(res);
  }

  Future<List<Map<String, dynamic>>> getCurrentUserCart() async {
    if (!_isInitialized) throw Exception('Supabase is not initialized');
    final userId = client.auth.currentUser?.id;
    if (userId == null) return [];
    final response = await client
        .from('cart_items')
        .select('product_id, quantity, selected_note, products(*)')
        .eq('user_id', userId)
        .order('created_at');
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> upsertCartItem({
    required String productId,
    required int quantity,
    String? selectedNote,
  }) async {
    if (!_isInitialized) return;
    final userId = client.auth.currentUser?.id;
    if (userId == null) return;
    await client.from('cart_items').upsert({
      'user_id': userId,
      'product_id': productId,
      'quantity': quantity,
      'selected_note': selectedNote,
    }, onConflict: 'user_id,product_id');
  }

  Future<void> deleteCartItem(String productId) async {
    if (!_isInitialized) return;
    final userId = client.auth.currentUser?.id;
    if (userId == null) return;
    await client
        .from('cart_items')
        .delete()
        .eq('user_id', userId)
        .eq('product_id', productId);
  }

  Future<void> clearCurrentUserCart() async {
    if (!_isInitialized) return;
    final userId = client.auth.currentUser?.id;
    if (userId == null) return;
    await client.from('cart_items').delete().eq('user_id', userId);
  }

  /// Fetch reviews for a specific product from Supabase
  Future<List<Map<String, dynamic>>> getReviews(String productId) async {
    if (!_isInitialized) return [];
    final rows = <Map<String, dynamic>>[];
    const pageSize = 1000;
    for (var offset = 0;; offset += pageSize) {
      final response = await client
          .from('reviews')
          .select()
          .eq('product_id', productId)
          .order('created_at', ascending: false)
          .range(offset, offset + pageSize - 1);
      final page = List<Map<String, dynamic>>.from(response);
      rows.addAll(page);
      if (page.length < pageSize) break;
    }
    return rows;
  }

  Future<List<Map<String, dynamic>>> getReviewRatingRows() async {
    if (!_isInitialized) throw Exception('Database connection is not initialized.');
    return _getAllReviewRows('id, product_id, rating');
  }

  /// Fetch every review row visible to the current admin session for analytics.
  Future<List<Map<String, dynamic>>> getAllReviews() async {
    if (!_isInitialized) throw Exception('Database connection is not initialized.');
    return _getAllReviewRows(
      'id, product_id, rating, created_at, is_verified_purchase',
    );
  }

  Future<List<Map<String, dynamic>>> _getAllReviewRows(String columns) async {
    final rows = <Map<String, dynamic>>[];
    const pageSize = 1000;
    for (var offset = 0;; offset += pageSize) {
      final response = await client
          .from('reviews')
          .select(columns)
          .order('id')
          .range(offset, offset + pageSize - 1);
      final page = List<Map<String, dynamic>>.from(response);
      rows.addAll(page);
      if (page.length < pageSize) break;
    }
    return rows;
  }

  /// Post a product review to Supabase and update product aggregate rating
  Future<bool> insertReview(String productId, ReviewModel review) async {
    if (!_isInitialized) return false;

    try {
      await client.from('reviews').insert(review.toJson(productId));
      return true;
    } catch (e) {
      return false;
    }
  }

  // ==========================================
  // NOTIFICATIONS SERVICE (Supabase Table)
  // ==========================================

  /// Fetch notifications from Supabase
  Future<List<Map<String, dynamic>>> getNotifications() async {
    if (!_isInitialized) return [];
    try {
      final response = await client
          .from('notifications')
          .select()
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (_) {
      return [];
    }
  }

  /// Insert a notification in Supabase
  Future<bool> insertNotification(NotificationModel notification) async {
    if (!_isInitialized) return false;
    try {
      await client.from('notifications').insert(notification.toJson());
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Mark notification as read in Supabase
  Future<void> markNotificationAsRead(String id) async {
    if (!_isInitialized) return;
    try {
      await client.from('notifications').update({'is_read': true}).eq('id', id);
    } catch (_) {}
  }

  // ==========================================
  // SUPPORT TICKETS (Supabase Table)
  // ==========================================

  /// Send support inquiry to Supabase
  Future<bool> insertSupportTicket({
    required String name,
    required String email,
    required String subject,
    required String message,
  }) async {
    if (!_isInitialized) return false;
    try {
      await client.from('support_tickets').insert({
        'id': 'ticket_${DateTime.now().millisecondsSinceEpoch}',
        'user_name': name,
        'user_email': email,
        'subject': subject,
        'message': message,
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  // ==========================================
  // USER PROFILES (Supabase Table)
  // ==========================================

  Future<bool> createProfileForSignup({
    required String userId,
    required String name,
    required String phone,
  }) async {
    if (!_isInitialized) return false;
    try {
      await client.from('profiles').upsert({
        'id': userId,
        'name': name,
        'phone': phone,
        'role': 'customer',
      }, onConflict: 'id', ignoreDuplicates: true);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Upsert user profile in Supabase
  Future<bool> updateUserProfile({
    required String userId,
    required String name,
    required String phone,
    required String address,
    String? avatarUrl,
  }) async {
    if (!_isInitialized) return false;
    try {
      await client.from('profiles').upsert({
        'id': userId,
        'name': name,
        'phone': phone,
        'address': address,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Fetch all user profiles from Supabase
  Future<List<Map<String, dynamic>>> getProfiles() async {
    if (!_isInitialized) return [];
    try {
      final res = await client
          .from('profiles')
          .select()
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(res);
    } catch (_) {
      return [];
    }
  }

  // ==========================================
  // DRIVER RECRUITMENT (Supabase Table & Storage)
  // ==========================================

  /// Upload a driver document (license / vehicle photo) to Supabase Storage
  Future<String?> uploadDriverDocument({
    required Uint8List imageBytes,
    required String fileName,
  }) async {
    if (!_isInitialized) return null;
    try {
      final safeName = 'doc_${DateTime.now().millisecondsSinceEpoch}_$fileName';
      await client.storage.from('driver-documents').uploadBinary(
            safeName,
            imageBytes,
            fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
          );
      final publicUrl = client.storage.from('driver-documents').getPublicUrl(safeName);
      return publicUrl;
    } catch (_) {
      return null;
    }
  }

  /// Submit a driver recruitment application to Supabase
  Future<bool> submitDriverApplication(DriverApplicationModel app) async {
    if (!_isInitialized) return false;
    try {
      await client.from('driver_applications').insert(app.toJson());
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Fetch all driver recruitment applications from Supabase
  Future<List<Map<String, dynamic>>> getDriverApplications() async {
    if (!_isInitialized) return [];
    try {
      final res = await client
          .from('driver_applications')
          .select()
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(res);
    } catch (_) {
      return [];
    }
  }

  Future<bool> isCurrentUserApprovedCourier() async {
    if (!_isInitialized) return false;
    final userId = client.auth.currentUser?.id;
    if (userId == null) return false;
    try {
      final rows = await client
          .from('driver_applications')
          .select('id')
          .eq('user_id', userId)
          .eq('status', 'approved')
          .limit(1);
      return rows.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Update driver recruitment application status (approved / rejected)
  Future<bool> updateDriverApplicationStatus(String id, String status, {String? notes}) async {
    if (!_isInitialized) return false;
    try {
      await client.from('driver_applications').update({
        'status': status,
        if (notes != null) 'notes': notes,
      }).eq('id', id);
      return true;
    } catch (_) {
      return false;
    }
  }

  // ==========================================
  // AUTHENTICATION (Supabase Auth)
  // ==========================================

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String name,
    required String phone,
  }) async {
    if (!_isInitialized) {
      throw Exception('Supabase is not initialized');
    }

    return await client.auth.signUp(
      email: email,
      password: password,
      data: {'name': name, 'phone': phone},
    );
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    if (!_isInitialized) {
      throw Exception('Supabase is not initialized');
    }

    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> sendPasswordReset(String email) async {
    if (!_isInitialized) throw Exception('Supabase is not initialized');
    await client.auth.resetPasswordForEmail(
      email.trim(),
      redirectTo: 'commerceapp://reset-password',
    );
  }

  Future<void> changePassword(String newPassword) async {
    if (!_isInitialized || client.auth.currentUser == null) {
      throw Exception('Please sign in first.');
    }
    await client.auth.updateUser(UserAttributes(password: newPassword));
  }

  Future<void> signOut() async {
    if (!_isInitialized) return;
    await client.auth.signOut();
  }
}
