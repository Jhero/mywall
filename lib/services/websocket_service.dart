import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../config/env_config.dart';
import 'package:flutter_app_badger/flutter_app_badger.dart';
import 'package:app_badger/app_badger.dart' as alt_badger;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Timer? _reconnectTimer;
  Timer? _pingTimer;
  final FlutterLocalNotificationsPlugin _flnp = FlutterLocalNotificationsPlugin();
  bool _notificationInitDone = false;

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  // =========================
  // STREAM CONTROLLERS
  // =========================
  final _connectionController = StreamController<bool>.broadcast();
  Stream<bool> get connectionStream => _connectionController.stream;

  final _unreadCountController = StreamController<int>.broadcast();
  Stream<int> get unreadCountStream => _unreadCountController.stream;

  final _notificationController =
      StreamController<List<Map<String, dynamic>>>.broadcast();
  Stream<List<Map<String, dynamic>>> get notificationStream =>
      _notificationController.stream;

  // =========================
  // NOTIFICATION STATE
  // =========================
  int _unreadCount = 0;
  int get unreadCount => _unreadCount;
  final List<Map<String, dynamic>> _notifications = [];
  List<Map<String, dynamic>> get notifications => List.unmodifiable(_notifications);
  
  // =========================
  // GALLERY EVENT LISTENERS
  // =========================
  final List<Function(Map<String, dynamic>)> _newGalleryListeners = [];
  final List<Function(Map<String, dynamic>)> _updateGalleryListeners = [];
  final List<Function(Map<String, dynamic>)> _deleteGalleryListeners = [];

  // =========================
  // CONNECT
  // =========================
  void connect() {
    if (_channel != null) return;

    try {
      final url = EnvConfig.webSocketUrl;
      print('WebSocket connecting to: $url');
      _initLocalNotifications();
      _channel = WebSocketChannel.connect(Uri.parse(url));

      _subscription = _channel!.stream.listen(
        (message) {
          print('Received message: $message');
          print('Received _isConnected: $_isConnected');
          if (!_isConnected) {
            _isConnected = true;
            _connectionController.add(true);
            _startPing();
          }
          _handleMessage(message);
        },
        onError: (error) {
          print('WebSocket error: $error');
          _handleDisconnect();
        },
        onDone: () {
          print('WebSocket closed');
          _handleDisconnect();
        },
        cancelOnError: true,
      );
    } catch (e) {
      print('WebSocket connect exception: $e');
      _scheduleReconnect();
    }
  }

  // =========================
  // HANDLE MESSAGE
  // =========================
  void _handleMessage(dynamic message) {
    try {
      print('Raw message: $message');
      final data = jsonDecode(message);
      print('Received message: $data');
      final type = data['type'];
      final payload = data['payload'];

      switch (type) {
        case 'notification':
          _handleNotification(payload);
          break;
        case 'unread_count':
          _unreadCount = payload ?? 0;
          _unreadCountController.add(_unreadCount);
          _setBadgeCount(_unreadCount);
          break;
        case 'new_gallery':
          _notifyNewGalleryListeners(payload);        
          break;
        case 'update_gallery':
          _notifyUpdateGalleryListeners(payload);
          break;
        case 'delete_gallery':
          _notifyDeleteGalleryListeners(payload);
          break;
        case 'pong':
          break;
      }
    } catch (_) {}
  }

  void _handleNotification(Map<String, dynamic> data) {
    _notifications.insert(0, {
      ...data,
      'is_read': 0,
    });
    _unreadCount++;

    _notificationController.add(List.unmodifiable(_notifications));
    _unreadCountController.add(_unreadCount);
    _setBadgeCount(_unreadCount);
    _showOrCancelBadgeNotification(_unreadCount);
  }

  // Listeners management
  void addNewGalleryListener(Function(Map<String, dynamic>) listener) {
    _newGalleryListeners.add(listener);
  }

  void removeNewGalleryListener(Function(Map<String, dynamic>) listener) {
    _newGalleryListeners.remove(listener);
  }

  void addUpdateGalleryListener(Function(Map<String, dynamic>) listener) {
    _updateGalleryListeners.add(listener);
  }

  void removeUpdateGalleryListener(Function(Map<String, dynamic>) listener) {
    _updateGalleryListeners.remove(listener);
  }

  void addDeleteGalleryListener(Function(Map<String, dynamic>) listener) {
    _deleteGalleryListeners.add(listener);
  }

  void removeDeleteGalleryListener(Function(Map<String, dynamic>) listener) {
    _deleteGalleryListeners.remove(listener);
  }

   // Notify listeners
  void _notifyNewGalleryListeners(Map<String, dynamic> data) {
    print('Notifying new gallery: $data');
    for (var listener in _newGalleryListeners) {
      listener(data);
    }
  }

  void _notifyUpdateGalleryListeners(Map<String, dynamic> data) {
    print('Notifying update gallery: $data');
    for (var listener in _updateGalleryListeners) {
      listener(data);
    }
  }

  void _notifyDeleteGalleryListeners(Map<String, dynamic> data) {
    print('Notifying delete gallery: $data');
    for (var listener in _deleteGalleryListeners) {
      listener(data);
    }
  }

  
  // =========================
  // PING
  // =========================
  void _startPing() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!_isConnected || _channel == null) return;
      try {
        _channel!.sink.add(jsonEncode({'type': 'ping'}));
      } catch (_) {
        _handleDisconnect();
      }
    });
  }

  // =========================
  // READ MANAGEMENT
  // =========================
  void markAsRead(String id) {
    for (var notif in _notifications) {
      if (notif['id'] == id && notif['is_read'] == 0) {
        notif['is_read'] = 1;
        if (_unreadCount > 0) _unreadCount--;
      }
    }
    _notificationController.add(List.unmodifiable(_notifications));
    _unreadCountController.add(_unreadCount);
    _setBadgeCount(_unreadCount);
    _showOrCancelBadgeNotification(_unreadCount);
  }

  void markAllAsRead() {
    for (var notif in _notifications) {
      notif['is_read'] = 1;
    }
    _unreadCount = 0;
    _notificationController.add(List.unmodifiable(_notifications));
    _unreadCountController.add(0);
    _setBadgeCount(0);
    _showOrCancelBadgeNotification(0);
  }

  void clearAll() {
    _notifications.clear();
    _unreadCount = 0;
    _notificationController.add([]);
    _unreadCountController.add(0);
    _setBadgeCount(0);
    _showOrCancelBadgeNotification(0);
  }
  

  // =========================
  // DISCONNECT
  // =========================
  void _handleDisconnect() {
    if (!_isConnected && _channel == null) return;

    _isConnected = false;
    _connectionController.add(false);
    _cleanup();
    _scheduleReconnect();
  }

  void _cleanup() {
    _pingTimer?.cancel();
    _subscription?.cancel();
    _channel?.sink.close();

    _pingTimer = null;
    _subscription = null;
    _channel = null;
  }

  void _scheduleReconnect() {
    if (_reconnectTimer != null) return;

    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      _reconnectTimer = null;
      connect();
    });
  }

  void disconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _cleanup();
    _isConnected = false;
    _connectionController.add(false);
    _setBadgeCount(_unreadCount);
    _showOrCancelBadgeNotification(_unreadCount);
  }

  void dispose() {
    disconnect();
    _connectionController.close();
    _unreadCountController.close();
    _notificationController.close();
  }
  
  void _setBadgeCount(int count) {
    try {
      if (count > 0) {
        // Prefer alt_badger when available; fallback to flutter_app_badger
        alt_badger.AppBadger.updateBadgeCount(count);
        FlutterAppBadger.updateBadgeCount(count);
      } else {
        alt_badger.AppBadger.removeBadge();
        FlutterAppBadger.removeBadge();
      }
    } catch (_) {}
  }

  Future<void> _initLocalNotifications() async {
    if (_notificationInitDone) return;
    try {
      const androidInit = AndroidInitializationSettings('@mipmap/launcher_icon');
      const initSettings = InitializationSettings(android: androidInit);
      await _flnp.initialize(initSettings);
      await _flnp
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();

      _notificationInitDone = true;
    } catch (_) {}
  }

  Future<void> _showOrCancelBadgeNotification(int count) async {
    if (!_notificationInitDone) await _initLocalNotifications();
    try {
      const channelId = 'app_badge_channel';
      const channelName = 'App Badge';
      const channelDesc = 'Badge updates for launcher icons';

      if (count > 0) {
        const androidDetails = AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: channelDesc,
          importance: Importance.low,
          priority: Priority.low,
          playSound: false,
          enableVibration: false,
          ongoing: true,
          autoCancel: false,
          icon: '@mipmap/launcher_icon',
        );
        const notifDetails = NotificationDetails(android: androidDetails);
        await _flnp.show(
          1001,
          'My BTS Idol',
          'You have $count new notifications',
          notifDetails,
        );
      } else {
        await _flnp.cancel(1001);
        await _flnp.cancelAll();
      }
    } catch (_) {}
  }
}
