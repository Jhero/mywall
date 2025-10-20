import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter/foundation.dart';
import '../config/env_config.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? _socket;
  bool _isConnected = false;
  final List<Function(Map<String, dynamic>)> _newGalleryListeners = [];
  final List<Function(Map<String, dynamic>)> _updateGalleryListeners = [];
  final List<Function(Map<String, dynamic>)> _deleteGalleryListeners = [];

  // Getters
  bool get isConnected => _isConnected;
  IO.Socket? get socket => _socket;

  // Initialize socket connection
  void initializeSocket() {
    try {
      _socket = IO.io(
        EnvConfig.baseUrl,
        IO.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .setExtraHeaders({'X-API-Key': EnvConfig.apiKey})
          .build(),
      );

      // Socket event handlers
      _socket!.onConnect((_) {
        _isConnected = true;
        print('✅ Socket connected successfully');
        
        // Join gallery room/channel
        _socket!.emit('join_galleries');
      });

      _socket!.onDisconnect((_) {
        _isConnected = false;
        print('❌ Socket disconnected');
      });

      _socket!.onError((error) {
        print('❌ Socket error: $error');
      });

      _socket!.onConnectError((error) {
        print('❌ Socket connect error: $error');
      });

      // Gallery events
      _socket!.on('new_gallery', (data) {
        print('🆕 New gallery received: $data');
        _notifyNewGalleryListeners(data);
      });

      _socket!.on('update_gallery', (data) {
        print('📝 Gallery updated: $data');
        _notifyUpdateGalleryListeners(data);
      });

      _socket!.on('delete_gallery', (data) {
        print('🗑️ Gallery deleted: $data');
        _notifyDeleteGalleryListeners(data);
      });

      _socket!.connect();

    } catch (e) {
      print('Error initializing socket: $e');
    }
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

  // Manual emit events (jika diperlukan)
  void emitNewGallery(Map<String, dynamic> galleryData) {
    _socket?.emit('new_gallery', galleryData);
  }

  void emitUpdateGallery(Map<String, dynamic> galleryData) {
    _socket?.emit('update_gallery', galleryData);
  }

  void emitDeleteGallery(String galleryId) {
    _socket?.emit('delete_gallery', {'id': galleryId});
  }

  // Disconnect socket
  void disconnect() {
    _socket?.disconnect();
    _isConnected = false;
    _newGalleryListeners.clear();
    _updateGalleryListeners.clear();
    _deleteGalleryListeners.clear();
  }
}