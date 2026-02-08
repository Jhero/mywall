import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';

class RateUsScreen extends StatelessWidget {
  const RateUsScreen({Key? key}) : super(key: key);

  Future<void> _launchStore(BuildContext context) async {
    final String targetStore = dotenv.env['TARGET_STORE'] ?? 'google_play';
    final String androidAppId = dotenv.env['ANDROID_APP_ID'] ?? 'com.myjovan.mywall';
    final String iosAppId = dotenv.env['IOS_APP_ID'] ?? '';

    Uri deepLink;
    Uri webLink;
    String storeName;

    // Determine URLs based on configuration and platform
    if (Platform.isIOS) {
      storeName = "App Store";
      deepLink = Uri.parse("itms-apps://itunes.apple.com/app/id$iosAppId?action=write-review");
      webLink = Uri.parse("https://apps.apple.com/app/id$iosAppId");
    } else {
      // Android stores
      switch (targetStore) {
        case 'samsung_galaxy':
          storeName = "Galaxy Store";
          deepLink = Uri.parse("samsungapps://ProductDetail/$androidAppId");
          webLink = Uri.parse("https://apps.samsung.com/appMain/ProductDetail.as?appId=$androidAppId");
          break;
        case 'oppo_app_market':
          storeName = "App Market"; // Oppo
          deepLink = Uri.parse("market://details?id=$androidAppId");
          webLink = Uri.parse("https://appmarket.oppomobile.com/app/$androidAppId"); // Generic web fallback if known
          break;
        case 'huawei_appgallery':
          storeName = "AppGallery";
          deepLink = Uri.parse("appmarket://details?id=$androidAppId");
          webLink = Uri.parse("https://appgallery.huawei.com/app/$androidAppId");
          break;
        case 'google_play':
        default:
          storeName = "Google Play";
          deepLink = Uri.parse("market://details?id=$androidAppId");
          webLink = Uri.parse("https://play.google.com/store/apps/details?id=$androidAppId");
          break;
      }
    }

    try {
      // Try to launch the Store app first
      if (!await launchUrl(deepLink, mode: LaunchMode.externalApplication)) {
        // If app fails, try the web link
        if (context.mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text("Could not open $storeName app, opening web version...")),
           );
        }
        await launchUrl(webLink, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
       // Catch any other errors
       if (context.mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text("Error opening store: $e")),
         );
       }
    }
  }

  String _getStoreName() {
    if (Platform.isIOS) return "App Store";
    
    final store = dotenv.env['TARGET_STORE'];
    switch (store) {
      case 'samsung_galaxy': return "Galaxy Store";
      case 'oppo_app_market': return "App Market";
      case 'huawei_appgallery': return "AppGallery";
      default: return "Google Play";
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final storeName = _getStoreName();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text("Rate Us"),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.star_rate_rounded, 
                size: 80, 
                color: Colors.amber[700]
              ),
              const SizedBox(height: 24),
              Text(
                "Enjoying MyWall?",
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                "Your feedback helps us improve.\nPlease rate us on the $storeName!",
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => _launchStore(context),
                icon: const Icon(Icons.store),
                label: const Text("Rate Now"),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 48),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: theme.colorScheme.error, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Note: If you see a 'Page doesn't exist' error, it means this app hasn't been published to the $storeName yet.",
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
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
}
