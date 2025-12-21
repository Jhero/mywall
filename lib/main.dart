import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'core/utils/environment.dart';
import 'data/services/admob_service.dart';
import 'presentation/providers/ad_provider.dart';
import 'presentation/screens/splash_screen.dart';
import 'core/themes/app_theme.dart';

// Import Age Verification Service
import 'services/age_verification_service.dart';

void main() {
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('═══════════════════════════════════════════');
    debugPrint('Flutter Error Caught:');
    debugPrint('Error: ${details.exception}');
    debugPrint('Stack trace: ${details.stack}');
    debugPrint('═══════════════════════════════════════════');
  };

  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      try {
        await SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ]);

        try {
          await Environment.load();
          debugPrint('✓ Environment loaded successfully');
        } catch (e) {
          debugPrint('✗ Error loading environment: $e');
        }

        try {
          await AdmobService().initialize();
          debugPrint('✓ AdMob initialized successfully');
        } catch (e) {
          debugPrint('✗ Error initializing AdMob: $e');
        }

        // 🔎 Cek sinyal usia menggunakan service
        final ageSignals = await AgeVerificationService.getAgeSignals();
        debugPrint("✓ Age signals retrieved: $ageSignals");
        
        // Log informasi tambahan
        if (AgeVerificationService.isUnder13(ageSignals)) {
          debugPrint("⚠️ User is under 13 years old");
        }
        if (AgeVerificationService.isUnderParentalSupervision(ageSignals)) {
          debugPrint("👨‍👩‍👧 User is under parental supervision");
        }
        debugPrint("📊 Age range: ${AgeVerificationService.getAgeRange(ageSignals)}");

        runApp(
          MultiProvider(
            providers: [
              ChangeNotifierProvider(
                create: (_) => AdProvider(),
                lazy: false,
              ),
            ],
            child: MyApp(ageSignals: ageSignals),
          ),
        );
      } catch (e, stackTrace) {
        debugPrint('═══════════════════════════════════════════');
        debugPrint('Critical Error in main():');
        debugPrint('Error: $e');
        debugPrint('Stack trace: $stackTrace');
        debugPrint('═══════════════════════════════════════════');

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
  final Map<String, dynamic> ageSignals;
  const MyApp({super.key, required this.ageSignals});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My BTS Wallpaper 2026',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      builder: (context, widget) {
        ErrorWidget.builder = (FlutterErrorDetails errorDetails) {
          return MaterialApp(
            home: Scaffold(
              body: Center(child: Text("Oops! Something went wrong")),
            ),
          );
        };
        return widget ?? const SizedBox.shrink();
      },
      home: SplashScreen(ageSignals: ageSignals),
    );
  }
}

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
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.warning_amber_rounded,
                    size: 80, color: Colors.orange),
                const SizedBox(height: 32),
                const Text(
                  'My BTS Wallpaper 2026',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87),
                ),
                const SizedBox(height: 16),
                const Text(
                  'The app encountered an error during startup.\nPlease try again.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey),
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
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}