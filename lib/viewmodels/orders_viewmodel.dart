import 'dart:async';
import 'package:flutter/material.dart';
import '../data/models/order_model.dart';
import '../data/models/cart_item_model.dart';
import '../data/models/product_model.dart';
import '../core/services/supabase_service.dart';

class OrdersViewModel extends ChangeNotifier {
  final List<OrderModel> _orders = [];
  Timer? _refreshTimer;
  String? _errorMessage;

  OrdersViewModel() {
    loadOrdersFromSupabase();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => loadOrdersFromSupabase(),
    );
    final supabase = SupabaseService();
    if (supabase.isInitialized) {
      supabase.client.auth.onAuthStateChange.listen(
        (_) => loadOrdersFromSupabase(),
      );
    }
  }

  List<OrderModel> get orders => List.unmodifiable(_orders);
  String? get errorMessage => _errorMessage;

  Future<void> loadOrdersFromSupabase() async {
    final supabase = SupabaseService();
    if (!supabase.isInitialized) return;
    try {
      final rows = await supabase.getCurrentUserOrders();
      final products = await supabase.getProducts();
      final productModels = products.map(ProductModel.fromJson).toList();
      _orders
        ..clear()
        ..addAll(
          rows.map(
            (row) => OrderModel.fromSupabase(row, productsPool: productModels),
          ),
        );
      notifyListeners();
    } catch (_) {}
  }

  List<OrderModel> get pastDeliveredOrders =>
      _orders.where((o) => o.status == OrderStatus.delivered).toList();

  Future<OrderModel?> placeOrder({
    required List<CartItemModel> items,
    required double subtotal,
    required double tax,
    required double deliveryFee,
    required double discount,
    required double total,
    required String address,
    required String paymentMethod,
  }) async {
    _errorMessage = null;
    final newOrder = OrderModel(
      id: 'ORD-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      date: DateTime.now(),
      items: List.from(items),
      subtotal: subtotal,
      tax: tax,
      deliveryFee: deliveryFee,
      discount: discount,
      total: total,
      status: OrderStatus.placed,
      deliveryAddress: address,
      paymentMethod: paymentMethod,
      courier: const CourierInfo(
        name: '',
        phone: '',
        vehicle: '',
        avatarUrl: '',
        rating: 0,
      ),
      estimatedArrivalMinutes: 0,
      driverProgress: 0,
    );

    final supabase = SupabaseService();
    if (!supabase.isInitialized) {
      _errorMessage = 'Service is unavailable. Please try again later.';
      notifyListeners();
      return null;
    }
    final userId = supabase.client.auth.currentUser?.id;
    if (userId == null) {
      _errorMessage = 'Please sign in before completing payment.';
      notifyListeners();
      return null;
    }
    try {
      final inserted = await supabase.insertOrder(newOrder, userId);
      if (!inserted) {
        _errorMessage = 'The order could not be saved. Please try again.';
        notifyListeners();
        return null;
      }
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return null;
    }

    _orders.insert(0, newOrder);
    notifyListeners();
    return newOrder;
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}
