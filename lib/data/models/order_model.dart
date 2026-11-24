import 'cart_item_model.dart';
import 'product_model.dart';

enum OrderStatus {
  placed('تم الاستلام', 'Placed'),
  processing('قيد التجهيز والتغليف', 'Processing'),
  onTheWay('في الطريق إليك', 'On The Way'),
  delivered('تم التسليم بنجاح', 'Delivered'),
  cancelled('ملغي', 'Cancelled');

  final String titleAr;
  final String titleEn;
  const OrderStatus(this.titleAr, this.titleEn);

  String localized(bool isArabic) => isArabic ? titleAr : titleEn;

  static OrderStatus fromString(String? val) {
    switch (val?.toLowerCase()) {
      case 'processing':
        return OrderStatus.processing;
      case 'ontheway':
      case 'on_the_way':
        return OrderStatus.onTheWay;
      case 'delivered':
        return OrderStatus.delivered;
      case 'cancelled':
        return OrderStatus.cancelled;
      case 'placed':
      default:
        return OrderStatus.placed;
    }
  }
}

class CourierInfo {
  final String name;
  final String phone;
  final String vehicle;
  final double rating;
  final String avatarUrl;

  const CourierInfo({
    required this.name,
    required this.phone,
    required this.vehicle,
    this.rating = 4.9,
    this.avatarUrl = '',
  });
}

class OrderModel {
  final String id;
  final String customerId;
  final DateTime date;
  final List<CartItemModel> items;
  final double subtotal;
  final double tax;
  final double deliveryFee;
  final double discount;
  final double total;
  final OrderStatus status;
  final String deliveryAddress;
  final double destLat;
  final double destLng;
  final String paymentMethod;
  final CourierInfo courier;
  final int estimatedArrivalMinutes;
  final double driverProgress; // 0.0 to 1.0 on delivery route

  const OrderModel({
    required this.id,
    this.customerId = '',
    required this.date,
    required this.items,
    required this.subtotal,
    required this.tax,
    required this.deliveryFee,
    required this.discount,
    required this.total,
    required this.status,
    required this.deliveryAddress,
    this.destLat = 24.7136,
    this.destLng = 46.6753,
    required this.paymentMethod,
    required this.courier,
    this.estimatedArrivalMinutes = 0,
    this.driverProgress = 0,
  });

  OrderModel copyWith({
    String? id,
    String? customerId,
    DateTime? date,
    List<CartItemModel>? items,
    double? subtotal,
    double? tax,
    double? deliveryFee,
    double? discount,
    double? total,
    OrderStatus? status,
    String? deliveryAddress,
    double? destLat,
    double? destLng,
    String? paymentMethod,
    CourierInfo? courier,
    int? estimatedArrivalMinutes,
    double? driverProgress,
  }) {
    return OrderModel(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      date: date ?? this.date,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      tax: tax ?? this.tax,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      discount: discount ?? this.discount,
      total: total ?? this.total,
      status: status ?? this.status,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      destLat: destLat ?? this.destLat,
      destLng: destLng ?? this.destLng,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      courier: courier ?? this.courier,
      estimatedArrivalMinutes:
          estimatedArrivalMinutes ?? this.estimatedArrivalMinutes,
      driverProgress: driverProgress ?? this.driverProgress,
    );
  }

  factory OrderModel.fromSupabase(
    Map<String, dynamic> json, {
    List<ProductModel>? productsPool,
  }) {
    final rawItems = json['order_items'] as List? ?? [];
    final parsedItems = rawItems.map((itemJson) {
      final pId = itemJson['product_id']?.toString() ?? '';
      ProductModel? matched;
      if (productsPool != null) {
        try {
          matched = productsPool.firstWhere((p) => p.id == pId);
        } catch (_) {}
      }

      final product =
          matched ??
          ProductModel(
            id: pId,
            nameAr: 'منتج مسجل',
            nameEn: 'Product',
            descriptionAr: '',
            descriptionEn: '',
            price: (itemJson['unit_price'] as num?)?.toDouble() ?? 10.0,
            categoryId: 'cat_general',
            businessType: 'general',
            images: const [
              'https://images.unsplash.com/photo-1581092160607-ee22621dd758?w=600',
            ],
            inStock: true,
            unitAr: 'قطعة',
            unitEn: 'Piece',
          );

      return CartItemModel(
        product: product,
        quantity: (itemJson['quantity'] as num?)?.toInt() ?? 1,
      );
    }).toList();

    return OrderModel(
      id: json['id']?.toString() ?? '',
      customerId: json['user_id']?.toString() ?? '',
      date: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      items: parsedItems,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      tax: (json['tax'] as num?)?.toDouble() ?? 0.0,
      deliveryFee: (json['delivery_fee'] as num?)?.toDouble() ?? 0.0,
      discount: (json['discount'] as num?)?.toDouble() ?? 0.0,
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      status: OrderStatus.fromString(json['status']?.toString()),
      deliveryAddress: json['delivery_address']?.toString() ?? 'الرياض',
      destLat: (json['dest_lat'] as num?)?.toDouble() ?? 24.7136,
      destLng: (json['dest_lng'] as num?)?.toDouble() ?? 46.6753,
      paymentMethod: json['payment_method']?.toString() ?? 'cash_on_delivery',
      courier: CourierInfo(
        name: json['courier_name']?.toString() ?? '',
        phone: json['courier_phone']?.toString() ?? '',
        vehicle: json['courier_vehicle']?.toString() ?? '',
        avatarUrl: json['courier_avatar']?.toString() ?? '',
      ),
      estimatedArrivalMinutes:
          (json['estimated_arrival_minutes'] as num?)?.toInt() ?? 0,
      driverProgress: (json['driver_progress'] as num?)?.toDouble() ?? 0,
    );
  }
}
