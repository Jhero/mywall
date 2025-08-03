import 'package:flutter/material.dart';
import '../services/favorites_manager.dart';
import '../services/gallery_service.dart';
import '../models/gallery.dart';
import 'wallpaper_detail_screen.dart';
import 'package:http/http.dart' as http;

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({Key? key}) : super(key: key);

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  late List<String> favorites;
  late FavoritesManager _favoritesManager;
  
  @override
  void initState() {
    super.initState();
    _favoritesManager = FavoritesManager();
    favorites = _favoritesManager.getAllFavorites();
    _favoritesManager.addListener(_onFavoritesChanged);
  }

  @override
  void dispose() {
    _favoritesManager.removeListener(_onFavoritesChanged);
    super.dispose();
  }

  void _onFavoritesChanged() {
    setState(() {
      favorites = _favoritesManager.getAllFavorites();
    });
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
                onFavoriteChanged: () {
                  // The listener will automatically refresh the UI
                },
              ),
            ),
          );
        } else {
          // For API images, create a Gallery object from the stored URL
          final gallery = Gallery(
            id: wallpaper.hashCode, // Use hash as ID (int)
            title: _getDisplayName(wallpaper),
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
                onFavoriteChanged: () {
                  // The listener will automatically refresh the UI
                },
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
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(8),
                    bottomRight: Radius.circular(8),
                  ),
                ),
                child: Text(
                  _getDisplayName(wallpaper),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
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
        title: const Text(
          'Favorite Wallpapers',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: favorites.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite_border,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 20),
                  Text(
                    'No favorites yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Like wallpapers to add them here',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
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
              itemCount: favorites.length,
              itemBuilder: (context, index) {
                final wallpaper = favorites[index];
                return _buildFavoriteItem(wallpaper);
              },
            ),
    );
  }
}