// lib/screens/wallpaper_detail_screen.dart
import 'package:flutter/material.dart';
import '../../models/gallery.dart';
import '../../services/gallery_service.dart';
import '../../services/favorites_manager.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
// import 'package:share_plus/share_plus'; // HAPUS INI
import 'package:wallpaper_manager_flutter/wallpaper_manager_flutter.dart';

class WallpaperLocation {
  static const int HOME_SCREEN = WallpaperManagerFlutter.homeScreen;
  static const int LOCK_SCREEN = WallpaperManagerFlutter.lockScreen;
  static const int BOTH_SCREEN = WallpaperManagerFlutter.bothScreens;
}

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
  final FavoritesManager _favoritesManager = FavoritesManager();
  final wallpaperManager = WallpaperManagerFlutter();

  @override
  void initState() {
    super.initState();
    if (widget.gallery != null) {
      imageIdentifier = widget.gallery!.imageUrl;
    } else {
      imageIdentifier = widget.imagePath!;
    }
    _checkFavoriteStatus();
  }

  void _checkFavoriteStatus() {
    isFavorite = _favoritesManager.isFavorite(imageIdentifier);
  }

  Future<void> _toggleFavorite() async {
    setState(() {
      isFavorite = !isFavorite;
    });

    // Update favorite status in manager
    if (isFavorite) {
      await _favoritesManager.addFavorite(imageIdentifier);
    } else {
      await _favoritesManager.removeFavorite(imageIdentifier);
    }

    // Notify parent widget if callback is provided
    if (widget.onFavoriteChanged != null) {
      widget.onFavoriteChanged!();
    }
  }

  Future<void> _downloadWallpaper() async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text("Downloading wallpaper..."),
            ],
          ),
        ),
      );

      Uint8List imageBytes;
      String fileName;
      String fileType = 'jpg';
      
      if (widget.gallery != null) {
        // Download from API
        final imageUrl = GalleryService.getImageUrl(widget.gallery!.imageUrl);
        final response = await http.get(
          Uri.parse(imageUrl),
          headers: {'X-API-Key': GalleryService.apiKey},
        );
        
        if (response.statusCode != 200) {
          throw Exception('Failed to download image: ${response.statusCode}');
        }
        
        imageBytes = response.bodyBytes;
        
        // Extract file type from URL or content type
        if (imageUrl.toLowerCase().contains('.png')) {
          fileType = 'png';
        } else if (imageUrl.toLowerCase().contains('.jpeg') || imageUrl.toLowerCase().contains('.jpg')) {
          fileType = 'jpg';
        } else if (imageUrl.toLowerCase().contains('.webp')) {
          fileType = 'webp';
        }
        
        fileName = 'wallpaper_${widget.gallery!.title.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}_${DateTime.now().millisecondsSinceEpoch}.$fileType';
      } else {
        // Handle local asset
        final ByteData data = await DefaultAssetBundle.of(context).load(widget.imagePath!);
        imageBytes = data.buffer.asUint8List();
        
        // Extract file type from asset path
        if (widget.imagePath!.toLowerCase().contains('.png')) {
          fileType = 'png';
        } else if (widget.imagePath!.toLowerCase().contains('.jpeg') || widget.imagePath!.toLowerCase().contains('.jpg')) {
          fileType = 'jpg';
        }
        
        fileName = 'local_wallpaper_${DateTime.now().millisecondsSinceEpoch}.$fileType';
      }

      // Get downloads directory (works for both Android and iOS)
      final directory = await getDownloadsDirectory();
      if (directory == null) {
        throw Exception('Could not access downloads directory');
      }

      final filePath = '${directory.path}/$fileName';
      final File file = File(filePath);
      await file.writeAsBytes(imageBytes);

      // Close loading dialog
      Navigator.of(context).pop();

      // Show comprehensive success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text('Download Successful!', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Saved to: ${directory.path}',
                style: const TextStyle(fontSize: 12),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                'File: $fileName',
                style: const TextStyle(fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {
              // Hanya dismiss snackbar, share dihapus
            },
          ),
        ),
      );

    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Row(
                children: [
                  Icon(Icons.error, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text('Download Failed', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Error: ${e.toString()}',
                style: const TextStyle(fontSize: 12),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  // HAPUS METHOD _shareDownloadedFile() atau komen saja:
  /*
  Future<void> _shareDownloadedFile(String filePath) async {
    try {
      await Share.shareXFiles(
        [XFile(filePath)],
        text: 'Check out this amazing wallpaper I downloaded! 🎨',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cannot share file: ${e.toString()}'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }
  */

  Future<void> _setAsWallpaper() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text("Preparing wallpaper..."),
            ],
          ),
        ),
      );

      String filePath;
      
      if (widget.gallery != null) {
        final imageUrl = GalleryService.getImageUrl(widget.gallery!.imageUrl);
        final response = await http.get(
          Uri.parse(imageUrl),
          headers: {'X-API-Key': GalleryService.apiKey},
        );
        
        if (response.statusCode != 200) {
          throw Exception('Failed to download image: ${response.statusCode}');
        }
        
        final tempDir = await getTemporaryDirectory();
        filePath = '${tempDir.path}/wallpaper_${DateTime.now().millisecondsSinceEpoch}.jpg';
        await File(filePath).writeAsBytes(response.bodyBytes);
      } else {
        // Untuk local asset, kita perlu menyalin ke file temporary
        final ByteData data = await DefaultAssetBundle.of(context).load(widget.imagePath!);
        final tempDir = await getTemporaryDirectory();
        filePath = '${tempDir.path}/wallpaper_${DateTime.now().millisecondsSinceEpoch}.jpg';
        await File(filePath).writeAsBytes(data.buffer.asUint8List());
      }

      Navigator.of(context).pop(); 

      // Show location selection dialog
      final location = await showDialog<int>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Set Wallpaper'),
          content: const Text('Where would you like to set this wallpaper?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, WallpaperLocation.HOME_SCREEN),
              child: const Text('Home Screen'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, WallpaperLocation.LOCK_SCREEN),
              child: const Text('Lock Screen'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, WallpaperLocation.BOTH_SCREEN),
              child: const Text('Both'),
            ),
          ],
        ),
      );

      if (location != null) {
        await _applyWallpaper(filePath, location);
      }

    } catch (e) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _applyWallpaper(String filePath, int location) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text("Applying wallpaper..."),
            ],
          ),
        ),
      );

      File imageFile = File(filePath);
      
      bool result = await wallpaperManager.setWallpaper(
        imageFile,
        location,
      );

      Navigator.of(context).pop();
      
      if (result) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Wallpaper set successfully! 🎉'),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.warning, color: Colors.white),
                SizedBox(width: 8),
                Text('Failed to set wallpaper. Please try again.'),
              ],
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Failed to apply wallpaper: ${e.toString()}'),
              ),
            ],
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // MODIFIKASI method _shareWallpaper() atau HAPUS/komentari:
  Future<void> _shareWallpaper() async {
    // Tampilkan pesan bahwa fitur share sedang tidak tersedia
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.info, color: Colors.white),
            SizedBox(width: 8),
            Text('Share feature is temporarily unavailable'),
          ],
        ),
        backgroundColor: Colors.blue,
      ),
    );
    
    // ATAU hapus tombol share dari UI dengan mengubah build method
  }

  Widget _buildImage() {
    if (widget.gallery != null) {
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
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 16),
                  Text(
                    'Loading wallpaper...',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load image',
                    style: TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Error: ${snapshot.error}',
                    style: TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          } else if (snapshot.hasData && snapshot.data!.statusCode == 200) {
            return Image.memory(
              snapshot.data!.bodyBytes,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.broken_image,
                        color: Colors.red,
                        size: 64,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Failed to display image',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                );
              },
            );
          } else {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error,
                    color: Colors.red,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'HTTP Error: ${snapshot.data?.statusCode ?? 'Unknown'}',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            );
          }
        },
      );
    } else {
      return Image.asset(
        widget.imagePath!,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.broken_image,
                  color: Colors.red,
                  size: 64,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Failed to load asset',
                  style: TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  'Path: ${widget.imagePath}',
                  style: TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
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
            tooltip: isFavorite ? 'Remove from favorites' : 'Add to favorites',
          ),
          IconButton(
            onPressed: _downloadWallpaper,
            icon: const Icon(Icons.download, color: Colors.white),
            tooltip: 'Download wallpaper',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: InteractiveViewer(
              panEnabled: true,
              scaleEnabled: true,
              minScale: 0.5,
              maxScale: 3.0,
              child: Center(
                child: _buildImage(),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[900]!.withOpacity(0.95),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 16),
                // Hanya tampilkan tombol Set Wallpaper, hapus tombol Share
                ElevatedButton.icon(
                  onPressed: _setAsWallpaper,
                  icon: const Icon(Icons.wallpaper),
                  label: const Text('Set as Wallpaper'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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