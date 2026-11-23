import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../viewmodels/orders_viewmodel.dart';
import '../../viewmodels/cart_viewmodel.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/services/location_service.dart';
import '../../data/models/order_model.dart';

class OrdersHistoryView extends StatefulWidget {
  const OrdersHistoryView({super.key});

  @override
  State<OrdersHistoryView> createState() => _OrdersHistoryViewState();
}

class _OrdersHistoryViewState extends State<OrdersHistoryView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<OrdersViewModel>(context, listen: false).loadOrdersFromSupabase();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    final ordersVM = Provider.of<OrdersViewModel>(context);
    final primary = theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          loc.translate('order_history'),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: primary,
          labelColor: primary,
          unselectedLabelColor: theme.colorScheme.onSurface.withAlpha(140),
          tabs: [
            Tab(
              icon: const Icon(Icons.pending_actions_rounded, size: 18),
              text: loc.isArabic ? 'قيد الشراء والتوصيل' : 'In-Progress Purchases',
            ),
            Tab(
              icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
              text: loc.isArabic ? 'تم شراؤها بنجاح' : 'Successfully Purchased',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOrdersList(ordersVM.orders.where((o) => o.status != OrderStatus.delivered).toList(), theme, loc, primary),
          _buildOrdersList(ordersVM.pastDeliveredOrders, theme, loc, primary),
        ],
      ),
    );
  }

  Widget _buildOrdersList(
    List<OrderModel> orders,
    ThemeData theme,
    AppLocalizations loc,
    Color primary,
  ) {
    if (orders.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.assignment_late_outlined,
                size: 64,
                color: theme.colorScheme.onSurface.withAlpha(100),
              ),
              const SizedBox(height: 16),
              Text(
                loc.translate('no_orders'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final order = orders[index];
        final isDelivered = order.status == OrderStatus.delivered;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order ID and Date
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: primary.withAlpha(20),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.receipt_long_outlined, color: primary, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              order.id,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              '${order.date.year}/${order.date.month}/${order.date.day}',
                              style: TextStyle(
                                fontSize: 11,
                                color: theme.colorScheme.onSurface.withAlpha(120),
                              ),
                            ),
                          ],
                        ),
                      ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDelivered
                            ? const Color(0xFF10B981).withAlpha(25)
                            : primary.withAlpha(25),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        order.status.localized(loc.isArabic),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isDelivered ? const Color(0xFF10B981) : primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(),
                ),

                // Purchased Products Preview
                Column(
                  children: order.items.map((cartItem) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: SizedBox(
                              width: 48,
                              height: 48,
                              child: Image.network(
                                cartItem.product.images.first,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: primary.withAlpha(20),
                                  child: Icon(Icons.inventory_2_outlined, color: primary, size: 20),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  cartItem.product.localizedName(loc.isArabic),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  '${cartItem.quantity}x ${cartItem.product.price.toStringAsFixed(0)} ${loc.translate('sar')}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: theme.colorScheme.onSurface.withAlpha(140),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Flexible(
                            child: Text(
                              '${cartItem.totalPrice.toStringAsFixed(0)} ${loc.translate('sar')}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.end,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),

                const Divider(),
                const SizedBox(height: 6),

                // Total and Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loc.translate('total'),
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.colorScheme.onSurface.withAlpha(120),
                          ),
                        ),
                        Text(
                          '${order.total.toStringAsFixed(2)} ${loc.translate('sar')}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        if (!isDelivered) ...[
                          IconButton(
                            tooltip: loc.isArabic ? 'فتح المسار في خرائط جوجل' : 'Open in Google Maps',
                            icon: const Icon(Icons.map_outlined, color: Colors.blue, size: 20),
                            onPressed: () async {
                              final uri = Uri.parse(LocationService.getNavigationUrl(
                                destLat: LocationService.defaultLat + 0.02,
                                destLng: LocationService.defaultLng + 0.02,
                              ));
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(uri, mode: LaunchMode.externalApplication);
                              }
                            },
                          ),
                          const SizedBox(width: 4),
                        ]
                        else
                          OutlinedButton.icon(
                            onPressed: () {
                              final cartVM = Provider.of<CartViewModel>(context, listen: false);
                              for (var itm in order.items) {
                                cartVM.addToCart(itm.product, quantity: itm.quantity);
                              }
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    loc.isArabic ? 'تمت إضافة المنتجات إلى السلة مجدداً' : 'Items added to cart again',
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.replay_rounded, size: 16),
                            label: Text(
                              loc.isArabic ? 'إعادة الشراء' : 'Reorder',
                              style: const TextStyle(fontSize: 12),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
