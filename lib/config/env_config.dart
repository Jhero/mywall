import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  static String get baseUrl => dotenv.env['BASE_URL'] ?? 'http://192.168.1.5:8080';
  static String get apiKey => dotenv.env['API_KEY'] ?? 'ebe2540a9634855cb916d8b2d7bde2ad2154dd46f4dc3a0727a93a17779a98d8';
  
  // Method untuk mendapatkan WebSocket URL
  static String get webSocketUrl {
    String url = dotenv.env['BASE_URL'] ?? 'http://192.168.1.5:8080';
    
    // Convert http -> ws, https -> wss
    if (url.startsWith('https://')) {
      return url.replaceFirst('https://', 'wss://') + '/ws';
    } else {
      return url.replaceFirst('http://', 'ws://') + '/ws';
    }
  }
  
  static Future<void> load() async {
    await dotenv.load(fileName: ".env");
  }
}