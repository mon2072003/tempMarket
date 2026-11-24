import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/delivery_viewmodel.dart';
import '../../viewmodels/theme_viewmodel.dart';
import '../../core/localization/app_localizations.dart';
import '../../data/models/order_model.dart';
import '../widgets/delivery_map_painter.dart';

class DeliveryTrackingView extends StatelessWidget {
  const DeliveryTrackingView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    final themeVM = Provider.of<ThemeViewModel>(context);
    final deliveryVM = Provider.of<DeliveryViewModel>(context);
    final order = deliveryVM.currentTrackingOrder;
    final primary = theme.colorScheme.primary;

    if (order == null) {
      return Scaffold(
        appBar: AppBar(title: Text(loc.translate('live_tracking'))),
        body: Center(
          child: Text(
            loc.isArabic
                ? 'لا توجد طلبات قيد التوصيل'
                : 'No active delivery order',
          ),
        ),
      );
    }

    final courierAssigned = order.courier.name.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          loc.translate('live_tracking'),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      body: Column(
        children: [
          // Interactive Custom Painted Delivery Map
          Expanded(
            flex: 6,
            child: Stack(
              children: [
                ClipRect(
                  child: CustomPaint(
                    size: Size.infinite,
                    painter: DeliveryMapPainter(
                      progress: order.driverProgress,
                      primaryColor: primary,
                      secondaryColor: themeVM.currentBrand.secondaryColor,
                      isDark: themeVM.isDarkMode,
                    ),
                  ),
                ),

                // Floating Live ETA Badge
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: theme.cardTheme.color,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(35),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: primary.withAlpha(25),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.access_time_filled_rounded,
                                color: primary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  loc.translate('eta'),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: theme.colorScheme.onSurface
                                        .withAlpha(140),
                                  ),
                                ),
                                Text(
                                  order.status == OrderStatus.delivered
                                      ? (loc.isArabic
                                            ? 'وصل المندوب لوجهتك'
                                            : 'Driver Arrived')
                                      : (loc.isArabic
                                            ? '${order.estimatedArrivalMinutes} دقيقة تقريباً'
                                            : 'approx ${order.estimatedArrivalMinutes} mins'),
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900,
                                    color: order.status == OrderStatus.delivered
                                        ? const Color(0xFF10B981)
                                        : primary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withAlpha(25),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.circle,
                                size: 8,
                                color: Color(0xFF10B981),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                loc.isArabic ? 'مباشر' : 'LIVE',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF10B981),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom Tracking Sheet
          Expanded(
            flex: 5,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
              decoration: BoxDecoration(
                color: theme.cardTheme.color,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(25),
                    blurRadius: 12,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle Bar
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.onSurface.withAlpha(40),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                    // Order ID & Status Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${loc.translate('order_id')}: ${order.id}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              '${order.items.length} ${loc.isArabic ? "أصناف" : "items"} • ${order.total.toStringAsFixed(2)} ${loc.translate('sar')}',
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.onSurface.withAlpha(
                                  140,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: primary.withAlpha(25),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            order.status.localized(loc.isArabic),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Order Progress Stepper (4 steps)
                    _buildTrackingStepper(context, order, primary),
                    const SizedBox(height: 18),
                    const Divider(),
                    const SizedBox(height: 12),

                    // Courier Information Card
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundImage: order.courier.avatarUrl.isNotEmpty
                              ? NetworkImage(order.courier.avatarUrl)
                              : null,
                          backgroundColor: primary.withAlpha(20),
                          child: order.courier.avatarUrl.isEmpty
                              ? const Icon(Icons.delivery_dining_rounded)
                              : null,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                courierAssigned
                                    ? order.courier.name
                                    : (loc.isArabic
                                          ? '\u{628}\u{627}\u{646}\u{62a}\u{638}\u{627}\u{631}\u{20}\u{645}\u{646}\u{62f}\u{648}\u{628}'
                                          : 'Waiting for a courier'),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),
                              if (courierAssigned)
                                Text(
                                  order.courier.vehicle,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: theme.colorScheme.onSurface
                                        .withAlpha(130),
                                  ),
                                ),
                              if (courierAssigned)
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.star_rounded,
                                      size: 14,
                                      color: Color(0xFFF59E0B),
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      '${order.courier.rating}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                        // Contact actions appear after a courier accepts.
                        if (courierAssigned)
                          Row(
                            children: [
                              IconButton.filledTonal(
                                icon: const Icon(Icons.call_rounded, size: 18),
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        '${loc.translate('call_driver')}: ${order.courier.phone}',
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(width: 8),
                              IconButton.filled(
                                icon: const Icon(
                                  Icons.chat_bubble_outline_rounded,
                                  size: 18,
                                ),
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        '${loc.translate('chat_driver')}: ${order.courier.name}',
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackingStepper(
    BuildContext context,
    OrderModel order,
    Color primary,
  ) {
    final loc = AppLocalizations.of(context);
    final stages = [
      loc.translate('status_placed'),
      loc.translate('status_processing'),
      loc.translate('status_on_the_way'),
      loc.translate('status_delivered'),
    ];

    int activeStageIndex = 2; // Default on the way
    if (order.status == OrderStatus.placed) activeStageIndex = 0;
    if (order.status == OrderStatus.processing) activeStageIndex = 1;
    if (order.status == OrderStatus.onTheWay) activeStageIndex = 2;
    if (order.status == OrderStatus.delivered) activeStageIndex = 3;

    return Row(
      children: List.generate(stages.length, (index) {
        final isPassed = index <= activeStageIndex;
        final isCurrent = index == activeStageIndex;

        return Expanded(
          child: Column(
            children: [
              Row(
                children: [
                  if (index > 0)
                    Expanded(
                      child: Container(
                        height: 3,
                        color: isPassed ? primary : Colors.grey.withAlpha(60),
                      ),
                    ),
                  Container(
                    width: isCurrent ? 24 : 18,
                    height: isCurrent ? 24 : 18,
                    decoration: BoxDecoration(
                      color: isPassed ? primary : Colors.grey.withAlpha(60),
                      shape: BoxShape.circle,
                      border: isCurrent
                          ? Border.all(color: Colors.white, width: 2.5)
                          : null,
                    ),
                    child: isPassed
                        ? const Icon(Icons.check, size: 12, color: Colors.white)
                        : null,
                  ),
                  if (index < stages.length - 1)
                    Expanded(
                      child: Container(
                        height: 3,
                        color: index < activeStageIndex
                            ? primary
                            : Colors.grey.withAlpha(60),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                stages[index],
                textAlign: TextAlign.center,
                maxLines: 2,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isPassed ? FontWeight.bold : FontWeight.normal,
                  color: isPassed ? primary : Colors.grey,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
