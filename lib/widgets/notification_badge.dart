import 'package:flutter/material.dart';
import 'package:flutter_app_badger/flutter_app_badger.dart';
import '../../services/websocket_service.dart';

class NotificationBadge extends StatefulWidget {
  final VoidCallback onTap;
  
  const NotificationBadge({
    Key? key,
    required this.onTap,
  }) : super(key: key);

  @override
  State<NotificationBadge> createState() => _NotificationBadgeState();
}

class _NotificationBadgeState extends State<NotificationBadge> {
  int _lastBadgeCount = -1;

  void _updateAppIconBadge(int count) {
    try {
      if (count > 0) {
        FlutterAppBadger.updateBadgeCount(count);
      } else {
        FlutterAppBadger.removeBadge();
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final ws = WebSocketService();
    return StreamBuilder<int>(
      stream: ws.unreadCountStream,
      initialData: ws.unreadCount,
      builder: (context, snapshot) {
        final unreadCount = snapshot.data ?? 0;

        if (unreadCount != _lastBadgeCount) {
          _lastBadgeCount = unreadCount;
          _updateAppIconBadge(unreadCount);
        }

        return Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: widget.onTap,
            ),
            if (unreadCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  child: Text(
                    unreadCount > 99 ? '99+' : unreadCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
