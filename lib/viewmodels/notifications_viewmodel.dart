import 'package:flutter/material.dart';
import '../data/models/notification_model.dart';
import '../core/services/supabase_service.dart';

class NotificationsViewModel extends ChangeNotifier {
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;

  List<NotificationModel> get notifications => List.unmodifiable(_notifications);
  int get unreadCount => _notifications.where((n) => !n.isRead).length;
  bool get isLoading => _isLoading;

  NotificationsViewModel() {
    loadNotificationsFromSupabase();
  }

  Future<void> loadNotificationsFromSupabase() async {
    final supabase = SupabaseService();
    if (!supabase.isInitialized) return;

    _isLoading = true;
    notifyListeners();

    try {
      final rows = await supabase.getNotifications();
      if (rows.isNotEmpty) {
        _notifications = rows.map((j) => NotificationModel.fromJson(j)).toList();
      }
    } catch (_) {}

    _isLoading = false;
    notifyListeners();
  }

  void markAsRead(String id) {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1 && !_notifications[index].isRead) {
      _notifications[index].isRead = true;
      notifyListeners();
      SupabaseService().markNotificationAsRead(id);
    }
  }

  void markAllAsRead() {
    for (var n in _notifications) {
      if (!n.isRead) {
        n.isRead = true;
        SupabaseService().markNotificationAsRead(n.id);
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
}
