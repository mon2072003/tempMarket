import 'package:flutter/material.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/services/supabase_service.dart';

class CourierOrdersView extends StatefulWidget {
  const CourierOrdersView({super.key});

  @override
  State<CourierOrdersView> createState() => _CourierOrdersViewState();
}

class _CourierOrdersViewState extends State<CourierOrdersView> {
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    final rows = await SupabaseService().getOrdersWithItems();
    if (!mounted) return;
    setState(() {
      _orders = rows;
      _isLoading = false;
    });
  }

  Future<void> _updateStatus(String id, String status) async {
    final success = await SupabaseService().updateOrderStatus(id, status);
    if (!mounted) return;
    final loc = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? (loc.isArabic ? 'تم تحديث حالة الطلب.' : 'Order status updated.')
              : (loc.isArabic ? 'تعذر تحديث الطلب.' : 'Could not update order.'),
        ),
      ),
    );
    if (success) _loadOrders();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.isArabic ? 'طلبات المندوب' : 'Courier Orders'),
        actions: [
          IconButton(onPressed: _loadOrders, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadOrders,
              child: _orders.isEmpty
                  ? ListView(
                      children: [
                        SizedBox(height: 180),
                        Center(
                          child: Text(
                            loc.isArabic ? 'لا توجد طلبات عملاء متاحة.' : 'No customer orders available.',
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _orders.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final order = _orders[index];
                        final status = order['status']?.toString() ?? 'placed';
                        final orderId = order['id']?.toString() ?? '';
                        final nextStatus = _nextStatus(status);
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.receipt_long_outlined),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Order $orderId',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    Chip(label: Text(_statusTitle(status, loc.isArabic))),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  order['delivery_address']?.toString() ??
                                      (loc.isArabic ? 'لا يوجد عنوان' : 'No address'),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${loc.isArabic ? 'الإجمالي' : 'Total'}: ${(order['total'] as num?)?.toDouble().toStringAsFixed(2) ?? '0.00'} ${loc.translate('sar')}',
                                  style: TextStyle(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (nextStatus != null) ...[
                                  const SizedBox(height: 12),
                                  Align(
                                    alignment: AlignmentDirectional.centerEnd,
                                    child: ElevatedButton.icon(
                                      onPressed: () => _updateStatus(orderId, nextStatus),
                                      icon: const Icon(Icons.update, size: 18),
                                      label: Text(
                                        loc.isArabic
                                            ? 'تغيير إلى ${_statusTitle(nextStatus, true)}'
                                            : 'Mark ${_statusTitle(nextStatus, false)}',
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }

  String? _nextStatus(String status) {
    switch (status.toLowerCase()) {
      case 'placed':
        return 'processing';
      case 'processing':
        return 'onTheWay';
      case 'ontheway':
      case 'on_the_way':
        return 'delivered';
      default:
        return null;
    }
  }

  String _statusTitle(String status, bool isArabic) {
    if (!isArabic) {
      switch (status.toLowerCase()) {
        case 'ontheway':
        case 'on_the_way':
          return 'On The Way';
        default:
          return status[0].toUpperCase() + status.substring(1);
      }
    }
    switch (status.toLowerCase()) {
      case 'placed':
        return 'تم الاستلام';
      case 'processing':
        return 'قيد التجهيز';
      case 'ontheway':
      case 'on_the_way':
        return 'في الطريق';
      case 'delivered':
        return 'تم التسليم';
      default:
        return status;
    }
  }
}
