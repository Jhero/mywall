import 'package:flutter/foundation.dart';

class DebugLogger {
  static void logAdEvent(String event, {String? adType, dynamic error}) {
    if (kDebugMode) {
      final timestamp = DateTime.now().toIso8601String();
      final adTypeStr = adType != null ? '[$adType] ' : '';
      final errorStr = error != null ? ' - Error: $error' : '';
      debugPrint('🟢 AD_LOGGER $timestamp: $adTypeStr$event$errorStr');
    }
  }

  static void logAdSuccess(String message, {String? adType}) {
    logAdEvent('✅ SUCCESS: $message', adType: adType);
  }

  static void logAdError(String message, {String? adType, dynamic error}) {
    logAdEvent('❌ ERROR: $message', adType: adType, error: error);
  }

  static void logAdLoading(String message, {String? adType}) {
    logAdEvent('⏳ LOADING: $message', adType: adType);
  }
}