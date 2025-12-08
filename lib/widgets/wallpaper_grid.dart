import 'package:flutter/material.dart';
import 'dart:async';
import '../services/gallery_service.dart';
import '../models/gallery.dart';
import '../presentation/screens/wallpaper_detail_screen.dart';
import '../services/websocket_service.dart';

class WallpaperGrid extends StatefulWidget {
  final String? searchQuery;
  final String? categoryId;
  final bool useLocalAssets;
  final Future<void> Function()? onRefresh;
  final Stream<dynamic>? updateStream; // Changed from Stream<bool> to Stream<dynamic>

  const WallpaperGrid({
    Key? key,
    this.searchQuery,
    this.categoryId,
    this.useLocalAssets = false,
    this.onRefresh,
    this.updateStream,
  }) : super(key: key);

  @override
  _WallpaperGridState createState() => _WallpaperGridState();
}

class _WallpaperGridState extends State<WallpaperGrid> {
  List<Gallery> galleries = [];
  bool isLoading = true;
  bool isLoadingMore = false;
  String? errorMessage;
  
  // Pagination variables
  int _currentPage = 1;
  final int _limit = 20;
  bool _hasMore = true;
  final ScrollController _scrollController = ScrollController();

  final WebSocketService _webSocketService = WebSocketService();
  StreamSubscription? _updateSubscription;

  @override
  void initState() {
    super.initState();
    _loadGalleries();
    _setupWebSocketListeners();
    
    _scrollController.addListener(_onScroll);
    
    if (widget.updateStream != null) {
      _updateSubscription = widget.updateStream!.listen((data) {
        _handleExternalUpdate(data);
      });
    }
  }

  @override
  void didUpdateWidget(WallpaperGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    print('🔍 widget-3: "${widget}"');
    print('🔍 oldWidget-3: "${oldWidget}"');
    // Jika searchQuery atau categoryId berubah, reset dan load ulang data
    if (widget.searchQuery != oldWidget.searchQuery || 
        widget.categoryId != oldWidget.categoryId) {
       print('🎯 Category changed to: ${widget.categoryId}');   
      _resetPagination();
      _loadGalleries();
    }
  }

  @override
  void dispose() {
    _webSocketService.removeNewGalleryListener(_handleWebSocketNewGallery);
    _webSocketService.removeUpdateGalleryListener(_handleWebSocketUpdateGallery);
    _webSocketService.removeDeleteGalleryListener(_handleWebSocketDeleteGallery);
    _scrollController.dispose();
    _updateSubscription?.cancel();
    super.dispose();
  }

  void _setupWebSocketListeners() {
    _webSocketService.addNewGalleryListener(_handleWebSocketNewGallery);
    _webSocketService.addUpdateGalleryListener(_handleWebSocketUpdateGallery);
    _webSocketService.addDeleteGalleryListener(_handleWebSocketDeleteGallery);
  }

  void _handleWebSocketNewGallery(Map<String, dynamic> galleryData) {
    print('🆕 WebSocket: New gallery received in WallpaperGrid');
    
    // Jika tidak sedang search/filter tertentu, tambahkan gallery baru
    if (widget.searchQuery == null && widget.categoryId == null) {
      try {
        final newGallery = Gallery.fromJson(galleryData);
        
        if (mounted) {
          setState(() {
            // Tambahkan di awal list untuk menunjukkan yang terbaru
            galleries.insert(0, newGallery);
          });
        }
      } catch (e) {
        print('Error handling new gallery in WallpaperGrid: $e');
      }
    }
  }

  void _handleWebSocketUpdateGallery(Map<String, dynamic> galleryData) {
    print('📝 WebSocket: Gallery updated in WallpaperGrid');
    
    try {
      final updatedGallery = Gallery.fromJson(galleryData);
      final galleryId = updatedGallery.id?.toString();
      
      if (galleryId != null && mounted) {
        setState(() {
          final index = galleries.indexWhere((g) => g.id?.toString() == galleryId);
          if (index != -1) {
            galleries[index] = updatedGallery;
          }
        });
      }
    } catch (e) {
      print('Error handling updated gallery in WallpaperGrid: $e');
    }
  }

  void _handleWebSocketDeleteGallery(Map<String, dynamic> galleryData) {
    print('🗑️ WebSocket: Gallery deleted in WallpaperGrid');
    
    try {
      final deletedId = galleryData['id']?.toString();
      
      if (deletedId != null && mounted) {
        setState(() {
          galleries.removeWhere((gallery) => gallery.id?.toString() == deletedId);
        });
      }
    } catch (e) {
      print('Error handling deleted gallery in WallpaperGrid: $e');
    }
  }

  void _handleExternalUpdate(dynamic data) {
    print('WallpaperGrid: Received external update signal: $data');
    
    if (data is Map) {
      if (data['type'] == 'galleries_data') {
        // Handle galleries data from external source
        _handleExternalGalleriesData(data['data'], data['category_id']);
      } else if (data['type'] == 'refresh') {
        // Refresh data
        _refreshGalleries();
      }
    } else if (data == true) {
      // Backward compatibility
      _refreshGalleries();
    }
  }

  void _handleExternalGalleriesData(List<Map<String, dynamic>> galleriesData, String? categoryId) {
    try {
      final loadedGalleries = galleriesData.map((data) => Gallery.fromJson(data)).toList();
      
      if (mounted) {
        setState(() {
          galleries = loadedGalleries;
          isLoading = false;
          _hasMore = false; // External data biasanya tidak support pagination
          errorMessage = null;
        });
      }
      
      print('Successfully loaded ${loadedGalleries.length} galleries from external source');
    } catch (e) {
      print('Error handling external galleries data: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
          errorMessage = 'Failed to load galleries data';
        });
      }
    }
  }

  void _resetPagination() {
    setState(() {
      _currentPage = 1;
      _hasMore = true;
      galleries.clear();
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels == 
        _scrollController.position.maxScrollExtent) {
      if (_hasMore && !isLoadingMore) {
        _loadMoreGalleries();
      }
    }
  }

  Future<void> _loadGalleries({bool silent = false}) async {
    if (!silent) {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });
    }

    try {
      List<Gallery> loadedGalleries;
      if (widget.searchQuery != null && widget.searchQuery!.isNotEmpty) {
        // Load galleries by category
        loadedGalleries = await GalleryService.fetchGalleriesByCategory(
          widget.searchQuery!,
          page: _currentPage,
          limit: _limit,
        );
      } else if (widget.searchQuery != null && widget.searchQuery!.isNotEmpty) {
        // print('Loading galleries by search: ${widget.searchQuery}');
        // Load galleries by search (jika ada)
        loadedGalleries = await GalleryService.fetchGalleries(
          page: _currentPage,
          limit: _limit,
        );
        // Filter by search query locally
        loadedGalleries = loadedGalleries.where((gallery) => 
          gallery.title?.toLowerCase().contains(widget.searchQuery!.toLowerCase()) ?? false
        ).toList();
      } else {
        print('Loading all galleries');
        // Load all galleries
        loadedGalleries = await GalleryService.fetchGalleries(
          page: _currentPage,
          limit: _limit,
        );
      }

      if (mounted) {
        setState(() {
          galleries = loadedGalleries;
          isLoading = false;
          _hasMore = loadedGalleries.length == _limit;
          errorMessage = null;
        });
      }

      print('Successfully loaded ${loadedGalleries.length} galleries');
      
    } catch (e) {
      print('Error loading galleries: $e');
      if (mounted && !silent) {
        setState(() {
          isLoading = false;
          errorMessage = 'Failed to load galleries: ${e.toString()}';
        });
      }
    }
  }

  Future<void> _loadMoreGalleries() async {
    if (isLoadingMore || !_hasMore) return;

    setState(() {
      isLoadingMore = true;
    });

    try {
      final nextPage = _currentPage + 1;
      List<Gallery> newGalleries;
      // print('Loading more galleries for category1: ${widget.searchQuery}');
      if (widget.searchQuery != null && widget.searchQuery!.isNotEmpty) {
        // print('Loading more galleries for category: ${widget.searchQuery}');
        newGalleries = await GalleryService.fetchGalleriesByCategory(
          widget.searchQuery!,
          page: nextPage,
          limit: _limit,
        );
      } else {
      // print('Loading more galleries for category2: ${widget.categoryId}');
        newGalleries = await GalleryService.fetchGalleries(
          page: nextPage,
          limit: _limit,
        );
        
        // Filter by search query jika ada
        if (widget.searchQuery != null && widget.searchQuery!.isNotEmpty) {
          newGalleries = newGalleries.where((gallery) => 
            gallery.title?.toLowerCase().contains(widget.searchQuery!.toLowerCase()) ?? false
          ).toList();
        }
      }

      if (mounted) {
        setState(() {
          galleries.addAll(newGalleries);
          _currentPage = nextPage;
          _hasMore = newGalleries.length == _limit;
          isLoadingMore = false;
        });
      }

      print('Loaded ${newGalleries.length} more galleries');
      
    } catch (e) {
      print('Error loading more galleries: $e');
      if (mounted) {
        setState(() {
          isLoadingMore = false;
        });
      }
    }
  }

  Future<void> _refreshGalleries() async {
    _resetPagination();
    await _loadGalleries(silent: true);
  }

  // Method untuk mendapatkan image URL dengan fallback
  String _getGalleryImageUrl(Gallery gallery) {
    if (gallery.imageUrl != null && gallery.imageUrl!.isNotEmpty) {
      return GalleryService.getImageUrl(gallery.imageUrl!);
    }
    return 'assets/default_wallpaper.png';
  }

  // Method untuk mendapatkan headers dengan API Key
  Map<String, String> _getImageHeaders() {
    return {
      'X-API-Key': GalleryService.apiKey,
    };
  }

  void _onGalleryTap(Gallery gallery) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WallpaperDetailScreen.fromGallery(gallery: gallery),
      ),
    );
  }

  Widget _buildGalleryItem(Gallery gallery) {
    final imageUrl = _getGalleryImageUrl(gallery);
    final isNetworkImage = imageUrl.startsWith('http');

    return GestureDetector(
      onTap: () => _onGalleryTap(gallery),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // Image widget dengan headers untuk network image
            isNetworkImage
                ? Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    headers: _getImageHeaders(),
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: Colors.grey[300],
                        child: Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded / 
                                  loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return _buildErrorWidget();
                    },
                  )
                : Image.asset(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildErrorWidget();
                    },
                  ),
            // Overlay untuk title
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Text(
                  gallery.title ?? 'Untitled',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      color: Colors.grey[300],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.broken_image, color: Colors.grey[600], size: 40),
          SizedBox(height: 8),
          Text(
            'Failed to load',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }

  Widget _buildEmptyState() {
    IconData icon;
    String message;
    
    if (widget.categoryId != null && widget.categoryId!.isNotEmpty) {
      icon = Icons.category;
      message = 'No galleries in this category';
    } else if (widget.searchQuery != null && widget.searchQuery!.isNotEmpty) {
      icon = Icons.search;
      message = 'No galleries found';
    } else {
      icon = Icons.image_not_supported;
      message = 'No galleries available';
    }
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: Colors.grey),
          SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderInfo() {
    String infoText = '${galleries.length} galleries';
    Widget? filterChip;
    
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            infoText,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          if (filterChip != null) filterChip,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading && galleries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(strokeWidth: 2),
            SizedBox(height: 8),
            Text('Loading galleries...'),
          ],
        ),
      );
    }

    if (errorMessage != null && galleries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 48),
            SizedBox(height: 8),
            Text('Failed to load galleries'),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: _loadGalleries,
              child: Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (galleries.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _refreshGalleries,
      child: Column(
        children: [
          // Header info
          _buildHeaderInfo(),
          
          // Grid view
          Expanded(
            child: GridView.builder(
              controller: _scrollController,
              padding: EdgeInsets.all(16),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.7,
              ),
              itemCount: galleries.length + (_hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= galleries.length) {
                  return _buildLoadingIndicator();
                }
                return _buildGalleryItem(galleries[index]);
              },
            ),
          ),
        ],
      ),
    );
  }
}