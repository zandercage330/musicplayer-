import 'package:flutter/material.dart';
import 'package:musify/models/notification_model.dart';
import 'package:musify/providers/notification_provider.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // For date formatting

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  void initState() {
    super.initState();
    // Optionally, mark all as read when the screen is opened after a slight delay
    // Or fetch fresh notifications
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<NotificationProvider>(
        context,
        listen: false,
      );
      // provider.markAllAsRead(); // Decide if this should be automatic
      if (provider.notifications.isEmpty) {
        provider.fetchNotifications(); // Fetch if list is empty
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () {
              Provider.of<NotificationProvider>(
                context,
                listen: false,
              ).markAllAsRead();
            },
            child: Text(
              'Mark All Read',
              style: TextStyle(color: Theme.of(context).colorScheme.secondary),
            ),
          ),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.notifications.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(
                    Icons.notifications_off_outlined,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'No notifications yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Check back later for updates!',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text('Check for Notifications'),
                    onPressed: () {
                      provider.fetchNotifications();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                      foregroundColor: Colors.black,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.fetchNotifications(),
            child: ListView.builder(
              itemCount: provider.notifications.length,
              itemBuilder: (context, index) {
                final notification = provider.notifications[index];
                return _NotificationItem(notification: notification);
              },
            ),
          );
        },
      ),
    );
  }
}

class _NotificationItem extends StatelessWidget {
  final NotificationModel notification;

  const _NotificationItem({required this.notification});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<NotificationProvider>(context, listen: false);
    final timeAgo = DateFormat.jm().add_yMMMd().format(notification.timestamp);

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        provider.deleteNotification(notification.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${notification.title} dismissed')),
        );
      },
      background: Container(
        color: Colors.redAccent,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        alignment: AlignmentDirectional.centerEnd,
        child: const Icon(Icons.delete_sweep, color: Colors.white),
      ),
      child: ListTile(
        leading: Icon(
          notification.isRead
              ? Icons.notifications_none_outlined
              : Icons.notifications_active,
          color:
              notification.isRead
                  ? Colors.grey
                  : Theme.of(context).colorScheme.secondary,
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight:
                notification.isRead ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification.body),
            const SizedBox(height: 4),
            Text(
              timeAgo,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey[500]),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.close, size: 20),
          onPressed: () {
            provider.deleteNotification(notification.id);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${notification.title} removed')),
            );
          },
        ),
        onTap: () {
          if (!notification.isRead) {
            provider.markAsRead(notification.id);
          }
          // TODO: Implement navigation or action based on notification.type and notification.data
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Tapped on: ${notification.title}')),
          );
        },
        tileColor:
            notification.isRead
                ? null
                : Theme.of(context).colorScheme.secondary.withAlpha(30),
        isThreeLine: true,
      ),
    );
  }
}
