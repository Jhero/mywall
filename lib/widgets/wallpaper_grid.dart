// lib/widgets/wallpaper_grid.dart
import 'package:flutter/material.dart';
import '../models/gallery.dart';
import '../services/gallery_service.dart';
import '../services/favorites_manager.dart';
import '../screens/wallpaper_detail_screen.dart';

class WallpaperGrid extends StatefulWidget {
  final List<String>? wallpaperImages; // For local assets
  final Function(String)? onWallpaperTap; // Callback for asset tap
  final bool useLocalAssets; // Flag to determine data source
  final String? searchQuery; // Search query for API galleries
  final VoidCallback? onRefresh; // NEW: Callback for parent refresh

  const WallpaperGrid({
    Key? key,
    this.wallpaperImages,
    this.onWallpaperTap,
    this.useLocalAssets = false,
    this.searchQuery,
    this.onRefresh, // NEW: Added parameter
  }) : super(key: key);

  @override
  State<WallpaperGrid> createState() => _WallpaperGridState();
}

class _WallpaperGridState extends State<WallpaperGrid> {
  final ScrollController _scrollController = ScrollController();
  
  List<Gallery> galleries = [];
  bool isLoading = true;
  bool isLoadingMore = false;
  bool hasMoreData = true;
  String? errorMessage;
  String? currentSearchQuery;
  
  // Pagination
  int currentPage = 1;
  int itemsPerPage = 20;

  @override
  void initState() {
    super.initState();
    currentSearchQuery = widget.searchQuery;
    
    if (!widget.useLocalAssets) {
      _loadGalleries();
      _setupScrollListener();
    } else {
      isLoading = false;
    }
  }

  @override
  void didUpdateWidget(WallpaperGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.useLocalAssets && 
        (oldWidget.searchQuery != widget.searchQuery || 
         oldWidget.useLocalAssets != widget.useLocalAssets)) {
      currentSearchQuery = widget.searchQuery;
      _resetAndLoadGalleries();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // Setup scroll listener for lazy loading
  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= 
          _scrollController.position.maxScrollExtent - 200) {
        // Load more data when user is 200 pixels away from bottom
        _loadMoreGalleries();
      }
    });
  }

  // Reset data and fetch from beginning
  void _resetAndLoadGalleries() {
    setState(() {
      currentPage = 1;
      hasMoreData = true;
      galleries.clear();
    });
    _loadGalleries();
  }

  Future<void> _loadGalleries({bool isRefresh = false}) async {
    if (!mounted) return;
    
    if (isRefresh) {
      setState(() {
        currentPage = 1;
        hasMoreData = true;
        galleries.clear();
      });
    }

    try {
      setState(() {
        if (isRefresh || currentPage == 1) {
          isLoading = true;
        } else {
          isLoadingMore = true;
        }
        errorMessage = null;
      });
      
      List<Gallery> fetchedGalleries;
      
      // Call API with pagination
      if (currentSearchQuery != null && currentSearchQuery!.isNotEmpty) {
        fetchedGalleries = await GalleryService.searchGalleries(
          currentSearchQuery!,
          page: currentPage,
          limit: itemsPerPage,
        );
      } else {
        fetchedGalleries = await GalleryService.fetchGalleries(
          page: currentPage,
          limit: itemsPerPage,
        );
      }
      
      // Check if we have more data
      if (fetchedGalleries.length < itemsPerPage) {
        hasMoreData = false;
      }
      
      setState(() {
        if (isRefresh || currentPage == 1) {
          galleries = fetchedGalleries;
        } else {
          galleries.addAll(fetchedGalleries);
        }
        isLoading = false;
        isLoadingMore = false;
      });

      print('Successfully loaded ${fetchedGalleries.length} galleries (Page: $currentPage)');
      
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
        isLoadingMore = false;
        
        // Set fallback galleries only if we don't have any data
        if (galleries.isEmpty) {
          hasMoreData = false;
        }
      });
      
      print('Error loading galleries: $e');
    }
  }

  // Load more galleries for pagination
  Future<void> _loadMoreGalleries() async {
    if (isLoadingMore || !hasMoreData || isLoading || widget.useLocalAssets) return;

    currentPage++;
    await _loadGalleries();
  }

  // Pull to refresh function - UPDATED: Call parent callback
  Future<void> _refreshGalleries() async {
    await _loadGalleries(isRefresh: true);
    
    // NEW: Notify parent about the refresh
    if (widget.onRefresh != null) {
      widget.onRefresh!();
    }
  }

  // NEW: Public method to trigger refresh from parent
  Future<void> refresh() async {
    await _refreshGalleries();
  }

  Widget _buildWallpaperItem(Gallery gallery, {double ratio = 16/9}) {
    // Check if this wallpaper is favorited
    final bool isFavorite = FavoritesManager().isFavorite(gallery.imageUrl);
    
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WallpaperDetailScreen.fromGallery(gallery: gallery),
          ),
        );
      },
      child: AspectRatio(
        aspectRatio: ratio,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  GalleryService.getImageUrl(gallery.imageUrl),
                  fit: BoxFit.cover,
                  headers: {
                    'X-API-Key': GalleryService.apiKey,
                  },
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
                          strokeWidth: 2,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[300],
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.image_not_supported,
                            color: Colors.grey,
                            size: 32,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Image not available',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                // Gradient overlay for better text readability
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.3),
                      ],
                    ),
                  ),
                ),
                // Favorite icon
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isFavorite) {
                          FavoritesManager().removeFavorite(gallery.imageUrl);
                        } else {
                          FavoritesManager().addFavorite(gallery.imageUrl);
                        }
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite ? Colors.red : Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
                // Title overlay
                Positioned(
                  bottom: 8,
                  left: 8,
                  right: 8,
                  child: Text(
                    gallery.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          offset: Offset(0, 1),
                          blurRadius: 3,
                          color: Colors.black45,
                        ),
                      ],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAssetWallpaperItem(String imagePath, {double ratio = 16/9}) {
    // Check if this wallpaper is favorited
    final bool isFavorite = FavoritesManager().isFavorite(imagePath);
    
    return GestureDetector(
      onTap: () {
        if (widget.onWallpaperTap != null) {
          widget.onWallpaperTap!(imagePath);
        }
      },
      child: AspectRatio(
        aspectRatio: ratio,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  imagePath,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[300],
                      child: const Icon(
                        Icons.error,
                        color: Colors.red,
                        size: 50,
                      ),
                    );
                  },
                ),
                // Gradient overlay for better text readability
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.3),
                      ],
                    ),
                  ),
                ),
                // Favorite icon
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isFavorite) {
                          FavoritesManager().removeFavorite(imagePath);
                        } else {
                          FavoritesManager().addFavorite(imagePath);
                        }
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite ? Colors.red : Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
                // Title overlay
                Positioned(
                  bottom: 8,
                  left: 8,
                  right: 8,
                  child: Text(
                    imagePath.split('/').last.split('.').first.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          offset: Offset(0, 1),
                          blurRadius: 3,
                          color: Colors.black45,
                        ),
                      ],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGalleryGrid() {
    if (galleries.isEmpty && !isLoading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Icon(
                Icons.image_not_supported, 
                size: 64, 
                color: Colors.grey
              ),
              const SizedBox(height: 16),
              const Text(
                'No galleries found',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Text(
                currentSearchQuery != null 
                    ? 'Try a different search term' 
                    : 'Pull to refresh or try again',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              if (!widget.useLocalAssets) ...[
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => _loadGalleries(isRefresh: true),
                  child: const Text('Refresh'),
                ),
              ],
            ],
          ),
        ),
      );
    }

    List<Widget> items = [];
    
    // Add gallery items
    for (int i = 0; i < galleries.length; i += 2) {
      Widget leftItem = Expanded(
        child: _buildWallpaperItem(
          galleries[i],
          ratio: i % 4 == 0 ? 16/9 : 9/16, // Alternate ratios
        ),
      );

      Widget rightItem = i + 1 < galleries.length
          ? Expanded(
              child: _buildWallpaperItem(
                galleries[i + 1],
                ratio: i % 4 == 0 ? 9/16 : 16/9, // Alternate ratios
              ),
            )
          : const Expanded(child: SizedBox());

      items.add(
        Row(
          children: [
            leftItem,
            const SizedBox(width: 8),
            rightItem,
          ],
        ),
      );

      if (i + 2 < galleries.length || isLoadingMore || !hasMoreData) {
        items.add(const SizedBox(height: 8));
      }
    }

    // Add loading indicator at bottom
    if (isLoadingMore) {
      items.add(
        Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Text('Loading more galleries...'),
            ],
          ),
        ),
      );
    }

    // Add end indicator
    if (!hasMoreData && galleries.isNotEmpty) {
      items.add(
        Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: const Text(
            '✨ You\'ve reached the end! ✨',
            style: TextStyle(
              color: Colors.grey,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Column(children: items);
  }

  Widget _buildAssetGrid() {
    if (widget.wallpaperImages == null || widget.wallpaperImages!.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(Icons.image_not_supported, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'No wallpapers found',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    List<Widget> rows = [];
    final images = widget.wallpaperImages!;
    
    for (int i = 0; i < images.length; i += 2) {
      Widget leftItem = Expanded(
        child: _buildAssetWallpaperItem(
          images[i],
          ratio: i % 4 == 0 ? 16/9 : 9/16, // Alternate ratios
        ),
      );

      Widget rightItem = i + 1 < images.length
          ? Expanded(
              child: _buildAssetWallpaperItem(
                images[i + 1],
                ratio: i % 4 == 0 ? 9/16 : 16/9, // Alternate ratios
              ),
            )
          : const Expanded(child: SizedBox());

      rows.add(
        Row(
          children: [
            leftItem,
            const SizedBox(width: 8),
            rightItem,
          ],
        ),
      );

      if (i + 2 < images.length) {
        rows.add(const SizedBox(height: 8));
      }
    }

    return Column(children: rows);
  }

  Widget _buildContent() {
    if (widget.useLocalAssets) {
      return _buildAssetGrid();
    } else if (isLoading && galleries.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading galleries...'),
            ],
          ),
        ),
      );
    } else if (errorMessage != null && galleries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to load galleries',
                style: TextStyle(
                  color: Colors.red[600],
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                errorMessage!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _loadGalleries(isRefresh: true),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    } else {
      return _buildGalleryGrid();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Content with RefreshIndicator for API galleries
          if (!widget.useLocalAssets)
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refreshGalleries,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: _buildContent(),
                ),
              ),
            )
          else
            Expanded(child: _buildContent()),
            
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}