import 'package:flutter/material.dart';
import '../models/favorites_manager.dart';
import 'wallpaper_detail_screen.dart';

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