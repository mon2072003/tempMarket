import 'dart:async';
import 'package:flutter/material.dart';
import '../data/models/order_model.dart';

class DeliveryViewModel extends ChangeNotifier {
  OrderModel? _currentTrackingOrder;
  Timer? _simulationTimer;
  bool _isSimulating = false;

  OrderModel? get currentTrackingOrder => _currentTrackingOrder;
  bool get isSimulating => _isSimulating;

  DeliveryViewModel() {
    startMovementSimulation();
  }

  void setTrackingOrder(OrderModel order) {
    _currentTrackingOrder = order;
    notifyListeners();
  }

  void startMovementSimulation() {
    _isSimulating = true;
    _simulationTimer?.cancel();
    _simulationTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      final order = _currentTrackingOrder;
      if (order == null) {
        timer.cancel();
        _isSimulating = false;
        return;
      }
      if (order.driverProgress < 0.95) {
        final newProgress = order.driverProgress + 0.05;
        final newEta = (order.estimatedArrivalMinutes > 2)
            ? order.estimatedArrivalMinutes - 1
            : 2;

        _currentTrackingOrder = OrderModel(
          id: order.id, date: order.date, items: order.items,
          subtotal: order.subtotal, tax: order.tax, deliveryFee: order.deliveryFee,
          discount: order.discount, total: order.total, status: order.status,
          deliveryAddress: order.deliveryAddress, paymentMethod: order.paymentMethod,
          courier: order.courier,
          estimatedArrivalMinutes: newEta,
          driverProgress: newProgress,
        );
        notifyListeners();
      } else {
        // Driver arrived
        _currentTrackingOrder = OrderModel(
          id: order.id, date: order.date, items: order.items,
          subtotal: order.subtotal, tax: order.tax, deliveryFee: order.deliveryFee,
          discount: order.discount, total: order.total,
          status: OrderStatus.delivered,
          deliveryAddress: order.deliveryAddress, paymentMethod: order.paymentMethod,
          courier: order.courier,
          estimatedArrivalMinutes: 0,
          driverProgress: 1.0,
        );
        _simulationTimer?.cancel();
        _isSimulating = false;
        notifyListeners();
      }
    });
  }

  void resetSimulation() {
    if (_currentTrackingOrder == null) return;
    startMovementSimulation();
  }

  @override
  void dispose() {
    _simulationTimer?.cancel();
    super.dispose();
  }
}
