import 'package:flutter/services.dart';
import 'dart:convert';

class AgeVerificationService {
  static const platform = MethodChannel('com.myjovan.mywall/age_signals');

  /// Mendapatkan informasi age signals dari native Android
  static Future<Map<String, dynamic>> getAgeSignals() async {
    try {
      final result = await platform.invokeMethod<Map>('getAgeSignals');
      
      if (result != null) {
        // Convert Map<Object?, Object?> to Map<String, dynamic>
        final Map<String, dynamic> ageData = Map<String, dynamic>.from(result);
        return ageData;
      }
      
      return _getDefaultAgeSignals();
    } on PlatformException catch (e) {
      print("✗ PlatformException getting age signals: ${e.message}");
      return _getDefaultAgeSignals();
    } catch (e) {
      print("✗ Error getting age signals: $e");
      return _getDefaultAgeSignals();
    }
  }

  /// Default age signals jika gagal mendapatkan dari native
  static Map<String, dynamic> _getDefaultAgeSignals() {
    return {
      "under13": false,
      "parentalSupervision": false,
      "ageRange": "UNKNOWN"
    };
  }

  /// Check apakah user di bawah 13 tahun
  static bool isUnder13(Map<String, dynamic> ageSignals) {
    return ageSignals["under13"] == true;
  }

  /// Check apakah user dalam pengawasan orang tua
  static bool isUnderParentalSupervision(Map<String, dynamic> ageSignals) {
    return ageSignals["parentalSupervision"] == true;
  }

  /// Get age range sebagai string
  static String getAgeRange(Map<String, dynamic> ageSignals) {
    return ageSignals["ageRange"]?.toString() ?? "UNKNOWN";
  }
}