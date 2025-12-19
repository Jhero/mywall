import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'core/utils/environment.dart';
import 'data/services/admob_service.dart';
import 'presentation/providers/ad_provider.dart';
import 'presentation/screens/splash_screen.dart';
import 'core/themes/app_theme.dart';

void main() {
  // Tangkap semua error Flutter framework
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('═══════════════════════════════════════════');
    debugPrint('Flutter Error Caught:');
    debugPrint('Error: ${details.exception}');
    debugPrint('Stack trace: ${details.stack}');
    debugPrint('═══════════════════════════════════════════');
  };

  // Tangkap error async yang tidak tertangani
  runZonedGuarded(
    () async {
      // Pastikan Flutter sudah terinisialisasi
      WidgetsFlutterBinding.ensureInitialized();
      
      try {
        // Set orientasi portrait saja
        await SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ]);
        
        // Load environment dengan error handling
        try {
          await Environment.load();
          debugPrint('✓ Environment loaded successfully');
        } catch (e) {
          debugPrint('✗ Error loading environment: $e');
          // Continue anyway, bisa pakai default values
        }
        
        // Initialize Admob dengan error handling
        try {
          await AdmobService().initialize();
          debugPrint('✓ AdMob initialized successfully');
        } catch (e) {
          debugPrint('✗ Error initializing AdMob: $e');
          // Continue anyway, app masih bisa jalan tanpa ads
        }
        
        // Run app
        runApp(
          MultiProvider(
            providers: [
              ChangeNotifierProvider(
                create: (_) => AdProvider(),
                lazy: false, // Load immediately
              ),
            ],
            child: const MyApp(),
          ),
        );
      } catch (e, stackTrace) {
        debugPrint('═══════════════════════════════════════════');
        debugPrint('Critical Error in main():');
        debugPrint('Error: $e');
        debugPrint('Stack trace: $stackTrace');
        debugPrint('═══════════════════════════════════════════');
        
        // Tetap run app dengan minimal config
        runApp(const ErrorRecoveryApp());
      }
    },
    (error, stackTrace) {
      debugPrint('═══════════════════════════════════════════');
      debugPrint('Async Error Caught:');
      debugPrint('Error: $error');
      debugPrint('Stack trace: $stackTrace');
      debugPrint('═══════════════════════════════════════════');
    },
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My BTS Wallpaper',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      
      // Error handler untuk widget build errors
      builder: (context, widget) {
        // Custom error widget
        ErrorWidget.builder = (FlutterErrorDetails errorDetails) {
          return MaterialApp(
            home: Scaffold(
              backgroundColor: Colors.white,
              body: SafeArea(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Oops! Something went wrong',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Please restart the app',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () {
                            SystemNavigator.pop();
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Close App'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        };
        
        return widget ?? const SizedBox.shrink();
      },
      
      home: const SplashScreen(),
    );
  }
}

// Fallback app jika ada critical error
class ErrorRecoveryApp extends StatelessWidget {
  const ErrorRecoveryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    size: 80,
                    color: Colors.orange,
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'My BTS Wallpaper',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'The app encountered an error during startup.\nPlease try again.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: () {
                      SystemNavigator.pop();
                    },
                    icon: const Icon(Icons.close),
                    label: const Text('Close App'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}