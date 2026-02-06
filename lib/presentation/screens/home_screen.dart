import 'package:flutter/material.dart';
import '../../services/favorites_manager.dart';
import '../../services/gallery_service.dart';
import '../../models/gallery.dart';
import 'wallpaper_detail_screen.dart';
import '../../widgets/wallpaper_grid.dart';
import 'package:http/http.dart' as http;
import '../../config/env_config.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:async'; // Import untuk Stream
import '../../services/websocket_service.dart';
// import '../../helpers/rating_helper.dart';
import '../../helpers/category_cache_helper.dart';

import '../../services/websocket_service.dart';
// import '../../services/notification_service.dart';
import '../../widgets/notification_badge.dart';
import '../../pages/notification_page.dart';
import '../../services/websocket_service.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class MyHomePage extends StatefulWidget {
  final GlobalKey? tourThemeMenuKey;
  final GlobalKey? tourNotificationKey;
  final GlobalKey? tourReloadKey;
  MyHomePage({this.tourThemeMenuKey, this.tourNotificationKey, this.tourReloadKey});
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
  String? categoryId;
  String? errorMessage;
  
  // API Configuration
  static String get baseUrl => EnvConfig.baseUrl;
  static String get apiKey => EnvConfig.apiKey;

  // Key untuk refresh WallpaperGrid
  Key _wallpaperGridKey = UniqueKey();

  // StreamController untuk auto-update
  final StreamController<bool> _updateStreamController = StreamController<bool>.broadcast();
  Timer? _autoRefreshTimer;
  final WebSocketService _webSocketService = WebSocketService();

  @override
  void initState() {
    super.initState();
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   RatingHelper.showRatingDialogIfNeeded(context);
    // });

    fetchCategories();
    // _startAutoRefresh();
    _initializeWebSocket();
  }

  @override
  /*
  void dispose() {
    _socketService.removeNewGalleryListener(_handleNewGallery);
    _socketService.disconnect();
    super.dispose();
  } 
  */ 
  void dispose() {
    searchController.dispose();
    _updateStreamController.close();
    
    _webSocketService.removeNewGalleryListener(_handleWebSocketNewGallery);
    _webSocketService.removeUpdateGalleryListener(_handleWebSocketUpdateGallery);
    _webSocketService.removeDeleteGalleryListener(_handleWebSocketDeleteGallery);
    
    super.dispose();
  }

  void _initializeWebSocket() {
    // Register gallery listeners on WebSocketService
    _webSocketService.addNewGalleryListener(_handleWebSocketNewGallery);
    _webSocketService.addUpdateGalleryListener(_handleWebSocketUpdateGallery);
    _webSocketService.addDeleteGalleryListener(_handleWebSocketDeleteGallery);
    _webSocketService.connect();
  }

  /*
  void _initializeSocket() {
    // Initialize socket connection
    _socketService.initializeSocket();
    
    // Add listener for new galleries
    _socketService.addNewGalleryListener(_handleNewGallery);
    _socketService.addUpdateGalleryListener(_handleUpdateGallery);
    _socketService.addDeleteGalleryListener(_handleDeleteGallery);
  }
  */


  // Auto refresh setiap 30 detik
  void _startAutoRefresh() {
    _autoRefreshTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      _checkForNewData();
    });
  }

  void _handleWebSocketNewGallery(Map<String, dynamic> galleryData) {
    // print('🆕 WebSocket: New gallery received in HomePage: $galleryData');
    
    try {        
        // Trigger WallpaperGrid update
        _triggerWallpaperGridUpdate();
        
        // Show notification
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('New wallpaper added:'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
    } catch (e) {
      // print('Error handling new gallery from WebSocket: $e');
    }
  }

  void _handleWebSocketUpdateGallery(Map<String, dynamic> galleryData) {
    // print('📝 WebSocket: Gallery updated in HomePage: $galleryData');
    
    try {
        _triggerWallpaperGridUpdate();
    } catch (e) {
      // print('Error handling updated gallery from WebSocket: $e');
    }
  }

  void _handleWebSocketDeleteGallery(Map<String, dynamic> galleryData) {
    // print('🗑️ WebSocket: Gallery deleted in HomePage: $galleryData');
    
    try {        
        _triggerWallpaperGridUpdate();
        
        // Show notification
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Wallpaper deleted'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
    } catch (e) {
      // print('Error handling deleted gallery from WebSocket: $e');
    }
  }


  // Function untuk check data baru
  Future<void> _checkForNewData() async {
    try {
        _triggerWallpaperGridUpdate();
    } catch (e) {
      // print('Auto-refresh error: $e');
    }
  }

  // Trigger update ke WallpaperGrid
  void _triggerWallpaperGridUpdate() {
    if (!_updateStreamController.isClosed) {
      _updateStreamController.add(true);
    }
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
        // print('Failed to authorize image: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      // print('Error fetching authorized image: $e');
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
      // ===============================
      // 1️⃣ DATA STATIS
      // ===============================
      final categories = [
        {
          'id': 14,
          'name': 'Jhope',
          'authorized_image_url': 'assets/category/Jhope.jpg',
        },
        {
          'id': 4,
          'name': 'Jimin',
          'authorized_image_url': 'assets/category/Jimin.jpg',
        },
        {
          'id': 13,
          'name': 'Jin',
          'authorized_image_url': 'assets/category/Jin.jpg',
        },
        {
          'id': 17,
          'name': 'Jungkok',
          'authorized_image_url': 'assets/category/Jungkok.jpg',
        },
        {
          'id': 15,
          'name': 'RM',
          'authorized_image_url': 'assets/category/RM.jpg',
        },
        {
          'id': 18,
          'name': 'Suga',
          'authorized_image_url': 'assets/category/Suga.jpg',
        },
        {
          'id': 16,
          'name': 'Vee',
          'authorized_image_url': 'assets/category/Vee.jpg',
        },
      ];

      // ===============================
      // 2️⃣ SAVE TO CACHE (optional)
      // ===============================
      await CategoryCacheHelper.save(categories);

      // ===============================
      // 3️⃣ UPDATE UI
      // ===============================
      setState(() {
        allWallpapers = categories;
        filteredWallpapers = List.from(categories);
        isLoading = false;
      });

      // print('Loaded ${categories.length} categories from static assets');
      _triggerWallpaperGridUpdate();
    } catch (e) {
      // print('Error loading categories: $e');
      _handleError('Failed to load categories');
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
        categoryId = null;
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
      categoryId = selectedWallpaper['id']?.toString();
    });
  }

  void clearSearch() {
    setState(() {
      searchController.clear();
      isSearching = false;
      categoryId = null;
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Wallpaper',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onBackground,
                ),
              ),
              Text(
                'My',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              Text(
                'BTS Idol',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
            ],
          ),
        ),
        actions: [
          NotificationBadge(
            key: widget.tourNotificationKey,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationPage(),
                ),
              );
            },
          ),
          PopupMenuButton<String>(
            key: widget.tourThemeMenuKey,
            onSelected: (value) {
              Provider.of<ThemeProvider>(context, listen: false)
                  .setThemeByKey(value);
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'normal', child: Icon(Icons.wb_sunny)),
              PopupMenuItem(value: 'dark', child: Icon(Icons.nightlight_round)),
              PopupMenuItem(value: 'pink', child: Icon(Icons.favorite)),
              PopupMenuItem(value: 'blue', child: Icon(Icons.water_drop)),
            ],
            icon: const Icon(Icons.color_lens),
          ),
          // WebSocket connection indicator
          // StreamBuilder<bool>(
          //   stream: Stream.periodic(Duration(seconds: 5)).map((_) => _webSocketService.isConnected),
          //   builder: (context, snapshot) {
          //     final isConnected = snapshot.data ?? false;
          //     return Icon(
          //       Icons.circle,
          //       color: isConnected ? Colors.green : Colors.red,
          //       size: 12,
          //     );
          //   },
          // ),
          SizedBox(width: 8),
          IconButton(
            key: widget.tourReloadKey,
            icon: Icon(Icons.refresh),
            onPressed: isLoading ? null : _refreshAll,
            tooltip: 'Refresh all data',
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: Column(
            children: [
              // Bagian Consumer untuk status WebSocket
              Builder(
                builder: (context) {
                  final ws = WebSocketService();
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    /*
                    children: [
                      const Text('Home Page'),
                      const SizedBox(height: 20),
                      Text(
                        'Unread Notifications: ${ws.unreadCount}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'WebSocket: ${ws.isConnected ? "Connected ✅" : "Disconnected ❌"}',
                        style: TextStyle(
                          color: ws.isConnected ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                    */
                  );
                },
              ),

              const SizedBox(height: 20),

              // Bagian RefreshIndicator + CustomScrollView
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refreshAll,
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child: _buildHeaderSection(),
                      ),
                      if (isSearching && filteredWallpapers.isNotEmpty)
                        SliverToBoxAdapter(
                          child: _buildSearchResultsSection(),
                        ),
                      SliverToBoxAdapter(
                        child: _buildMainContent(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      /*
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
      */
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          
          // Categories Section dengan height yang fixed TAPI TIDAK BERLEBIHAN
          SizedBox(
            height: 110, // Reduced height untuk mencegah overflow
            child: _buildCategoriesSection(),
          ),              
          
          const SizedBox(height: 15),
          
          // Search Status
          if (categoryId != null && categoryId!.isNotEmpty)
            Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(Icons.search, color: Theme.of(context).colorScheme.primary, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Results for "${_getWallpaperNameById(categoryId!)}"',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
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
                      foregroundColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
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
            color: Theme.of(context).dividerColor,
          ),
          
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildSearchResultsSection() {
    return Container(
      color: Theme.of(context).colorScheme.surface,
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
                      foregroundColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
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
                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
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
      // Height yang lebih aman dan responsif
      height: MediaQuery.of(context).size.height * 0.6,
      child: WallpaperGrid(
        key: _wallpaperGridKey,
        searchQuery: null,
        categoryId: categoryId,
        useLocalAssets: false,
        onRefresh: _refreshAll,
        updateStream: _updateStreamController.stream, // Stream untuk auto-update
      ),
    );
  }
  
  Widget _buildCategoriesSection() {
    if (isLoading && allWallpapers.isEmpty) {
      return SizedBox(
        height: 100, // Reduced height
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(height: 4),
              Text('Loading...', style: TextStyle(fontSize: 12)),
            ],
          ),
        ),
      );
    }

    if (errorMessage != null && allWallpapers.isEmpty) {
      return SizedBox(
        height: 100, // Reduced height
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.red[600], size: 20),
              SizedBox(height: 4),
              Text(
                'Failed to load',
                style: TextStyle(color: Colors.red[600], fontSize: 10),
              ),
              TextButton(
                onPressed: refreshCategories,
                child: Text('Retry', style: TextStyle(fontSize: 10)),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (filteredWallpapers.isEmpty) {
      return SizedBox(
        height: 100, // Reduced height
        child: Center(
          child: Text('No categories', style: TextStyle(fontSize: 12)),
        ),
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
      width: 70, // Reduced width
      margin: const EdgeInsets.only(right: 10),
      child: GestureDetector(
        onTap: () {
          // print('Category tapped: $title with ID: $categoryId');
          setState(() {
            // categoryId = categoryId;
            this.categoryId = categoryId;
            searchController.text = title;
            isSearching = false;
            searchController.clear();
            // filteredWallpapers = List.from(allWallpapers);
            // _refreshWallpaperGrid();
          });
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Container image dengan size 50x50
            Container(
              width: 50, // Maximum width 50
              height: 50, // Maximum height 50
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Theme.of(context).colorScheme.surface,
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
                              width: 15,
                              height: 15,
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                    : null,
                                strokeWidth: 1.5,
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
                              size: 20,
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
                              size: 20,
                            ),
                          );
                        },
                      ),
              ),
            ),
            const SizedBox(height: 6),
            // Text dengan constraints yang lebih ketat
            Container(
              constraints: BoxConstraints(maxWidth: 65),
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 11, // Reduced font size
                  fontWeight: FontWeight.w500,
                ),
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

  String _getWallpaperNameById(String id) {
    for (final item in allWallpapers) {
      if (item['id']?.toString() == id) {
        return item['name']?.toString() ?? 'Unknown';
      }
    }
    return 'Unknown';
  }  
}
