import 'package:flutter/material.dart';
import '../data/models/cart_item_model.dart';
import '../data/models/product_model.dart';
import '../core/services/supabase_service.dart';

class CartViewModel extends ChangeNotifier {
  final List<CartItemModel> _items = [];
  String? _appliedCoupon;
  double _discountPercentage = 0.0;
  final double _taxRate = 0.15; // 15% VAT
  final double _standardDeliveryFee = 15.0;
  bool _isLoadingFromSupabase = false;

  CartViewModel() {
    loadCartFromSupabase();
    final supabase = SupabaseService();
    if (supabase.isInitialized) {
      supabase.client.auth.onAuthStateChange.listen((_) => loadCartFromSupabase());
    }
  }

  List<CartItemModel> get items => List.unmodifiable(_items);
  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);
  bool get isEmpty => _items.isEmpty;

  double get subtotal =>
      _items.fold(0.0, (sum, item) => sum + item.totalPrice);

  double get discountAmount => subtotal * _discountPercentage;

  double get taxAmount => (subtotal - discountAmount) * _taxRate;

  double get deliveryFee => (subtotal > 200 || _items.isEmpty) ? 0.0 : _standardDeliveryFee;

  double get grandTotal => (subtotal - discountAmount) + taxAmount + deliveryFee;

  String? get appliedCoupon => _appliedCoupon;

  Future<void> loadCartFromSupabase() async {
    final supabase = SupabaseService();
    if (!supabase.isInitialized || _isLoadingFromSupabase) return;
    if (supabase.client.auth.currentUser == null) {
      _items.clear();
      notifyListeners();
      return;
    }

    _isLoadingFromSupabase = true;
    try {
      final rows = await supabase.getCurrentUserCart();
      final loadedItems = <CartItemModel>[];
      for (final row in rows) {
        final rawProduct = row['products'];
        if (rawProduct is Map) {
          loadedItems.add(
            CartItemModel(
              product: ProductModel.fromJson(Map<String, dynamic>.from(rawProduct)),
              quantity: (row['quantity'] as num?)?.toInt() ?? 1,
              selectedNote: row['selected_note']?.toString(),
            ),
          );
        }
      }
      _items
        ..clear()
        ..addAll(loadedItems);
      notifyListeners();
    } catch (_) {
      // Keep the local cart usable if the cart table has not been migrated yet.
    } finally {
      _isLoadingFromSupabase = false;
    }
  }

  void addToCart(ProductModel product, {int quantity = 1, String? note}) {
    final existingIndex = _items.indexWhere((item) => item.product.id == product.id);
    if (existingIndex != -1) {
      _items[existingIndex].quantity += quantity;
    } else {
      _items.add(CartItemModel(product: product, quantity: quantity, selectedNote: note));
    }
    notifyListeners();
    _syncItem(_items[existingIndex == -1 ? _items.length - 1 : existingIndex]);
  }

  void incrementQuantity(String productId) {
    final index = _items.indexWhere((item) => item.product.id == productId);
    if (index != -1) {
      _items[index].quantity += 1;
      notifyListeners();
      _syncItem(_items[index]);
    }
  }

  void decrementQuantity(String productId) {
    final index = _items.indexWhere((item) => item.product.id == productId);
    if (index != -1) {
      if (_items[index].quantity > 1) {
        _items[index].quantity -= 1;
      } else {
        _items.removeAt(index);
        SupabaseService().deleteCartItem(productId);
      }
      notifyListeners();
      if (index != -1 && _items.any((item) => item.product.id == productId)) {
        _syncItem(_items[index]);
      }
    }
  }

  void removeFromCart(String productId) {
    _items.removeWhere((item) => item.product.id == productId);
    notifyListeners();
    SupabaseService().deleteCartItem(productId);
  }

  Future<bool> applyCoupon(String code) async {
    final cleanCode = code.trim().toUpperCase();
    if (cleanCode.isEmpty) return false;
    try {
      final promo = await SupabaseService().validatePromoCode(cleanCode);
      if (promo == null) return false;
      _appliedCoupon = promo.code;
      _discountPercentage = promo.discountPercent / 100;
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  void removeCoupon() {
    _appliedCoupon = null;
    _discountPercentage = 0.0;
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    _appliedCoupon = null;
    _discountPercentage = 0.0;
    notifyListeners();
    SupabaseService().clearCurrentUserCart();
  }

  void _syncItem(CartItemModel item) {
    SupabaseService().upsertCartItem(
      productId: item.product.id,
      quantity: item.quantity,
      selectedNote: item.selectedNote,
    );
  }
}
