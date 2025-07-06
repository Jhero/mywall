// lib/services/favorites_manager.dart
import 'package:flutter/foundation.dart';

class FavoritesManager extends ChangeNotifier {
  static final FavoritesManager _instance = FavoritesManager._internal();
  factory FavoritesManager() => _instance;
  FavoritesManager._internal();

  final Set<String> _favorites = <String>{};

  Set<String> get favorites => Set.unmodifiable(_favorites);

  bool isFavorite(String imageUrl) {
    return _favorites.contains(imageUrl);
  }

  void addFavorite(String imageUrl) {
    _favorites.add(imageUrl);
    notifyListeners();
  }

  void removeFavorite(String imageUrl) {
    _favorites.remove(imageUrl);
    notifyListeners();
  }

  void toggleFavorite(String imageUrl) {
    if (isFavorite(imageUrl)) {
      removeFavorite(imageUrl);
    } else {
      addFavorite(imageUrl);
    }
  }

  void clearFavorites() {
    _favorites.clear();
    notifyListeners();
  }
}