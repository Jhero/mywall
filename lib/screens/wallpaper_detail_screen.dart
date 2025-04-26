import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:share_plus/share_plus.dart';
import 'package:wallpaper_manager_flutter/wallpaper_manager_flutter.dart';
import '../models/favorites_manager.dart';

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
                      await file.writeAsBytes(list);
                      
                      // Set the wallpaper
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
                        SnackBar(
                          content: Text('Error setting wallpaper: $e'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  child: const Text('Set Wallpaper'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}