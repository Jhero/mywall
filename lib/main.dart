import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wallpaper_manager_flutter/wallpaper_manager_flutter.dart';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WallpaperMy',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Roboto',
      ),
      home: const MainNavigationScreen(),
    );
  }
}

// Main navigation container with bottom navigation
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({Key? key}) : super(key: key);

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;
  
  // List of screens for navigation
  final List<Widget> _screens = [
    const MyHomePage(),
    const FavoritesScreen(),
    const AboutScreen(),
  ];
  
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Favorites',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.info),
            label: 'About',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        onTap: _onItemTapped,
      ),
    );
  }
}

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

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  TextEditingController searchController = TextEditingController();
  List<String> allWallpapers = ['Nature', 'City', 'Abstract', 'Animals', 'Landscape', 'Space'];
  List<String> filteredWallpapers = [];
  bool isSearching = false;
  
  // Add a list of wallpaper image paths
  final List<String> wallpaperImages = [
    'assets/leaf.png',
    'assets/easter_eggs.png',
    'assets/minimal.png',
    'assets/dark.png',
  ];

  @override
  void initState() {
    super.initState();
    filteredWallpapers = List.from(allWallpapers);
  }

  void filterSearchResults(String query) {
    setState(() {
      isSearching = query.isNotEmpty;
      if (query.isEmpty) {
        filteredWallpapers = List.from(allWallpapers);
      } else {
        filteredWallpapers = allWallpapers
            .where((item) => item.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
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
      ),
      body: SafeArea(
        child: SingleChildScrollView(
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
              // Add the search results widget here
              if (isSearching) 
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Search Results (${filteredWallpapers.length})',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: filteredWallpapers.map((wallpaper) => Chip(
                          label: Text(wallpaper),
                          backgroundColor: Colors.blue[100],
                          onDeleted: () {
                            // Simulate selecting a search result
                            setState(() {
                              searchController.text = wallpaper;
                              isSearching = false;
                              // In a real app, you would navigate to wallpaper details here
                            });
                          },
                        )).toList(),
                      ),
                    ],
                  ),
                ),              
                            
              const SizedBox(height: 20),
              
              // Categories Row
              SizedBox(
                height: 100,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _buildCategoryItem('Street Art', 'assets/street_art.png'),
                    _buildCategoryItem('Wild Life', 'assets/wildlife.png'),
                    _buildCategoryItem('Nature', 'assets/nature.png'),
                    _buildCategoryItem('City', 'assets/city.png'),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Wallpaper Grid
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildWallpaperItem('assets/leaf.png', ratio: 16/9),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildWallpaperItem('assets/easter_eggs.png', ratio: 9/16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildWallpaperItem('assets/minimal.png', ratio: 16/9),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildWallpaperItem('assets/dark.png', ratio: 9/16),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryItem(String title, String imagePath) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      width: 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        image: DecorationImage(
          image: AssetImage(imagePath),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.black.withOpacity(0.3),
        ),
        child: Center(
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWallpaperItem(String imagePath, {required double ratio}) {
    // Check if this wallpaper is favorited
    final bool isFavorite = FavoritesManager().isFavorite(imagePath);
    
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WallpaperDetailScreen(
              imagePath: imagePath,
              onFavoriteChanged: () {
                // Refresh the UI when returning from detail screen
                setState(() {});
              },
            ),
          ),
        );
      },
      child: Hero(
        tag: imagePath,
        child: AspectRatio(
          aspectRatio: ratio,
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: AssetImage(imagePath),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(8),
                        bottomRight: Radius.circular(8),
                      ),
                    ),
                    child: Text(
                      imagePath.split('/').last.split('.').first.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              // Show a favorite indicator if the wallpaper is in favorites
              if (isFavorite)
                const Positioned(
                  top: 8,
                  right: 8,
                  child: Icon(
                    Icons.favorite,
                    color: Colors.red,
                    size: 22,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }  
}

// Add the FavoritesScreen class
class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({Key? key}) : super(key: key);

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  late List<String> favorites;
  
  @override
  void initState() {
    super.initState();
    favorites = FavoritesManager().getAllFavorites();
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
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => WallpaperDetailScreen(
                          imagePath: wallpaper,
                          onFavoriteChanged: () {
                            // Refresh the favorites list when returning
                            setState(() {
                              favorites = FavoritesManager().getAllFavorites();
                            });
                          },
                        ),
                      ),
                    );
                  },
                  child: Hero(
                    tag: 'favorite_$wallpaper',
                    child: Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            image: DecorationImage(
                              image: AssetImage(wallpaper),
                              fit: BoxFit.cover,
                            ),
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
                                setState(() {
                                  FavoritesManager().removeFavorite(wallpaper);
                                  favorites = FavoritesManager().getAllFavorites();
                                });
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
                              wallpaper.split('/').last.split('.').first.toUpperCase(),
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
              },
            ),
    );
  }
}

// New About Screen
class AboutScreen extends StatelessWidget {
  const AboutScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'About',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            
            // App Logo
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Center(
                child: Icon(
                  Icons.wallpaper,
                  size: 70,
                  color: Colors.white,
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // App Title
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Wallpaper',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                Text(
                  'My',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 10),
            
            // App Version
            const Text(
              'Version 1.0.0',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            
            const SizedBox(height: 30),
            
            // App Description
            const Text(
              'WallpaperMy is a free wallpaper application that provides high-quality wallpapers for your device. With WallpaperMy, you can browse, search, and set beautiful wallpapers for your home screen and lock screen.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
              ),
            ),
            
            const SizedBox(height: 30),
            
            // Features Section
            const Text(
              'Features',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 15),
            
            _buildFeatureItem(
              Icons.photo_library, 
              'Beautiful Wallpapers', 
              'Access a wide collection of high-quality wallpapers'
            ),
            
            _buildFeatureItem(
              Icons.favorite, 
              'Favorites', 
              'Save your favorite wallpapers for quick access'
            ),
            
            _buildFeatureItem(
              Icons.format_paint, 
              'Categories', 
              'Browse wallpapers by category for easy discovery'
            ),
            
            _buildFeatureItem(
              Icons.wallpaper, 
              'Easy Application', 
              'Set wallpapers for home screen, lock screen, or both'
            ),
            
            _buildFeatureItem(
              Icons.share, 
              'Share', 
              'Share wallpapers with friends and family'
            ),
                        
            const SizedBox(height: 30),
            
            // Developer Info
            const Text(
              'Developed by',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            
            const SizedBox(height: 5),
            
            const Text(
              'WallpaperMy Team',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 30),
            
            // Contact Info
            OutlinedButton.icon(
              icon: const Icon(Icons.email),
              label: const Text('Contact Us'),
              onPressed: () {
                // Implement email contact functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Contact feature coming soon!')),
                );
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFeatureItem(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: Colors.blue,
              size: 24,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  description,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Modified WallpaperDetailScreen class
class WallpaperDetailScreen extends StatefulWidget {
  final String imagePath;
  final Function? onFavoriteChanged;
  
  const WallpaperDetailScreen({
    Key? key, 
    required this.imagePath,
    this.onFavoriteChanged,
  }) : super(key: key);

  @override
  State<WallpaperDetailScreen> createState() => _WallpaperDetailScreenState();
}

class _WallpaperDetailScreenState extends State<WallpaperDetailScreen> {
  late bool isLiked;

  @override
  void initState() {
    super.initState();
    isLiked = FavoritesManager().isFavorite(widget.imagePath);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Full screen image
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
            },
            child: Center(
              child: Hero(
                tag: widget.imagePath,
                child: Image.asset(
                  widget.imagePath,
                  fit: BoxFit.contain,
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
            ),
          ),
          
          // Top action buttons
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back button
                  CircleAvatar(
                    backgroundColor: Colors.black54,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () {
                        if (widget.onFavoriteChanged != null) {
                          widget.onFavoriteChanged!();
                        }
                        Navigator.pop(context);
                      },
                    ),
                  ),
                  
                  // Share button
                  CircleAvatar(
                    backgroundColor: Colors.blue,
                    child: IconButton(
                      icon: const Icon(Icons.share, color: Colors.white),
                      onPressed: () async {
                        final ByteData bytes = await rootBundle.load(widget.imagePath);
                        final Uint8List list = bytes.buffer.asUint8List();
                        final tempDir = await getTemporaryDirectory();
                        final file = await File('${tempDir.path}/image.jpg').create();
                        await file.writeAsBytes(list);
                        await Share.shareXFiles([XFile(file.path)], text: 'Check out this wallpaper!');
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Bottom action buttons
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Like button
                CircleAvatar(
                  backgroundColor: Colors.red,
                  child: IconButton(
                    icon: Icon(
                      isLiked ? Icons.favorite : Icons.favorite_border,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      setState(() {
                        isLiked = !isLiked;
                        if (isLiked) {
                          FavoritesManager().addFavorite(widget.imagePath);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Added to favorites'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        } else {
                          FavoritesManager().removeFavorite(widget.imagePath);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Removed from favorites'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        }
                      });
                    },
                  ),
                ),
                const SizedBox(width: 20),
                
                // Set Wallpaper button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: () async {
                    try {
                      final ByteData bytes = await rootBundle.load(widget.imagePath);
                      final Uint8List list = bytes.buffer.asUint8List();
                      
                      // Get the directory for temporary files
                      final directory = await getTemporaryDirectory();
                      final imagePath = '${directory.path}/wallpaper_${DateTime.now().millisecondsSinceEpoch}.jpg';
                      final file = File(imagePath);
                      
                      // Save the image to a temporary file
                      await file.writeAsBytes(list);

                      // Show wallpaper location selection dialog
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('Set wallpaper on'),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ListTile(
                                  title: const Text('Home Screen'),
                                  onTap: () async {
                                    Navigator.pop(context);
                                    try {
                                      final int location = 1;
                                      await WallpaperManagerFlutter().setWallpaper(
                                        file, 
                                        location
                                      );
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Home screen wallpaper set successfully!')),
                                      );
                                    } catch (e) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Error: ${e.toString()}')),
                                      );
                                    }
                                  },
                                ),
                                ListTile(
                                  title: const Text('Lock Screen'),
                                  onTap: () async {
                                    Navigator.pop(context);
                                    try {
                                      final int location = 2;
                                      await WallpaperManagerFlutter().setWallpaper(
                                        file, 
                                        location
                                      );
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Lock screen wallpaper set successfully!')),
                                      );
                                    } catch (e) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Error: ${e.toString()}')),
                                      );
                                    }
                                  },
                                ),
                                ListTile(
                                  title: const Text('Both Screens'),
                                  onTap: () async {
                                    Navigator.pop(context);
                                    try {
                                      final int location = 3;
                                      await WallpaperManagerFlutter().setWallpaper(
                                        file, 
                                        location
                                      );
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Wallpaper set on both screens successfully!')),
                                      );
                                    } catch (e) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Error: ${e.toString()}')),
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      );

                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error setting wallpaper: $e')),
                      );
                    }
                  },
                  child: const Text('Set Wallpaper'),  // Added the required child parameter
                )                
              ],
            ),
          ),
        ],
      ),
    );
  }
}