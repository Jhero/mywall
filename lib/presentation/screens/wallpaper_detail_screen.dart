// lib/screens/wallpaper_detail_screen.dart
import 'package:flutter/material.dart';
import '../../models/gallery.dart';
import '../../services/gallery_service.dart';
import '../../services/favorites_manager.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart'; // UNCOMMENT INI
import 'package:wallpaper_manager_flutter/wallpaper_manager_flutter.dart';
import 'dart:ui' as ui;
import 'package:image/image.dart' as img;

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
  bool _isSharing = false;

  @override
  void initState() {
    super.initState();
    if (widget.gallery != null) {
      imageIdentifier = widget.gallery!.imageUrl ?? '';
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
        final imageUrl = GalleryService.getImageUrl(widget.gallery!.imageUrl ?? '');
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
        
        fileName = 'wallpaper_${(widget.gallery!.title ?? '') .replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}_${DateTime.now().millisecondsSinceEpoch}.$fileType';
        // fileName = 'wallpaper_${widget.gallery!.title.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}_${DateTime.now().millisecondsSinceEpoch}.$fileType';
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
            label: 'SHARE',
            textColor: Colors.white,
            onPressed: () {
              _shareDownloadedFile(filePath);
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

  Future<void> _shareDownloadedFile(String filePath) async {
    try {
      await Share.shareXFiles(
        [XFile(filePath)],
        text: 'Check out this amazing wallpaper from WallpaperMy app! 📱🎨',
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

  Future<void> _shareWallpaper() async {
    if (_isSharing) return;
    
    setState(() {
      _isSharing = true;
    });

    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 20),
              Text(_isSharing ? "Sharing..." : "Preparing..."),
            ],
          ),
        ),
      );

      Uint8List imageBytes;
      String fileName;
      
      if (widget.gallery != null) {
        final imageUrl = GalleryService.getImageUrl(widget.gallery!.imageUrl ?? '');
        final response = await http.get(
          Uri.parse(imageUrl),
          headers: {'X-API-Key': GalleryService.apiKey},
        );
        
        if (response.statusCode != 200) {
          throw Exception('Failed to load image: ${response.statusCode}');
        }
        
        imageBytes = response.bodyBytes;
        fileName = 'wallpaper_${(widget.gallery!.title ?? '')
        .replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}.jpg';        
        // fileName = 'wallpaper_${widget.gallery!.title.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}.jpg';
      } else {
        final ByteData data = await DefaultAssetBundle.of(context).load(widget.imagePath!);
        imageBytes = data.buffer.asUint8List();
        fileName = 'wallpaper_${widget.imagePath!.split('/').last}';
      }

      // Save to temporary file
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/$fileName');
      await tempFile.writeAsBytes(imageBytes);

      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Share the file
      await Share.shareXFiles(
        [XFile(tempFile.path)],
        text: 'Check out this beautiful wallpaper from WallpaperMy app! 🖼️✨\n\nDownload WallpaperMy for more amazing wallpapers!',
      );

      // Clean up temporary file after a delay
      Future.delayed(const Duration(seconds: 10), () async {
        try {
          if (await tempFile.exists()) {
            await tempFile.delete();
          }
        } catch (e) {
          // Ignore cleanup errors
        }
      });

    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('Failed to share: ${e.toString()}'),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSharing = false;
        });
      }
    }
  }

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
        final imageUrl = GalleryService.getImageUrl(widget.gallery!.imageUrl ?? '');
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

  Widget _buildImage() {
    if (widget.gallery != null) {
      final imageUrl = GalleryService.getImageUrl(widget.gallery!.imageUrl ?? '');
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        actions: [
          IconButton(
            onPressed: _toggleFavorite,
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: isFavorite
                  ? Colors.red
                  : (Theme.of(context).appBarTheme.foregroundColor ??
                      Theme.of(context).colorScheme.onSurface),
            ),
            tooltip: isFavorite ? 'Remove from favorites' : 'Add to favorites',
          ),
          IconButton(
            onPressed: _downloadWallpaper,
            icon: Icon(
              Icons.download,
              color: Theme.of(context).appBarTheme.foregroundColor ??
                  Theme.of(context).colorScheme.onSurface,
            ),
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
              color: Theme.of(context).colorScheme.surface.withOpacity(0.95),
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
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _setAsWallpaper,
                        icon: const Icon(Icons.wallpaper),
                        label: const Text('Set Wallpaper'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Theme.of(context).colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isSharing ? null : _shareWallpaper,
                        icon: _isSharing
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.share),
                        label: Text(_isSharing ? 'Sharing...' : 'Share'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.secondary,
                          foregroundColor: Theme.of(context).colorScheme.onSecondary,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
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
