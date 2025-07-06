// lib/widgets/wallpaper_grid.dart
import 'package:flutter/material.dart';
import '../models/gallery.dart';
import '../services/gallery_service.dart';

class WallpaperGrid extends StatefulWidget {
  const WallpaperGrid({Key? key}) : super(key: key);

  @override
  State<WallpaperGrid> createState() => _WallpaperGridState();
}

class _WallpaperGridState extends State<WallpaperGrid> {
  List<Gallery> galleries = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadGalleries();
  }

  Future<void> _loadGalleries() async {
    try {
      final fetchedGalleries = await GalleryService.fetchGalleries();
      setState(() {
        galleries = fetchedGalleries;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  Future<void> _refreshGalleries() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    await _loadGalleries();
  }

  Widget _buildWallpaperItem(Gallery gallery, {double ratio = 16/9}) {
    return AspectRatio(
      aspectRatio: ratio,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                GalleryService.getImageUrl(gallery.imageUrl),
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: Colors.grey[300],
                    child: Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[300],
                    child: const Icon(
                      Icons.error,
                      color: Colors.red,
                      size: 50,
                    ),
                  );
                },
              ),
              // Gradient overlay for better text readability
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.3),
                    ],
                  ),
                ),
              ),
              // Title overlay
              Positioned(
                bottom: 8,
                left: 8,
                right: 8,
                child: Text(
                  gallery.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        offset: Offset(0, 1),
                        blurRadius: 3,
                        color: Colors.black45,
                      ),
                    ],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGalleryGrid() {
    if (galleries.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text(
            'No galleries found',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      );
    }

    List<Widget> rows = [];
    for (int i = 0; i < galleries.length; i += 2) {
      Widget leftItem = Expanded(
        child: _buildWallpaperItem(
          galleries[i],
          ratio: i % 4 == 0 ? 16/9 : 9/16, // Alternate ratios
        ),
      );

      Widget rightItem = i + 1 < galleries.length
          ? Expanded(
              child: _buildWallpaperItem(
                galleries[i + 1],
                ratio: i % 4 == 0 ? 9/16 : 16/9, // Alternate ratios
              ),
            )
          : const Expanded(child: SizedBox());

      rows.add(
        Row(
          children: [
            leftItem,
            const SizedBox(width: 8),
            rightItem,
          ],
        ),
      );

      if (i + 2 < galleries.length) {
        rows.add(const SizedBox(height: 8));
      }
    }

    return Column(children: rows);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          if (isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              ),
            )
          else if (errorMessage != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 48,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      errorMessage!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _refreshGalleries,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          else
            _buildGalleryGrid(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}