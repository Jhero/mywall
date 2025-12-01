import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoritesManager {
  static const String _favoritesKey = 'favorite_wallpapers';
  late SharedPreferences _prefs;
  List<String> _favorites = [];
  List<VoidCallback> _listeners = [];

  // Singleton pattern
  static final FavoritesManager _instance = FavoritesManager._internal();
  factory FavoritesManager() => _instance;
  FavoritesManager._internal() {
    _initPrefs();
  }

  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final favoritesJson = _prefs.getStringList(_favoritesKey);
    if (favoritesJson != null) {
      _favorites = favoritesJson;
      _notifyListeners();
    }
  }

  Future<void> _saveFavorites() async {
    await _prefs.setStringList(_favoritesKey, _favorites);
  }

  // Listener management
  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  void _notifyListeners() {
    for (final listener in _listeners) {
      listener();
    }
  }

  // Favorite operations
  Future<void> addFavorite(String wallpaper) async {
    if (!_favorites.contains(wallpaper)) {
      _favorites.add(wallpaper);
      await _saveFavorites();
      _notifyListeners();
    }
  }

  Future<void> removeFavorite(String wallpaper) async {
    if (_favorites.remove(wallpaper)) {
      await _saveFavorites();
      _notifyListeners();
    }
  }

  // Toggle method (untuk WallpaperDetailScreen)
  Future<void> toggleFavorite(String wallpaper) async {
    if (isFavorite(wallpaper)) {
      await removeFavorite(wallpaper);
    } else {
      await addFavorite(wallpaper);
    }
  }

  bool isFavorite(String wallpaper) {
    return _favorites.contains(wallpaper);
  }

  List<String> getAllFavorites() {
    return List.from(_favorites);
  }

  Future<void> clearAllFavorites() async {
    _favorites.clear();
    await _saveFavorites();
    _notifyListeners();
  }
}