import 'dart:async';
import 'package:flutter/material.dart';
import '../data/models/notification_model.dart';
import '../core/services/supabase_service.dart';

class NotificationsViewModel extends ChangeNotifier {
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  bool _isRefreshing = false;
  Timer? _refreshTimer;

  List<NotificationModel> get notifications =>
      List.unmodifiable(_notifications);
  int get unreadCount => _notifications.where((n) => !n.isRead).length;
  bool get isLoading => _isLoading;

  NotificationsViewModel() {
    unawaited(loadNotificationsFromSupabase());
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => unawaited(loadNotificationsFromSupabase(showLoading: false)),
    );
  }

  Future<void> loadNotificationsFromSupabase({bool showLoading = true}) async {
    final supabase = SupabaseService();
    if (!supabase.isInitialized || _isRefreshing) return;

    _isRefreshing = true;
    if (showLoading) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      final rows = await supabase.getNotifications();
      _notifications = rows.map(NotificationModel.fromJson).toList();
    } catch (_) {
      // Keep the cached notifications when a refresh fails.
    } finally {
      _isRefreshing = false;
      _isLoading = false;
      notifyListeners();
    }
  }

  void markAsRead(String id) {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1 && !_notifications[index].isRead) {
      _notifications[index].isRead = true;
      notifyListeners();
      unawaited(SupabaseService().markNotificationAsRead(id));
    }
  }

  void markAllAsRead() {
    for (final notification in _notifications) {
      if (!notification.isRead) {
        notification.isRead = true;
        unawaited(SupabaseService().markNotificationAsRead(notification.id));
      }
    }
    notifyListeners();
  }

  void clearAll() {
    _notifications.clear();
    notifyListeners();
  }

  Future<void> addNotification(NotificationModel notification) async {
    _notifications.insert(0, notification);
    notifyListeners();
    await SupabaseService().insertNotification(notification);
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}
