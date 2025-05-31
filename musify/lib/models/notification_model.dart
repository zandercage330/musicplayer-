class NotificationModel {
  final String id;
  final String title;
  final String body;
  final DateTime timestamp;
  bool isRead;
  final String? type; // e.g., 'new_release', 'system_update', 'playlist_share'
  final Map<String, dynamic>? data; // Optional data for navigation or actions

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    this.isRead = false,
    this.type,
    this.data,
  });

  // Optional: Add factory constructor for JSON parsing if fetching from a service
  // factory NotificationModel.fromJson(Map<String, dynamic> json) { ... }

  // Optional: Add toJson method if sending data to a service
  // Map<String, dynamic> toJson() { ... }
}
