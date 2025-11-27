import 'package:flutter/material.dart';
import '../../widgets/feature_item.dart';

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
            
            FeatureItem(
              icon: Icons.photo_library, 
              title: 'Beautiful Wallpapers', 
              description: 'Access a wide collection of high-quality wallpapers'
            ),
            
            FeatureItem(
              icon: Icons.favorite, 
              title: 'Favorites', 
              description: 'Save your favorite wallpapers for quick access'
            ),
            
            FeatureItem(
              icon: Icons.format_paint, 
              title: 'Categories', 
              description: 'Browse wallpapers by category for easy discovery'
            ),
            
            FeatureItem(
              icon: Icons.wallpaper, 
              title: 'Easy Application', 
              description: 'Set wallpapers for home screen, lock screen, or both'
            ),
            
            FeatureItem(
              icon: Icons.share, 
              title: 'Share', 
              description: 'Share wallpapers with friends and family'
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
}