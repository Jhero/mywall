import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mywall/core/utils/debug_logger.dart';

class Environment {
  // HTTP API
  static String get baseUrl =>
      dotenv.env['BASE_URL'] ?? 'http://192.168.1.5:8080';

  static String get apiKey =>
      dotenv.env['API_KEY'] ??
      'ebe2540a9634855cb916d8b2d7bde2ad2154dd46f4dc3a0727a93a17779a98d8';

  // Websocket URL (http → ws / https → wss)
  static String get webSocketUrl {
    final url = dotenv.env['BASE_URL'] ?? 'http://192.168.1.5:8080';
    if (url.startsWith('https://')) {
      return url.replaceFirst('https://', 'wss://') + '/ws';
    } else {
      return url.replaceFirst('http://', 'ws://') + '/ws';
    }
  }

  // AdMob IDs
  static String get admobAppId =>
      dotenv.env['ADMOB_APP_ID'] ??
      'ca-app-pub-3940256099942544~3347511713';

  static String get admobBannerId =>
      dotenv.env['ADMOB_BANNER_ID'] ??
      'ca-app-pub-3940256099942544/6300978111';

  static String get admobInterstitialId =>
      dotenv.env['ADMOB_INTERSTITIAL_ID'] ??
      'ca-app-pub-3940256099942544/1033173712';

  static String get admobRewardedId =>
      dotenv.env['ADMOB_REWARDED_ID'] ??
      'ca-app-pub-3940256099942544/5224354917';

  static String get admobNativeId =>
      dotenv.env['ADMOB_NATIVE_ID'] ??
      'ca-app-pub-3940256099942544/2247696110';

  // Init dotenv
  static Future<void> load() async {
    try {
      // Your existing environment loading code
      await dotenv.load(fileName: ".env");
      DebugLogger.logAdSuccess('Environment loaded successfully');
    } catch (e) {
      DebugLogger.logAdError('Error loading environment: $e');
      // Set default values or throw if critical
      // throw Exception('Failed to load environment: $e');
    }
  }
}
