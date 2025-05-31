import 'package:flutter/foundation.dart';
import 'package:musify/models/notification_model.dart';

class NotificationProvider with ChangeNotifier {
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  int _unreadCount = 0;

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  int get unreadCount => _unreadCount;

  NotificationProvider() {
    // For now, load some mock data. Replace with actual fetching logic.
    _loadMockNotifications();
  }

  Future<void> fetchNotifications() async {
    _isLoading = true;
    notifyListeners();

    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    // TODO: Replace with actual API call or local data fetching
    // For now, just re-load mock data or clear existing if you want to simulate refresh
    _notifications = [
      NotificationModel(
        id: '1',
        title: 'New Album Release!',
        body: 'Check out the latest album by Your Favorite Artist.',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        type: 'new_release',
        data: {'artistId': '123'},
      ),
      NotificationModel(
        id: '2',
        title: 'Playlist Shared',
        body: 'Your friend shared a playlist with you: Summer Vibes.',
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        isRead: true,
        type: 'playlist_share',
        data: {'playlistId': 'abc'},
      ),
      NotificationModel(
        id: '3',
        title: 'System Update Available',
        body: 'A new version of Musify is ready to install.',
        timestamp: DateTime.now().subtract(const Duration(days: 3)),
        type: 'system_update',
      ),
    ];
    _calculateUnreadCount();
    _isLoading = false;
    notifyListeners();
  }

  void _loadMockNotifications() {
    _notifications = [
      NotificationModel(
        id: '1',
        title: 'New Album Release!',
        body: 'Check out the latest album by Your Favorite Artist.',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        type: 'new_release',
        data: {'artistId': '123'},
      ),
      NotificationModel(
        id: '2',
        title: 'Playlist Shared',
        body: 'Your friend shared a playlist with you: Summer Vibes.',
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        isRead: true,
        type: 'playlist_share',
        data: {'playlistId': 'abc'},
      ),
      NotificationModel(
        id: '3',
        title: 'System Update Available',
        body: 'A new version of Musify is ready to install.',
        timestamp: DateTime.now().subtract(const Duration(days: 3)),
        type: 'system_update',
      ),
      NotificationModel(
        id: '4',
        title: 'Welcome to Musify!',
        body: 'Explore millions of songs and create your own playlists.',
        timestamp: DateTime.now().subtract(const Duration(days: 5)),
        isRead: true,
        type: 'welcome',
      ),
    ];
    _calculateUnreadCount();
    // notifyListeners(); // Not strictly needed here if called after in constructor or init
  }

  void _calculateUnreadCount() {
    _unreadCount = _notifications.where((n) => !n.isRead).length;
  }

  Future<void> markAsRead(String notificationId) async {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1 && !_notifications[index].isRead) {
      _notifications[index].isRead = true;
      _calculateUnreadCount();
      notifyListeners();
      // TODO: Persist this change (e.g., update backend or local storage)
    }
  }

  Future<void> markAllAsRead() async {
    bool changed = false;
    for (var notification in _notifications) {
      if (!notification.isRead) {
        notification.isRead = true;
        changed = true;
      }
    }
    if (changed) {
      _calculateUnreadCount();
      notifyListeners();
      // TODO: Persist this change
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    _notifications.removeWhere((n) => n.id == notificationId);
    _calculateUnreadCount();
    notifyListeners();
    // TODO: Persist this change
  }

  Future<void> clearAllNotifications() async {
    if (_notifications.isNotEmpty) {
      _notifications = [];
      _unreadCount = 0;
      notifyListeners();
      // TODO: Persist this change (e.g., clear all from backend/local storage)
    }
  }
}
