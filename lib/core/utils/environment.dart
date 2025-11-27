import 'package:flutter_dotenv/flutter_dotenv.dart';

class Environment {
  static String get baseUrl => dotenv.env['BASE_URL'] ?? 'http://192.168.1.7:8080';
  static String get apiKey => dotenv.env['API_KEY'] ?? 'ebe2540a9634855cb916d8b2d7bde2ad2154dd46f4dc3a0727a93a17779a98d8';
  
  // Method untuk mendapatkan WebSocket URL
  static String get webSocketUrl {
    String url = dotenv.env['BASE_URL'] ?? 'http://192.168.1.7:8080';
    
    // Convert http -> ws, https -> wss
    if (url.startsWith('https://')) {
      return url.replaceFirst('https://', 'wss://') + '/ws';
    } else {
      return url.replaceFirst('http://', 'ws://') + '/ws';
    }
  }

//   static const String admobAppId = String.fromEnvironment('ADMOB_APP_ID');
//   static const String admobBannerId = String.fromEnvironment('ADMOB_BANNER_ID');
//   static const String admobInterstitialId = String.fromEnvironment('ADMOB_INTERSTITIAL_ID');
//   static const String admobRewardedId = String.fromEnvironment('ADMOB_REWARDED_ID');
//   static const String admobNativeId = String.fromEnvironment('ADMOB_NATIVE_ID');

  static Future<void> load() async {
    await dotenv.load(fileName: ".env");

    // Untuk development, bisa load dari assets atau .env file
    // Untuk production, gunakan --dart-define dari command line
  }
}