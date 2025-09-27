import 'package:flutter/material.dart';
import '../services/favorites_manager.dart';
import 'wallpaper_detail_screen.dart';
import '../widgets/wallpaper_grid.dart';
import 'package:http/http.dart' as http;
import '../config/env_config.dart';
import 'dart:convert';
import 'dart:io';

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  TextEditingController searchController = TextEditingController();
  
  List<Map<String, dynamic>> allWallpapers = [];
  List<Map<String, dynamic>> filteredWallpapers = [];
  bool isSearching = false;
  bool isLoading = true;
  String? currentSearchQuery;
  String? errorMessage;
  
  // API Configuration
  static String get baseUrl => EnvConfig.baseUrl;
  static String get apiKey => EnvConfig.apiKey;

  // Key untuk refresh WallpaperGrid
  Key _wallpaperGridKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    fetchCategories();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // Convert API image path to proper URL format
  String convertImagePathToUrl(String imagePath) {
    String cleanPath = imagePath.replaceAll('\\', '/');
    
    if (cleanPath.startsWith('uploads/')) {
      cleanPath = cleanPath.substring(8);
    }
    
    return '$baseUrl/api/images/$cleanPath';
  }

  // Fetch image with authorization
  Future<String?> fetchAuthorizedImageUrl(String imagePath) async {
    try {
      String imageUrl = convertImagePathToUrl(imagePath);
      
      final response = await http.get(
        Uri.parse(imageUrl),
        headers: {
          'X-API-Key': apiKey,
          'Content-Type': 'application/json',
        },
      ).timeout(Duration(seconds: 15));

      if (response.statusCode == 200) {
        return imageUrl;
      } else {
        print('Failed to authorize image: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error fetching authorized image: $e');
      return null;
    }
  }

  Future<void> fetchCategories({bool isRefresh = false}) async {
    if (!mounted) return;
    
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      String url = '$baseUrl/api/categories';
      print('Fetching categories from: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'X-API-Key': apiKey,
          'Content-Type': 'application/json',
        },
      ).timeout(Duration(seconds: 30));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        List<Map<String, dynamic>> categories = [];
        
        // Handle different API response structures
        if (data is List) {
          categories = List<Map<String, dynamic>>.from(data);
        } else if (data is Map) {
          if (data.containsKey('status') && data['status'] == true) {
            if (data.containsKey('data')) {
              var dataField = data['data'];
              if (dataField is List) {
                categories = List<Map<String, dynamic>>.from(dataField);
              } else if (dataField is Map && dataField.containsKey('data')) {
                categories = List<Map<String, dynamic>>.from(dataField['data']);
              }
            }
          } else if (data.containsKey('categories')) {
            categories = List<Map<String, dynamic>>.from(data['categories']);
          } else if (data.containsKey('data')) {
            var dataField = data['data'];
            if (dataField is List) {
              categories = List<Map<String, dynamic>>.from(dataField);
            } else if (dataField is Map && dataField.containsKey('data')) {
              categories = List<Map<String, dynamic>>.from(dataField['data']);
            }
          }
        }

        // Process categories to fetch authorized image URLs
        List<Future<void>> imageFutures = [];
        for (var category in categories) {
          if (category.containsKey('image_url') && category['image_url'] != null) {
            String originalPath = category['image_url'].toString();
            
            Future<void> imageFuture = fetchAuthorizedImageUrl(originalPath).then((authorizedUrl) {
              if (authorizedUrl != null) {
                category['authorized_image_url'] = authorizedUrl;
              }
            });
            
            imageFutures.add(imageFuture);
          }
        }
        
        try {
          await Future.wait(imageFutures).timeout(Duration(seconds: 30));
        } catch (e) {
          print('Some image authorization requests timed out: $e');
        }

        setState(() {
          allWallpapers = categories;
          filteredWallpapers = List.from(allWallpapers);
          isLoading = false;
          errorMessage = null;
        });

        print('Successfully loaded ${categories.length} categories');
        
      } else {
        throw HttpException('Server returned ${response.statusCode}: ${response.reasonPhrase}');
      }
      
    } on SocketException catch (e) {
      print('Network error: $e');
      _handleError('No internet connection. Please check your network.');
    } on FormatException catch (e) {
      print('JSON parsing error: $e');
      _handleError('Invalid response format from server.');
    } on HttpException catch (e) {
      print('HTTP error: $e');
      _handleError('Server error: ${e.message}');
    } catch (e) {
      print('Unexpected error: $e');
      if (e.toString().contains('TimeoutException')) {
        _handleError('Request timeout. Please try again.');
      } else {
        _handleError('Failed to load categories: ${e.toString()}');
      }
    }
  }

  void _handleError(String message) {
    if (!mounted) return;
    
    setState(() {
      isLoading = false;
      errorMessage = message;
    });
  }

  Future<void> refreshCategories() async {
    await fetchCategories(isRefresh: true);
  }

  String getCategoryImage(Map<String, dynamic> category) {
    if (category.containsKey('authorized_image_url') && category['authorized_image_url'] != null) {
      return category['authorized_image_url'].toString();
    }
    
    // Fallback untuk image lokal jika diperlukan
    return 'assets/default_category.png';
  }

  void filterSearchResults(String query) {
    setState(() {
      isSearching = query.isNotEmpty;
      if (query.isEmpty) {
        filteredWallpapers = List.from(allWallpapers);
        currentSearchQuery = null;
      } else {
        filteredWallpapers = allWallpapers
            .where((item) => item['name']?.toString().toLowerCase().contains(query.toLowerCase()) ?? false)
            .toList();
      }
    });
  }

  void onSearchResultTap(Map<String, dynamic> selectedWallpaper) {
    setState(() {
      searchController.text = selectedWallpaper['name']?.toString() ?? '';
      isSearching = false;
      currentSearchQuery = selectedWallpaper['id']?.toString();
    });
  }

  void clearSearch() {
    setState(() {
      searchController.clear();
      isSearching = false;
      currentSearchQuery = null;
      filteredWallpapers = List.from(allWallpapers);
      _refreshWallpaperGrid();
    });
  }

  void _refreshWallpaperGrid() {
    setState(() {
      _wallpaperGridKey = UniqueKey();
    });
  }

  // Combined refresh function untuk categories dan wallpaper grid
  Future<void> _refreshAll() async {
    await fetchCategories(isRefresh: true);
    _refreshWallpaperGrid();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Wallpaper',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            Text(
              'My',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: isLoading ? null : _refreshAll,
            tooltip: 'Refresh all data',
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshAll,
          child: CustomScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            slivers: [
              // Header section
              SliverToBoxAdapter(
                child: _buildHeaderSection(),
              ),
              
              // Search Results section
              if (isSearching && filteredWallpapers.isNotEmpty)
                SliverToBoxAdapter(
                  child: _buildSearchResultsSection(),
                ),
              
              // Main content section
              SliverToBoxAdapter(
                child: _buildMainContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          
          // Search Bar
          Container(
            height: 50,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F8FF),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              children: [
                const SizedBox(width: 20),
                Expanded(
                  child: TextField(
                    controller: searchController,
                    onChanged: filterSearchResults,
                    decoration: const InputDecoration(
                      hintText: 'Search Wallpaper',
                      hintStyle: TextStyle(
                        color: Colors.grey,
                        fontSize: 18,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 15),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 20),
                  child: Icon(
                    Icons.search,
                    color: Colors.grey[800],
                    size: 28,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 15),
          
          // Categories Section
          SizedBox(
            height: 100,
            child: _buildCategoriesSection(),
          ),              
          
          const SizedBox(height: 15),
          
          // Search Status
          if (currentSearchQuery != null && currentSearchQuery!.isNotEmpty)
            Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(Icons.search, color: Colors.blue[600], size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Results for "${_getWallpaperNameById(currentSearchQuery!)}"',
                      style: TextStyle(
                        color: Colors.blue[600],
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton(
                    onPressed: clearSearch,
                    child: const Text('Clear', style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey[600],
                      padding: EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
                ],
              ),
            ),
          
          // Divider
          Container(
            height: 1,
            margin: EdgeInsets.symmetric(horizontal: 16),
            color: Colors.grey[200],
          ),
          
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildSearchResultsSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Search Results (${filteredWallpapers.length})',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: clearSearch,
                child: const Text('Clear', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey[600],
                  padding: EdgeInsets.symmetric(horizontal: 8),
                ),
              ),
            ],
          ),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: filteredWallpapers.map((wallpaper) => 
                GestureDetector(
                  onTap: () => onSearchResultTap(wallpaper),
                  child: Container(
                    margin: EdgeInsets.only(right: 8),
                    child: Chip(
                      label: Text(
                        wallpaper['name']?.toString() ?? 'Unknown',
                        style: TextStyle(fontSize: 12),
                      ),
                      backgroundColor: Colors.blue[100],
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                )
              ).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return Container(
      height: MediaQuery.of(context).size.height - 300, // Adjusted height
      child: WallpaperGrid(
        key: _wallpaperGridKey,
        searchQuery: currentSearchQuery,
        useLocalAssets: false,
        onRefresh: _refreshAll,
      ),
    );
  }

  Widget _buildCategoriesSection() {
    if (isLoading && allWallpapers.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(strokeWidth: 2),
            SizedBox(height: 4),
            Text('Loading...', style: TextStyle(fontSize: 12)),
          ],
        ),
      );
    }

    if (errorMessage != null && allWallpapers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red[600], size: 24),
            const SizedBox(height: 4),
            Text(
              'Failed to load',
              style: TextStyle(color: Colors.red[600], fontSize: 12),
            ),
            TextButton(
              onPressed: refreshCategories,
              child: const Text('Retry', style: TextStyle(fontSize: 10)),
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              ),
            ),
          ],
        ),
      );
    }

    if (filteredWallpapers.isEmpty) {
      return const Center(
        child: Text('No categories', style: TextStyle(fontSize: 12)),
      );
    }

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: filteredWallpapers.length,
      itemBuilder: (context, index) {
        final category = filteredWallpapers[index];
        String categoryName = category['name']?.toString() ?? 'Unknown';
        String categoryId = category['id']?.toString() ?? '';
        String imagePath = getCategoryImage(category);
        
        return _buildCategoryItem(
          categoryName,
          imagePath,
          categoryId: categoryId,
        );
      },
    );
  }

  Widget _buildCategoryItem(String title, String imagePath, {String? categoryId}) {
    bool isNetworkImage = imagePath.startsWith('http');
    
    return Container(
      width: 80,
      margin: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: () {
          setState(() {
            currentSearchQuery = categoryId;
            searchController.text = title;
            isSearching = false;
            _refreshWallpaperGrid();
          });
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey[200],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: isNetworkImage
                    ? Image.network(
                        imagePath,
                        fit: BoxFit.cover,
                        headers: {
                          'X-API-Key': apiKey,
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                    : null,
                                strokeWidth: 2,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[300],
                            child: Icon(
                              Icons.image_not_supported,
                              color: Colors.grey[600],
                              size: 24,
                            ),
                          );
                        },
                      )
                    : Image.asset(
                        imagePath,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[300],
                            child: Icon(
                              Icons.image_not_supported,
                              color: Colors.grey[600],
                              size: 24,
                            ),
                          );
                        },
                      ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  String _getWallpaperNameById(String id) {
    final wallpaper = allWallpapers.firstWhere(
      (item) => item['id']?.toString() == id,
      orElse: () => {'id': '', 'name': 'Unknown'},
    );
    return wallpaper['name']?.toString() ?? 'Unknown';
  }
}