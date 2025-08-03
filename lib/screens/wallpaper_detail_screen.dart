// lib/screens/wallpaper_detail_screen.dart
import 'package:flutter/material.dart';
import '../models/gallery.dart';
import '../services/gallery_service.dart';
import '../services/favorites_manager.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class WallpaperDetailScreen extends StatefulWidget {
  final Gallery? gallery;
  final String? imagePath;
  final VoidCallback? onFavoriteChanged;

  const WallpaperDetailScreen({
    Key? key,
    this.gallery,
    this.imagePath,
    this.onFavoriteChanged,
  }) : assert(gallery != null || imagePath != null, 'Either gallery or imagePath must be provided'),
       super(key: key);

  // Named constructor for Gallery objects
  const WallpaperDetailScreen.fromGallery({
    Key? key,
    required Gallery gallery,
    this.onFavoriteChanged,
  }) : gallery = gallery,
       imagePath = null,
       super(key: key);

  // Named constructor for local assets
  const WallpaperDetailScreen.fromAsset({
    Key? key,
    required String imagePath,
    this.onFavoriteChanged,
  }) : gallery = null,
       imagePath = imagePath,
       super(key: key);

  @override
  State<WallpaperDetailScreen> createState() => _WallpaperDetailScreenState();
}

class _WallpaperDetailScreenState extends State<WallpaperDetailScreen> {
  late bool isFavorite;
  late String imageIdentifier;
  late String title;
  late String description;

  @override
  void initState() {
    super.initState();
    if (widget.gallery != null) {
      imageIdentifier = widget.gallery!.imageUrl;
      title = widget.gallery!.title;
      description = widget.gallery!.description;
    } else {
      imageIdentifier = widget.imagePath!;
      title = 'Local Wallpaper';
      description = '';
    }
    isFavorite = FavoritesManager().isFavorite(imageIdentifier);
  }

  void _toggleFavorite() {
    setState(() {
      isFavorite = !isFavorite;
      FavoritesManager().toggleFavorite(imageIdentifier);
      if (widget.onFavoriteChanged != null) {
        widget.onFavoriteChanged!();
      }
    });
  }

  Future<void> _setAsWallpaper() async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text("Preparing wallpaper..."),
              ],
            ),
          );
        },
      );

      Uint8List imageBytes;
      
      if (widget.gallery != null) {
        // For API images, download the image first
        final imageUrl = GalleryService.getImageUrl(widget.gallery!.imageUrl);
        final response = await http.get(
          Uri.parse(imageUrl),
          headers: {
            'X-API-Key': GalleryService.apiKey,
          },
        );
        
        if (response.statusCode != 200) {
          throw Exception('Failed to download image');
        }
        
        imageBytes = response.bodyBytes;
      } else {
        // For local assets, load from assets
        final ByteData data = await DefaultAssetBundle.of(context).load(widget.imagePath!);
        imageBytes = data.buffer.asUint8List();
      }

      // Save image to documents directory
      final documentsDir = await getApplicationDocumentsDirectory();
      final wallpaperDir = Directory('${documentsDir.path}/wallpapers');
      if (!await wallpaperDir.exists()) {
        await wallpaperDir.create(recursive: true);
      }
      
      final wallpaperFile = File('${wallpaperDir.path}/wallpaper_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await wallpaperFile.writeAsBytes(imageBytes);

      // Close loading dialog
      Navigator.of(context).pop();

      // Show success dialog with instructions
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Wallpaper Saved!'),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('The wallpaper has been saved to your device.'),
                SizedBox(height: 16),
                Text('To set it as wallpaper:'),
                SizedBox(height: 8),
                Text('1. Go to your device Settings'),
                Text('2. Find "Wallpaper" or "Display"'),
                Text('3. Select "Set wallpaper"'),
                Text('4. Choose the saved image'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );

    } catch (e) {
      // Close loading dialog
      Navigator.of(context).pop();
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save wallpaper: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _shareWallpaper() async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text("Preparing to share..."),
              ],
            ),
          );
        },
      );

      Uint8List imageBytes;
      
      if (widget.gallery != null) {
        // For API images, download the image first
        final imageUrl = GalleryService.getImageUrl(widget.gallery!.imageUrl);
        final response = await http.get(
          Uri.parse(imageUrl),
          headers: {
            'X-API-Key': GalleryService.apiKey,
          },
        );
        
        if (response.statusCode != 200) {
          throw Exception('Failed to download image');
        }
        
        imageBytes = response.bodyBytes;
      } else {
        // For local assets, load from assets
        final ByteData data = await DefaultAssetBundle.of(context).load(widget.imagePath!);
        imageBytes = data.buffer.asUint8List();
      }

      // Save image to temporary file for sharing
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/wallpaper_share_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await tempFile.writeAsBytes(imageBytes);

      // Close loading dialog
      Navigator.of(context).pop();

      // Share the image
      await Share.shareXFiles(
        [XFile(tempFile.path)],
        text: 'Check out this beautiful wallpaper!',
      );

      // Clean up temporary file
      await tempFile.delete();

    } catch (e) {
      // Close loading dialog
      Navigator.of(context).pop();
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to share wallpaper: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildImage() {
    if (widget.gallery != null) {
      // Handle gallery images (from API)
      final imageUrl = GalleryService.getImageUrl(widget.gallery!.imageUrl);
      return FutureBuilder<http.Response>(
        future: http.get(
          Uri.parse(imageUrl),
          headers: {
            'X-API-Key': GalleryService.apiKey,
          },
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.white));
          } else if (snapshot.hasError) {
            return const Center(
              child: Icon(
                Icons.error,
                color: Colors.red,
                size: 100,
              ),
            );
          } else if (snapshot.hasData && snapshot.data!.statusCode == 200) {
            return Image.memory(
              snapshot.data!.bodyBytes,
              fit: BoxFit.contain,
            );
          } else {
            return const Center(
              child: Icon(
                Icons.error,
                color: Colors.red,
                size: 100,
              ),
            );
          }
        },
      );
    } else {
      // Handle local asset images
      return Image.asset(
        widget.imagePath!,
        fit: BoxFit.contain,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            onPressed: _toggleFavorite,
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: isFavorite ? Colors.red : Colors.white,
            ),
          ),
          IconButton(
            onPressed: () {
              // Add download functionality here
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Download functionality not implemented'),
                ),
              );
            },
            icon: const Icon(Icons.download, color: Colors.white),
          ),
        ],
      ),
      body: Column(
        children: [
          // Image viewer
          Expanded(
            child: InteractiveViewer(
              child: Center(
                child: _buildImage(),
              ),
            ),
          ),
          // Bottom info panel
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _setAsWallpaper,
                        icon: const Icon(Icons.wallpaper),
                        label: const Text('Set as Wallpaper'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _shareWallpaper,
                        icon: const Icon(Icons.share),
                        label: const Text('Share'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}