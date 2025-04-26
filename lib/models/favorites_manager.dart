// Create a class to store favorite wallpapers globally
class FavoritesManager {
  static final FavoritesManager _instance = FavoritesManager._internal();
  
  // Factory constructor to return the same instance every time
  factory FavoritesManager() {
    return _instance;
  }
  
  FavoritesManager._internal();
  
  // Set to store unique favorite wallpaper paths
  final Set<String> _favorites = {};
  
  // Add a wallpaper to favorites
  void addFavorite(String path) {
    _favorites.add(path);
  }
  
  // Remove a wallpaper from favorites
  void removeFavorite(String path) {
    _favorites.remove(path);
  }
  
  // Check if a wallpaper is in favorites
  bool isFavorite(String path) {
    return _favorites.contains(path);
  }
  
  // Get all favorites
  List<String> getAllFavorites() {
    return _favorites.toList();
  }
}