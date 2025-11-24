import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart'; // Import package
import '../config/env_config.dart';

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  WebSocketChannel? _webSocketChannel; // Ganti WebSocket dengan WebSocketChannel
  bool _isConnected = false;
  final List<Function(Map<String, dynamic>)> _newGalleryListeners = [];
  final List<Function(Map<String, dynamic>)> _updateGalleryListeners = [];
  final List<Function(Map<String, dynamic>)> _deleteGalleryListeners = [];
  final List<Function()> _connectedListeners = [];
  final List<Function()> _disconnectedListeners = [];

  Timer? _reconnectTimer;
  StreamSubscription? _messageSubscription;

  // Getters
  bool get isConnected => _isConnected;

  // Initialize WebSocket connection
  void initializeWebSocket() {
    _connect();
  }

  void _connect() {
    try {
      final url = EnvConfig.webSocketUrl;
      print('🔄 Connecting to WebSocket: $url');
      
      _webSocketChannel = WebSocketChannel.connect(Uri.parse(url));
      _isConnected = true;
      print('✅ WebSocket connected successfully');

      // Notify connected listeners
      for (var listener in _connectedListeners) {
        listener();
      }

      // Setup message handler
      _messageSubscription = _webSocketChannel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDisconnect,
      );

      // Join galleries room
      _sendMessage({
        'type': 'join_galleries',
        'payload': 'join'
      });

    } catch (e) {
      print('❌ WebSocket connection error: $e');
      _scheduleReconnect();
    }
  }

  void _handleMessage(dynamic message) {
    try {
      final data = json.decode(message);
      final type = data['type'];
      final payload = data['payload'];

      print('📨 WebSocket message received: $type');

      switch (type) {
        case 'connected':
          print('✅ WebSocket server connected');
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
          // Handle pong response
          break;
        default:
          print('❓ Unknown WebSocket message type: $type');
      }
    } catch (e) {
      print('❌ WebSocket message parsing error: $e');
    }
  }

  void _handleError(error) {
    print('❌ WebSocket error: $error');
    _handleDisconnect();
  }

  void _handleDisconnect() {
    if (_isConnected) {
      _isConnected = false;
      print('🔌 WebSocket disconnected');
      
      // Notify disconnected listeners
      for (var listener in _disconnectedListeners) {
        listener();
      }
      
      _cleanup();
      _scheduleReconnect();
    }
  }

  void _cleanup() {
    _messageSubscription?.cancel();
    _messageSubscription = null;
    _webSocketChannel?.sink.close();
    _webSocketChannel = null;
  }

  void _scheduleReconnect() {
    if (_reconnectTimer != null) return;
    
    print('🔄 Scheduling WebSocket reconnect in 60 seconds...');
    _reconnectTimer = Timer(Duration(seconds: 60), () {
      _reconnectTimer = null;
      _connect();
    });
  }

  void _sendMessage(Map<String, dynamic> message) {
    if (_isConnected && _webSocketChannel != null) {
      try {
        _webSocketChannel!.sink.add(json.encode(message));
      } catch (e) {
        print('❌ WebSocket send error: $e');
        _handleDisconnect();
      }
    }
  }

  // Ping server (optional)
  void ping() {
    _sendMessage({'type': 'ping', 'payload': 'ping'});
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

  void addConnectedListener(Function() listener) {
    _connectedListeners.add(listener);
  }

  void addDisconnectedListener(Function() listener) {
    _disconnectedListeners.add(listener);
  }

  // Notify listeners
  void _notifyNewGalleryListeners(Map<String, dynamic> data) {
    for (var listener in _newGalleryListeners) {
      listener(data);
    }
  }

  void _notifyUpdateGalleryListeners(Map<String, dynamic> data) {
    for (var listener in _updateGalleryListeners) {
      listener(data);
    }
  }

  void _notifyDeleteGalleryListeners(Map<String, dynamic> data) {
    for (var listener in _deleteGalleryListeners) {
      listener(data);
    }
  }

  // Disconnect WebSocket
  void disconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _cleanup();
    _isConnected = false;
    _newGalleryListeners.clear();
    _updateGalleryListeners.clear();
    _deleteGalleryListeners.clear();
    _connectedListeners.clear();
    _disconnectedListeners.clear();
  }
}