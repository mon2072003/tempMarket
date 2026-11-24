import 'dart:async';

import 'package:flutter/material.dart';

import '../core/services/supabase_service.dart';
import '../data/models/order_model.dart';

class DeliveryViewModel extends ChangeNotifier {
  OrderModel? _currentTrackingOrder;
  Timer? _refreshTimer;
  bool _isRefreshing = false;

  OrderModel? get currentTrackingOrder => _currentTrackingOrder;

  void setTrackingOrder(OrderModel order) {
    _currentTrackingOrder = order;
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => refreshTrackedOrder(),
    );
    refreshTrackedOrder();
    notifyListeners();
  }

  Future<void> refreshTrackedOrder() async {
    final current = _currentTrackingOrder;
    final service = SupabaseService();
    if (current == null || !service.isInitialized || _isRefreshing) return;

    _isRefreshing = true;
    try {
      final rows = await service.getCurrentUserOrders();
      for (final row in rows) {
        if (row['id']?.toString() != current.id) continue;
        final courierName = row['courier_name']?.toString() ?? '';
        _currentTrackingOrder = current.copyWith(
          status: OrderStatus.fromString(row['status']?.toString()),
          courier: CourierInfo(
            name: courierName,
            phone: row['courier_phone']?.toString() ?? '',
            vehicle: row['courier_vehicle']?.toString() ?? '',
            avatarUrl: row['courier_avatar']?.toString() ?? '',
            rating: current.courier.rating,
          ),
          estimatedArrivalMinutes:
              (row['estimated_arrival_minutes'] as num?)?.toInt() ?? 0,
          driverProgress: (row['driver_progress'] as num?)?.toDouble() ?? 0,
        );
        notifyListeners();
        break;
      }
    } catch (_) {
      // Keep showing the latest known order while the network is unavailable.
    } finally {
      _isRefreshing = false;
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}
