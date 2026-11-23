import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/notifications_viewmodel.dart';
import '../../core/localization/app_localizations.dart';
import '../../data/models/notification_model.dart';

class NotificationsView extends StatelessWidget {
  const NotificationsView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    final notifVM = Provider.of<NotificationsViewModel>(context);
    final primary = theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          loc.isArabic ? 'الإشعارات والتنبيهات' : 'Notifications',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        actions: [
          if (notifVM.notifications.isNotEmpty) ...[
            TextButton(
              onPressed: () => notifVM.markAllAsRead(),
              child: Text(
                loc.isArabic ? 'تحديد الكل كمقروء' : 'Mark all read',
                style: TextStyle(color: primary, fontSize: 12),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.clear_all_rounded),
              tooltip: loc.isArabic ? 'مسح الكل' : 'Clear all',
              onPressed: () => notifVM.clearAll(),
            ),
          ],
        ],
      ),
      body: notifVM.notifications.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: primary.withAlpha(20),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.notifications_none_rounded,
                        size: 64,
                        color: primary,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      loc.isArabic ? 'لا توجد إشعارات جديدة حالياً' : 'No notifications yet',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      loc.isArabic
                          ? 'ستظهر هنا كافة تحديثات حالة طلباتك والعروض الحصرية'
                          : 'Order updates and exclusive promotions will appear here',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.colorScheme.onSurface.withAlpha(130),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: notifVM.notifications.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final notif = notifVM.notifications[index];
                return Card(
                  color: notif.isRead
                      ? theme.cardTheme.color
                      : primary.withAlpha(theme.brightness == Brightness.dark ? 30 : 15),
                  child: InkWell(
                    onTap: () {
                      notifVM.markAsRead(notif.id);
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Type Icon
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: _getTypeColor(notif.type).withAlpha(25),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _getTypeIcon(notif.type),
                              color: _getTypeColor(notif.type),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 14),

                          // Content
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        notif.localizedTitle(loc.isArabic),
                                        style: TextStyle(
                                          fontWeight: notif.isRead ? FontWeight.bold : FontWeight.w900,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    if (!notif.isRead)
                                      Container(
                                        width: 8,
                                        height: 8,
                                        margin: const EdgeInsets.only(left: 6, right: 6),
                                        decoration: BoxDecoration(
                                          color: primary,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  notif.localizedBody(loc.isArabic),
                                  style: TextStyle(
                                    fontSize: 12,
                                    height: 1.4,
                                    color: theme.colorScheme.onSurface.withAlpha(160),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        _formatTime(notif.timestamp, loc.isArabic),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: theme.colorScheme.onSurface.withAlpha(110),
                                      ),
                                      ),
                                    ),
                                    if (notif.relatedOrderId != null)
                                      Flexible(
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            loc.isArabic ? 'تتبع الشحنة' : 'Track Order',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: primary,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Icon(Icons.arrow_forward_ios, size: 10, color: primary),
                                        ],
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Color _getTypeColor(NotificationType type) {
    switch (type) {
      case NotificationType.order:
        return const Color(0xFF3B82F6);
      case NotificationType.promo:
        return const Color(0xFFF59E0B);
      case NotificationType.system:
        return const Color(0xFF10B981);
    }
  }

  IconData _getTypeIcon(NotificationType type) {
    switch (type) {
      case NotificationType.order:
        return Icons.local_shipping_outlined;
      case NotificationType.promo:
        return Icons.local_offer_outlined;
      case NotificationType.system:
        return Icons.shield_outlined;
    }
  }

  String _formatTime(DateTime time, bool isArabic) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 60) {
      return isArabic ? 'منذ ${diff.inMinutes} دقيقة' : '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return isArabic ? 'منذ ${diff.inHours} ساعة' : '${diff.inHours}h ago';
    } else {
      return isArabic ? 'منذ ${diff.inDays} يوم' : '${diff.inDays}d ago';
    }
  }
}
