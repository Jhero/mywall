import 'package:flutter/material.dart';
import 'dart:async';
import '../services/gallery_service.dart';
import '../models/gallery.dart';
import '../screens/wallpaper_detail_screen.dart';

class WallpaperGrid extends StatefulWidget {
  final String? searchQuery;
  final bool useLocalAssets;
  final Future<void> Function()? onRefresh;
  final Stream<bool>? updateStream;

  const WallpaperGrid({
    Key? key,
    this.searchQuery,
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
  StreamSubscription? _updateSubscription;
  
  // Pagination variables
  int _currentPage = 1;
  final int _limit = 20;
  bool _hasMore = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadGalleries();
    
    // Setup scroll listener untuk infinite scroll
    _scrollController.addListener(_onScroll);
    
    // Listen to update stream jika ada
    if (widget.updateStream != null) {
      _updateSubscription = widget.updateStream!.listen((_) {
        print('WallpaperGrid: Received update signal');
        _refreshGalleries();
      });
    }
  }

  @override
  void didUpdateWidget(WallpaperGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Jika searchQuery berubah, reset dan load ulang data
    if (widget.searchQuery != oldWidget.searchQuery) {
      _resetPagination();
      _loadGalleries();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _updateSubscription?.cancel();
    super.dispose();
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
      } else {
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
      
      if (widget.searchQuery != null && widget.searchQuery!.isNotEmpty) {
        newGalleries = await GalleryService.fetchGalleriesByCategory(
          widget.searchQuery!,
          page: nextPage,
          limit: _limit,
        );
      } else {
        newGalleries = await GalleryService.fetchGalleries(
          page: nextPage,
          limit: _limit,
        );
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
                    GalleryService.getImageUrl(gallery.imageUrl!),
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
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
            SizedBox(height: 8),
            Text(
              widget.searchQuery != null ? 'No galleries found' : 'No galleries available',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshGalleries,
      child: Column(
        children: [
          // Info jumlah gallery
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${galleries.length} galleries',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (widget.searchQuery != null)
                  Chip(
                    label: Text('Category'),
                    backgroundColor: Colors.blue[100],
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
          ),
          
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