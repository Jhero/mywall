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
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}


class _MyHomePageState extends State<MyHomePage> {
  // Add these variables at the top of the class
  TextEditingController searchController = TextEditingController();
  List<String> allWallpapers = ['Nature', 'City', 'Abstract', 'Animals', 'Landscape', 'Space'];
  List<String> filteredWallpapers = [];
  bool isSearching = false;

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
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
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
              const SizedBox(height: 20),

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
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WallpaperDetailScreen(imagePath: imagePath),
          ),
        );
      },
      child: Hero(
        tag: imagePath,
        child: AspectRatio(
          aspectRatio: ratio,
          child: Container(
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
        ),
      ),
    );
  }  
}

// Add the WallpaperDetailScreen class here
class WallpaperDetailScreen extends StatefulWidget {
  final String imagePath;
  
  const WallpaperDetailScreen({Key? key, required this.imagePath}) : super(key: key);

  @override
  State<WallpaperDetailScreen> createState() => _WallpaperDetailScreenState();
}

class _WallpaperDetailScreenState extends State<WallpaperDetailScreen> {
  bool isLiked = false;

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
                      onPressed: () => Navigator.pop(context),
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

                      // Constants for this package
                      // 1 = Home screen
                      // 2 = Lock screen 
                      // 3 = Both screens
                      // final int location = 1; // Home screen

                      // // The actual method in this package is likely this:
                      // await WallpaperManagerFlutter().setWallpaper(file, location);
                      
                      // ScaffoldMessenger.of(context).showSnackBar(
                      //   const SnackBar(content: Text('Wallpaper set successfully!')),
                      // );

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
                            final int location = 2;				  
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
                  child: const Text(
                    'SET AS WALLPAPER',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
