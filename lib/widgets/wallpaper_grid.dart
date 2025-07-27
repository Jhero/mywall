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

  const WallpaperGrid({
    Key? key,
    this.wallpaperImages,
    this.onWallpaperTap,
    this.useLocalAssets = false,
    this.searchQuery,
  }) : super(key: key);

  @override
  State<WallpaperGrid> createState() => _WallpaperGridState();
}

class _WallpaperGridState extends State<WallpaperGrid> {
  List<Gallery> galleries = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    if (!widget.useLocalAssets) {
      _loadGalleries();
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
      _loadGalleries();
    }
  }

  Future<void> _loadGalleries() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });
      
      List<Gallery> fetchedGalleries;
      if (widget.searchQuery != null && widget.searchQuery!.isNotEmpty) {
        fetchedGalleries = await GalleryService.searchGalleries(widget.searchQuery!);
      } else {
        fetchedGalleries = await GalleryService.fetchGalleries();
      }
      
      setState(() {
        galleries = fetchedGalleries;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  Future<void> _refreshGalleries() async {
    await _loadGalleries();
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
                    'X-API-Key': GalleryService.apiKey, // Replace with your actual API key
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
                        ),
                      ),
                    );
                  },
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
    if (galleries.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text(
            'No galleries found',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      );
    }

    List<Widget> rows = [];
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

      rows.add(
        Row(
          children: [
            leftItem,
            const SizedBox(width: 8),
            rightItem,
          ],
        ),
      );

      if (i + 2 < galleries.length) {
        rows.add(const SizedBox(height: 8));
      }
    }

    return Column(children: rows);
  }

  Widget _buildAssetGrid() {
    if (widget.wallpaperImages == null || widget.wallpaperImages!.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text(
            'No wallpapers found',
            style: TextStyle(fontSize: 16, color: Colors.grey),
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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          if (widget.useLocalAssets)
            _buildAssetGrid()
          else if (isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              ),
            )
          else if (errorMessage != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 48,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      errorMessage!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _refreshGalleries,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          else
            _buildGalleryGrid(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}