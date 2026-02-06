import 'package:flutter/material.dart';
import '../../services/websocket_service.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: TextStyle(
            color: Theme.of(context).appBarTheme.foregroundColor ?? Theme.of(context).colorScheme.onSurface,
          ),
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: Theme.of(context).appBarTheme.elevation ?? 0,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        actions: [
          Row(
            children: [
              IconButton(
                onPressed: () {
                  WebSocketService().markAllAsRead();
                },
                icon: Icon(Icons.done_all, color: Theme.of(context).colorScheme.primary),
                tooltip: 'Mark All Read',
              ),
              IconButton(
                onPressed: () {
                  WebSocketService().clearAll();
                },
                icon: Icon(Icons.delete_forever, color: Theme.of(context).colorScheme.primary),
                tooltip: 'Clear All',
              ),
            ],
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: WebSocketService().notificationStream,
        initialData: WebSocketService().notifications,
        builder: (context, snapshot) {
          final notifications = snapshot.data ?? const [];

          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off, size: 64, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                  SizedBox(height: 16),
                  Text('No notifications yet',
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7))),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notif = notifications[index];
              final isRead = notif['is_read'] ?? 0;
              final title = (notif['title'] ?? '').toString();
              final body = (notif['body'] ?? '').toString();

              return ListTile(
                leading: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isRead == 0 ? Theme.of(context).colorScheme.primary : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                ),
                title: Text(
                  title.isEmpty ? 'Notification' : title,
                  style: TextStyle(
                    fontWeight: isRead == 0 ? FontWeight.bold : FontWeight.normal,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                subtitle: Text(body, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8))),
                trailing: Text(
                  _formatTime(notif['created_at']),
                  style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                ),
                tileColor: isRead == 0 ? Theme.of(context).colorScheme.primary.withOpacity(0.05) : null,
                onTap: () {
                  final id = notif['id']?.toString();
                  if (id != null && isRead == 0) {
                    WebSocketService().markAsRead(id);
                  }
                },
              );
            },
          );
        },
      ),
    );
  }

  String _formatTime(dynamic timestamp) {
    if (timestamp == null) return '';
    try {
      final date = DateTime.parse(timestamp.toString());
      final now = DateTime.now();
      final diff = now.difference(date);
      
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inHours < 1) return '${diff.inMinutes}m ago';
      if (diff.inDays < 1) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return '';
    }
  }
}
