import 'gallery.dart';
import 'dart:convert';

class GalleryResponse {
  final bool status;
  final String message;
  final List<Gallery> galleries;
  final Pagination pagination;

  GalleryResponse({
    required this.status,
    required this.message,
    required this.galleries,
    required this.pagination,
  });

  factory GalleryResponse.fromJson(Map<String, dynamic> json) {    
    print('jsonku:\n${const JsonEncoder.withIndent('  ').convert(json)}');
    final dataField = json['data'];
    List<dynamic> rawList = [];

    // Sesuai screenshot: data -> { data: [ ... ] }
    if (dataField is Map && dataField['data'] is List) {
      rawList = dataField['data'] as List;
    }

    final galleriesList = rawList
        .whereType<Map<String, dynamic>>()
        .map((e) => Gallery.fromJson(e))
        .toList();

    return GalleryResponse(
      // Jika tidak ada 'status' di response, fallback ke true
      status: (json['status'] is bool) ? json['status'] as bool : true,
      message: json['message'] ?? '',
      pagination: (json['pagination'] is Map<String, dynamic>)
          ? Pagination.fromJson(json['data']['pagination'] as Map<String, dynamic>)
          : Pagination(
              currentPage: 1,
              hasNext: false,
              hasPrevious: false,
              itemsPerPage: galleriesList.length,
              totalItems: (json['data']['pagination'] != null && json['data']['pagination']['total_items'] != null)
                ? json['data']['pagination']['total_items'] as int
                : 0,
              totalPages: 1,
            ),
      galleries: galleriesList,
    );
  }
}

class Pagination {
  final int currentPage;
  final bool hasNext;
  final bool hasPrevious;
  final int itemsPerPage;
  final int totalItems;
  final int totalPages;

  Pagination({
    required this.currentPage,
    required this.hasNext,
    required this.hasPrevious,
    required this.itemsPerPage,
    required this.totalItems,
    required this.totalPages,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      currentPage: json['current_page'] ?? 1,
      hasNext: json['has_next'] ?? false,
      hasPrevious: json['has_previous'] ?? false,
      itemsPerPage: json['items_per_page'] ?? 0,
      totalItems: json['total_items'] ?? 0,
      totalPages: json['total_pages'] ?? 1,
    );
  }
}
