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
  ScrollController _scrollController = ScrollController();
  
  List<Map<String, dynamic>> allWallpapers = [];
  List<Map<String, dynamic>> filteredWallpapers = [];
  bool isSearching = false;
  bool isLoading = true;
  bool isLoadingMore = false;
  bool hasMoreData = true;
  String? currentSearchQuery;
  String? errorMessage;
  
  // Pagination
  int currentPage = 1;
  int itemsPerPage = 20;
  
  // API Configuration
  static String get baseUrl => EnvConfig.baseUrl;
  static String get apiKey => EnvConfig.apiKey;

  // Default images mapping for categories (fallback)
  final Map<String, String> categoryImages = {
    'default': 'assets/default_category.png',
  };

  @override
  void initState() {
    super.initState();
    fetchCategories();
    _setupScrollListener();
  }

  @override
  void dispose() {
    searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Setup scroll listener for lazy loading
  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= 
          _scrollController.position.maxScrollExtent - 200) {
        // Load more data when user is 200 pixels away from bottom
        _loadMoreCategories();
      }
    });
  }

  // Convert API image path to proper URL format for HTTP requests with authorization
  String convertImagePathToUrl(String imagePath) {
    // Convert backslashes to forward slashes and remove 'uploads' prefix if present
    String cleanPath = imagePath.replaceAll('\\', '/');
    
    // Remove 'uploads/' prefix if it exists
    if (cleanPath.startsWith('uploads/')) {
      cleanPath = cleanPath.substring(8); // Remove 'uploads/'
    }
    
    // Construct the full URL for authorized image request
    return '$baseUrl/api/images/$cleanPath';
  }

  // Fetch image with authorization
  Future<String?> fetchAuthorizedImageUrl(String imagePath) async {
    try {
      String imageUrl = convertImagePathToUrl(imagePath);
      print('Fetching authorized image from: $imageUrl');
      
      final response = await http.get(
        Uri.parse(imageUrl),
        headers: {
          'X-API-Key': apiKey,
          'Content-Type': 'application/json',
        },
      ).timeout(Duration(seconds: 15));

      if (response.statusCode == 200) {
        // If the request is successful, return the URL for use with network image
        // The actual image data will be fetched by Flutter's Image.network widget
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

  // Modified to support pagination
  Future<void> fetchCategories({bool isRefresh = false}) async {
    if (!mounted) return;
    
    if (isRefresh) {
      setState(() {
        currentPage = 1;
        hasMoreData = true;
        allWallpapers.clear();
        filteredWallpapers.clear();
      });
    }
    
    setState(() {
      if (isRefresh) {
        isLoading = true;
      }
      errorMessage = null;
    });

    try {
      String url = '$baseUrl/api/categories?page=$currentPage&limit=$itemsPerPage';
      print('Fetching categories from: $url');
      print('Using API Key: ${apiKey.isNotEmpty ? "***" : "EMPTY"}');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'X-API-Key': apiKey,
          'Content-Type': 'application/json',
        },
      ).timeout(Duration(seconds: 30));

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        List<Map<String, dynamic>> categories = [];
        
        // Handle different API response structures
        if (data is List) {
          categories = List<Map<String, dynamic>>.from(data);
        } else if (data is Map) {
          if (data.containsKey('status') && data['status'] == true) {
            // Handle response with status wrapper
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

        // Check if we have more data
        if (categories.length < itemsPerPage) {
          hasMoreData = false;
        }

        // Process categories to fetch authorized image URLs
        List<Future<void>> imageFutures = [];
        for (var category in categories) {
          if (category.containsKey('image_url') && category['image_url'] != null) {
            String originalPath = category['image_url'].toString();
            
            // Create future to fetch authorized image URL
            Future<void> imageFuture = fetchAuthorizedImageUrl(originalPath).then((authorizedUrl) {
              if (authorizedUrl != null) {
                category['authorized_image_url'] = authorizedUrl;
                print('Original image path: $originalPath');
                print('Authorized image URL: $authorizedUrl');
              } else {
                print('Failed to authorize image for: $originalPath');
              }
            });
            
            imageFutures.add(imageFuture);
          }
        }
        
        // Wait for all image authorization requests to complete (with timeout)
        try {
          await Future.wait(imageFutures).timeout(Duration(seconds: 30));
        } catch (e) {
          print('Some image authorization requests timed out: $e');
        }

        setState(() {
          if (isRefresh || currentPage == 1) {
            allWallpapers = categories;
          } else {
            allWallpapers.addAll(categories);
          }
          
          // Update filtered wallpapers based on current search
          if (isSearching && searchController.text.isNotEmpty) {
            filterSearchResults(searchController.text);
          } else {
            filteredWallpapers = List.from(allWallpapers);
          }
          
          isLoading = false;
          isLoadingMore = false;
          errorMessage = null;
        });

        print('Successfully loaded ${categories.length} categories (Page: $currentPage)');
        
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

  // Load more categories for pagination
  Future<void> _loadMoreCategories() async {
    if (isLoadingMore || !hasMoreData || isLoading) return;

    setState(() {
      isLoadingMore = true;
    });

    currentPage++;
    await fetchCategories();
  }

  void _handleError(String message) {
    if (!mounted) return;
    
    setState(() {
      isLoading = false;
      isLoadingMore = false;
      errorMessage = message;
      
      // Set fallback categories only if we don't have any data
      if (allWallpapers.isEmpty) {
        allWallpapers = [
          {'id': '1', 'name': 'Alam'},
          {'id': '2', 'name': 'Wild Life'},
          {'id': '3', 'name': 'Nature'},
          {'id': '4', 'name': 'City'},
        ];
        filteredWallpapers = allWallpapers;
        hasMoreData = false;
      }
    });
  }

  // Pull to refresh function
  Future<void> _onRefresh() async {
    await fetchCategories(isRefresh: true);
  }

  // Manual refresh function
  Future<void> refreshCategories() async {
    await fetchCategories(isRefresh: true);
  }

  String getCategoryImage(Map<String, dynamic> category) {
    // First try to get the authorized image URL from API
    if (category.containsKey('authorized_image_url') && category['authorized_image_url'] != null) {
      return category['authorized_image_url'].toString();
    }
    
    // Fallback to local assets based on category name
    String categoryName = category['name']?.toString() ?? '';
    String lowerName = categoryName.toLowerCase();
    return categoryImages[lowerName] ?? categoryImages['default']!;
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
    });
  }

  String _getWallpaperNameById(String id) {
    final wallpaper = allWallpapers.firstWhere(
      (item) => item['id']?.toString() == id,
      orElse: () => {'id': '', 'name': 'Unknown'},
    );
    return wallpaper['name']?.toString() ?? 'Unknown';
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
            onPressed: isLoading ? null : refreshCategories,
            tooltip: 'Refresh categories',
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    
                    // Search Bar
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F8FF),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
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
                              ),
                            ),
                          ),
                          Icon(
                            Icons.search,
                            color: Colors.grey[800],
                            size: 28,
                          ),
                        ],
                      ),
                    ),

                    // Search Results
                    if (isSearching) 
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Search Results (${filteredWallpapers.length})',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed: clearSearch,
                                  icon: const Icon(Icons.clear, size: 16),
                                  label: const Text('Clear'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: filteredWallpapers.map((wallpaper) => GestureDetector(
                                onTap: () => onSearchResultTap(wallpaper),
                                child: Chip(
                                  label: Text(wallpaper['name']?.toString() ?? 'Unknown'),
                                  backgroundColor: Colors.blue[100],
                                  deleteIcon: const Icon(Icons.search, size: 18),
                                  onDeleted: () => onSearchResultTap(wallpaper),
                                ),
                              )).toList(),
                            ),
                          ],
                        ),
                      ),
                                  
                    const SizedBox(height: 20),
                    
                    // Categories Section
                    SizedBox(
                      height: 100,
                      child: _buildCategoriesSection(),
                    ),              
                    
                    const SizedBox(height: 20),
                    
                    // Search Status
                    if (currentSearchQuery != null && currentSearchQuery!.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          children: [
                            Icon(Icons.search, color: Colors.blue[600], size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Showing results for "${_getWallpaperNameById(currentSearchQuery!)}"',
                                style: TextStyle(
                                  color: Colors.blue[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: clearSearch,
                              child: const Text('Clear'),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              
              // Wallpaper Grid - now as a sliver
              SliverToBoxAdapter(
                child: WallpaperGrid(
                  searchQuery: currentSearchQuery,
                ),
              ),
              
              // Loading indicator at bottom
              if (isLoadingMore)
                SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    child: const Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 12),
                          Text('Loading more...'),
                        ],
                      ),
                    ),
                  ),
                ),
              
              // End indicator
              if (!hasMoreData && allWallpapers.isNotEmpty)
                SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    child: const Center(
                      child: Text(
                        'No more categories to load',
                        style: TextStyle(
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ),
                ),
                
              SliverToBoxAdapter(
                child: const SizedBox(height: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoriesSection() {
    if (isLoading && allWallpapers.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 8),
            Text('Loading categories...'),
          ],
        ),
      );
    }

    if (errorMessage != null && allWallpapers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red[600], size: 32),
            const SizedBox(height: 8),
            Text(
              'Failed to load categories',
              style: TextStyle(color: Colors.red[600]),
            ),
            const SizedBox(height: 4),
            TextButton(
              onPressed: refreshCategories,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (filteredWallpapers.isEmpty) {
      return const Center(
        child: Text('No categories available'),
      );
    }

    return ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: filteredWallpapers.map((category) {
        String categoryName = category['name']?.toString() ?? 'Unknown';
        String categoryId = category['id']?.toString() ?? '';
        String imagePath = getCategoryImage(category);
        
        return _buildCategoryItem(
          categoryName,
          imagePath,
          category: category,
          categoryId: categoryId,
        );
      }).toList(),
    );
  }

  Widget _buildCategoryItem(String title, String imagePath, {Map<String, dynamic>? category, String? categoryId}) {
    bool isNetworkImage = imagePath.startsWith('http');
    
    return Container(
      margin: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: () {
          print('Selected category: $title (ID: $categoryId)');
          // You can add navigation or other actions here
          setState(() {
            currentSearchQuery = categoryId;
            searchController.text = title;
            isSearching = false;
          });
        },
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey[200], // Background color while loading
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: isNetworkImage
                    ? Image.network(
                        imagePath,
                        fit: BoxFit.cover,
                        width: 80,
                        height: 80,
                        headers: {
                          'X-API-Key': apiKey,
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                  : null,
                              strokeWidth: 2,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          print('Error loading network image: $imagePath');
                          print('Error: $error');
                          // Fallback to asset image
                          String fallbackImage = getCategoryImageFallback(title);
                          return Image.asset(
                            fallbackImage,
                            fit: BoxFit.cover,
                            width: 80,
                            height: 80,
                          );
                        },
                      )
                    : Image.asset(
                        imagePath,
                        fit: BoxFit.cover,
                        width: 80,
                        height: 80,
                        errorBuilder: (context, error, stackTrace) {
                          print('Error loading asset image: $imagePath');
                          return Container(
                            width: 80,
                            height: 80,
                            color: Colors.grey[300],
                            child: Icon(
                              Icons.image_not_supported,
                              color: Colors.grey[600],
                            ),
                          );
                        },
                      ),
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: 80,
              child: Text(
                title,
                style: const TextStyle(fontSize: 12),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to get fallback asset image
  String getCategoryImageFallback(String categoryName) {
    String lowerName = categoryName.toLowerCase();
    return categoryImages[lowerName] ?? categoryImages['default']!;
  }
}