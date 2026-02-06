import 'package:flutter/material.dart';
import '../../widgets/feature_item.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'About App',
          style: TextStyle(
            color: Theme.of(context).appBarTheme.foregroundColor ?? Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: Theme.of(context).appBarTheme.elevation ?? 0,
        centerTitle: Theme.of(context).appBarTheme.centerTitle ?? true,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
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
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.secondary
                  ],
                ),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
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
                        
            const SizedBox(height: 40), // ✅ Tambahkan jarak lebih besar
            
            FittedBox(
              fit: BoxFit.scaleDown, // ✅ otomatis mengecil jika layar sempit
              child: Text(
                'My BTS Idol Wallpaper 2026',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                  letterSpacing: 0.5,
                ),
                maxLines: 1,           // ✅ pastikan tetap satu baris
                overflow: TextOverflow.ellipsis,
                softWrap: false,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 8),
            
            // App Version
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Version 1.0.0',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.primary,
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
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Column(
                children: [
                  Text(
                    'About My BTS Wallpaper',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'My BTS Idol Wallpaper is your ultimate destination for beautiful, high-quality wallpapers. '
                    'With our curated collection, you can easily find and set stunning backgrounds for your device. '
                    'Enjoy seamless browsing, instant downloads, and one-tap wallpaper application.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.87),
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 30),
            
            // Features Title
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Key Features',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
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
                  iconColor: Theme.of(context).colorScheme.primary,
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
                  description: 'Browse by categories like Jimin, Jhope, Vee, and more',
                  iconColor: Theme.of(context).colorScheme.secondary,
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
                color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  Text(
                    'Developed with ❤️ by',
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'My BTS Idol Wallpaper Team',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    'We are passionate about creating beautiful experiences through carefully curated wallpapers.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
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
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
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
            Text(
              '© 2026 My BTS Idol Wallpaper. All rights reserved.',
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
