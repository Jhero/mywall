// lib/services/gallery_service.dart
// Contoh modifikasi untuk mendukung pagination

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/gallery.dart';
import '../models/gallery_response.dart';
import '../config/env_config.dart';

class GalleryService {
  static String get baseUrl => EnvConfig.baseUrl;
  static String get apiKey => EnvConfig.apiKey;

  static Future<GalleryResponse> fetchGalleries({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final url = '$baseUrl/api/galleries?page=$page&limit=$limit';
      // print('Fetching galleries from: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'X-API-Key': apiKey,
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      // print('Galleries response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // langsung gunakan model
        final galleryResponse = GalleryResponse.fromJson(data);
        return galleryResponse;
      } else if(response.statusCode == 204) {
        // 🔥 TIDAK ERROR — DATA HABIS
        return GalleryResponse(
          galleries: [],
          status: true,
          message: 'No more galleries available',
          pagination: Pagination(
            totalItems: 0,
            currentPage: page,
            hasNext: false,
            hasPrevious: false,
            itemsPerPage: limit,
            totalPages: 0,
          ),
        );
      } else {
        throw Exception('Failed to fetch galleries: ${response.statusCode}');
      }
    } catch (e) {
      // print('Error fetching galleries: $e');
      throw Exception('Failed to load galleries: $e');
    }
  }


  // Search galleries with pagination
  static Future<List<Gallery>> searchGalleries(
    String query, {
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final url = '$baseUrl/api/galleries/search?q=$query&page=$page&limit=$limit';
      // print('Searching galleries from: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'X-API-Key': apiKey,
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      // print('Search galleries response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        List<Map<String, dynamic>> galleriesData = [];
        
        // Handle different API response structures
        if (data is List) {
          galleriesData = List<Map<String, dynamic>>.from(data);
        } else if (data is Map) {
          if (data.containsKey('status') && data['status'] == true) {
            if (data.containsKey('data')) {
              var dataField = data['data'];
              if (dataField is List) {
                galleriesData = List<Map<String, dynamic>>.from(dataField);
              } else if (dataField is Map && dataField.containsKey('data')) {
                galleriesData = List<Map<String, dynamic>>.from(dataField['data']);
              }
            }
          } else if (data.containsKey('galleries')) {
            galleriesData = List<Map<String, dynamic>>.from(data['galleries']);
          } else if (data.containsKey('results')) {
            galleriesData = List<Map<String, dynamic>>.from(data['results']);
          } else if (data.containsKey('data')) {
            var dataField = data['data'];
            if (dataField is List) {
              galleriesData = List<Map<String, dynamic>>.from(dataField);
            }
          }
        }

        // Convert to Gallery objects
        return galleriesData.map((item) => Gallery.fromJson(item)).toList();
        
      } else {
        throw Exception('Failed to search galleries: ${response.statusCode}');
      }
    } catch (e) {
      // print('Error searching galleries: $e');
      throw Exception('Failed to search galleries: $e');
    }
  }

  // Get full image URL
  static String getImageUrl(String imagePath) {
    if (imagePath.startsWith('http')) {
      return imagePath;
    }
    
    // Convert backslashes to forward slashes and remove 'uploads' prefix if present
    String cleanPath = imagePath.replaceAll('\\', '/');
    
    if (cleanPath.startsWith('uploads/')) {
      cleanPath = cleanPath.substring(8);
    }
    
    return '$baseUrl/api/images/$cleanPath';
  }

  // Alternative method: Fetch galleries by category with pagination
  static Future<GalleryResponse> fetchGalleriesByCategory(
    String categoryId, {
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final url = '$baseUrl/api/galleries?category_id=$categoryId&page=$page&limit=$limit';
      // print('Fetching galleries by category from: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'X-API-Key': apiKey,
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      // print('Category galleries response status: ${response}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // langsung gunakan model
        final galleryResponse = GalleryResponse.fromJson(data);
        return galleryResponse;
      } else if (response.statusCode == 204) {
        // 🔥 TIDAK ERROR — DATA HABIS
        return GalleryResponse(
          galleries: [],
          status: true,
          message: 'No more galleries available',
          pagination: Pagination(
            totalItems: 0,
            currentPage: page,
            hasNext: false,
            hasPrevious: false,
            itemsPerPage: limit,
            totalPages: 0,
          ),
        );
      }else {
        throw Exception('Failed to fetch category galleries: ${response.statusCode}');
      }
    } catch (e) {
      // print('Error fetching category galleries: $e');
      throw Exception('Failed to load category galleries: $e');
    }
  }
}
