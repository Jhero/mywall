import 'package:flutter/material.dart';
import '../../widgets/feature_item.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'About App',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            
            // App Logo
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.blue, Colors.purple],
                ),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.wallpaper_rounded,
                  size: 70,
                  color: Colors.white,
                ),
              ),
            ),
            
            const SizedBox(height: 25),
            
            // App Title
            const Text(
              'WallpaperMy',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.black,
                letterSpacing: 0.5,
              ),
            ),
            
            const SizedBox(height: 8),
            
            // App Version
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Version 1.0.0',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.blue,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            
            const SizedBox(height: 25),
            
            // App Description
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: const Column(
                children: [
                  Text(
                    'About WallpaperMy',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'WallpaperMy is your ultimate destination for beautiful, high-quality wallpapers. '
                    'With our curated collection, you can easily find and set stunning backgrounds for your device. '
                    'Enjoy seamless browsing, instant downloads, and one-tap wallpaper application.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.black87,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 30),
            
            // Features Title
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Key Features',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            
            const SizedBox(height: 15),
            
            // Features List
            Column(
              children: [
                FeatureItem(
                  icon: Icons.collections,
                  title: 'Vast Collection',
                  description: 'Thousands of high-quality wallpapers in various categories',
                  iconColor: Colors.blue,
                ),
                
                FeatureItem(
                  icon: Icons.favorite_rounded,
                  title: 'Favorites',
                  description: 'Save your favorite wallpapers for quick access anytime',
                  iconColor: Colors.red,
                ),
                
                FeatureItem(
                  icon: Icons.category_rounded,
                  title: 'Smart Categories',
                  description: 'Browse by categories like Nature, Abstract, Minimal, and more',
                  iconColor: Colors.green,
                ),
                
                FeatureItem(
                  icon: Icons.wallpaper_rounded,
                  title: 'Easy Application',
                  description: 'Set wallpapers for home screen, lock screen, or both with one tap',
                  iconColor: Colors.purple,
                ),
                
                FeatureItem(
                  icon: Icons.download_rounded,
                  title: 'Offline Access',
                  description: 'Download wallpapers and access them without internet',
                  iconColor: Colors.orange,
                ),
                
                FeatureItem(
                  icon: Icons.star_rounded,
                  title: 'Premium Quality',
                  description: 'All wallpapers are optimized for mobile devices in HD quality',
                  iconColor: Colors.amber,
                ),
              ],
            ),
            
            const SizedBox(height: 30),
            
            // Developer Info Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.blue[100]!),
              ),
              child: Column(
                children: [
                  const Text(
                    'Developed with ❤️ by',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.blueGrey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'WallpaperMy Team',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    'We are passionate about creating beautiful experiences through carefully curated wallpapers.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blueGrey,
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Contact Button
                  ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Row(
                            children: [
                              Icon(Icons.email, color: Colors.white, size: 20),
                              SizedBox(width: 10),
                              Text('Contact us at: jhery.p1000@gmail.com'),
                            ],
                          ),
                          backgroundColor: Colors.blue,
                          duration: Duration(seconds: 3),
                        ),
                      );
                    },
                    icon: const Icon(Icons.email_outlined, size: 20),
                    label: const Text('Contact Support'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 30),
            
            // Footer
            const Text(
              '© 2024 WallpaperMy. All rights reserved.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey,
              ),
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}