import 'package:flutter/material.dart';
import '../../services/favorites_manager.dart';
import '../../services/gallery_service.dart';
import '../../models/gallery.dart';
import 'wallpaper_detail_screen.dart';
import 'package:http/http.dart' as http;

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({Key? key}) : super(key: key);

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final FavoritesManager _favoritesManager = FavoritesManager();
  List<String> _favorites = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    // Tunggu sedikit untuk memastikan SharedPreferences terinisialisasi
    await Future.delayed(const Duration(milliseconds: 100));
    
    // Dapatkan favorites terbaru
    _favorites = _favoritesManager.getAllFavorites();
    
    // Tambahkan listener
    _favoritesManager.addListener(_onFavoritesChanged);
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _favoritesManager.removeListener(_onFavoritesChanged);
    super.dispose();
  }

  void _onFavoritesChanged() {
    if (mounted) {
      setState(() {
        _favorites = _favoritesManager.getAllFavorites();
      });
    }
  }

  // Check if the image is a local asset (starts with 'assets/')
  bool _isLocalAsset(String imagePath) {
    return imagePath.startsWith('assets/');
  }

  // Get the display name for the image
  String _getDisplayName(String imagePath) {
    if (_isLocalAsset(imagePath)) {
      return imagePath.split('/').last.split('.').first.toUpperCase();
    } else {
      // For API images, try to extract a meaningful name
      final uri = Uri.tryParse(imagePath);
      if (uri != null) {
        final pathSegments = uri.pathSegments;
        if (pathSegments.isNotEmpty) {
          final lastSegment = pathSegments.last;
          if (lastSegment.contains('.')) {
            return lastSegment.split('.').first.toUpperCase();
          }
          return lastSegment.toUpperCase();
        }
      }
      return 'Wallpaper';
    }
  }

  Widget _buildFavoriteItem(String wallpaper) {
    return GestureDetector(
      onTap: () {
        if (_isLocalAsset(wallpaper)) {
          // Navigate to detail screen for local asset
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => WallpaperDetailScreen.fromAsset(
                imagePath: wallpaper,
                onFavoriteChanged: _onFavoritesChanged,
              ),
            ),
          );
        } else {
          // For API images, create a Gallery object from the stored URL
          final gallery = Gallery(
            id: wallpaper.hashCode, // Use hash as ID (int)
            title: "",
            description: 'Favorite wallpaper',
            imageUrl: wallpaper,
            categoryId: 1, // Default category ID
            userId: 1, // Default user ID
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => WallpaperDetailScreen.fromGallery(
                gallery: gallery,
                onFavoriteChanged: _onFavoritesChanged,
              ),
            ),
          );
        }
      },
      child: Hero(
        tag: 'favorite_$wallpaper',
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
              ),
              child: _isLocalAsset(wallpaper)
                  ? Image.asset(
                      wallpaper,
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
                    )
                  : FutureBuilder<http.Response>(
                      future: http.get(
                        Uri.parse(GalleryService.getImageUrl(wallpaper)),
                        headers: {
                          'X-API-Key': GalleryService.apiKey,
                        },
                      ),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Container(
                            color: Colors.grey[300],
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          );
                        } else if (snapshot.hasError || 
                                   snapshot.data?.statusCode != 200) {
                          return Container(
                            color: Colors.grey[300],
                            child: const Icon(
                              Icons.error,
                              color: Colors.red,
                              size: 50,
                            ),
                          );
                        } else {
                          return Image.memory(
                            snapshot.data!.bodyBytes,
                            fit: BoxFit.cover,
                          );
                        }
                      },
                    ),
            ),
            // Remove from favorites button
            Positioned(
              top: 8,
              right: 8,
              child: CircleAvatar(
                backgroundColor: Colors.black54,
                radius: 16,
                child: IconButton(
                  icon: const Icon(Icons.favorite, color: Colors.red, size: 18),
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    _favoritesManager.removeFavorite(wallpaper);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Favorite Wallpapers',
          style: TextStyle(
            color: Theme.of(context).appBarTheme.foregroundColor ?? Theme.of(context).colorScheme.onSurface,
          ),
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: Theme.of(context).appBarTheme.elevation ?? 0,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        actions: [
          if (_favorites.isNotEmpty && !_isLoading)
            IconButton(
              icon: Icon(Icons.delete_outline, color: Theme.of(context).appBarTheme.foregroundColor),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Clear All Favorites'),
                    content: const Text('Are you sure you want to remove all favorites?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () async {
                          await _favoritesManager.clearAllFavorites();
                          Navigator.pop(context);
                        },
                        child: const Text('Clear', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _favorites.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.favorite_border,
                        size: 64,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                      ),
                      SizedBox(height: 20),
                      Text(
                        'No favorites yet',
                        style: TextStyle(
                          fontSize: 18,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Like wallpapers to add them here',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: _favorites.length,
                  itemBuilder: (context, index) {
                    final wallpaper = _favorites[index];
                    return _buildFavoriteItem(wallpaper);
                  },
                ),
    );
  }
}
