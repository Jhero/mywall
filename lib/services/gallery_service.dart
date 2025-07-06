// lib/services/gallery_service.dart
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/gallery.dart';

class GalleryService {
  static const String baseUrl = 'http://localhost:8080/api/gallerieslocalhost';
  static const String apiKey = 'ebe2540a9634855cb916d8b2d7bde2ad2154dd46f4dc3a0727a93a17779a98d8'; // Replace with your actual API key

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
          return (jsonData['data'] as List)
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

  static String getImageUrl(String imageUrl) {
    return '$baseUrl/$imageUrl';
  }
}