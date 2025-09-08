// lib/services/gallery_service.dart
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/gallery.dart';
import '../config/env_config.dart';

class GalleryService {
  static String get baseUrl => EnvConfig.baseUrl;
  static String get apiKey => EnvConfig.apiKey;

  static Future<List<Gallery>> fetchGalleries() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/galleries'),
        headers: {
          'X-API-Key': apiKey,
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['status'] == true) {
          return (jsonData['data']['data'] as List)
              .map((item) => Gallery.fromJson(item))
              .toList();
        } else {
          throw Exception(jsonData['message'] ?? 'Failed to fetch galleries');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<List<Gallery>> searchGalleries(String query) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/galleries?category_id=$query'),
        headers: {
          'X-API-Key': apiKey,
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['status'] == true) {
          return (jsonData['data']['data'] as List)
              .map((item) => Gallery.fromJson(item))
              .toList();
        } else {
          throw Exception(jsonData['message'] ?? 'Failed to search galleries');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static String getImageUrl(String imageUrl) {
    String imageCleanUrl = '$baseUrl/api/images/$imageUrl';
    String cleanUrl = imageCleanUrl
    .replaceAll('/uploads', '')
    .replaceAll('\\', '/');
    return cleanUrl;
  }
}