import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'core/utils/environment.dart';
import 'data/services/admob_service.dart';
import 'presentation/providers/ad_provider.dart';
import 'presentation/providers/theme_provider.dart';
import 'presentation/screens/splash_screen.dart';
// import 'presentation/widgets/rating_dialog.dart';
import 'core/themes/app_theme.dart';
import 'package:hive_flutter/hive_flutter.dart';
// import 'helpers/category_cache_helper.dart';

// Import Age Verification Service
import 'services/age_verification_service.dart';
import 'services/websocket_service.dart';

void main() {
  // Opsional: bikin warning zone mismatch jadi fatal saat dev
  // BindingBase.debugZoneErrorsAreFatal = true;

  runZonedGuarded(() async {
    // Pastikan binding diinisialisasi di zone yang sama dengan runApp
    WidgetsFlutterBinding.ensureInitialized();

    await Hive.initFlutter();
    await Hive.openBox('category_cache');

    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      // Bisa tambahkan logger di sini kalau perlu
    };

    try {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);

      try {
        await Environment.load();
        debugPrint('✓ Environment loaded successfully');
        WebSocketService().connect();
      } catch (e) {
        debugPrint('✗ Error loading environment: $e');
      }

      try {
        // Get age signals before initializing AdMob to set proper flags
        final ageSignals = await AgeVerificationService.getAgeSignals();
        final isChildDirected = AgeVerificationService.isUnder13(ageSignals) ||
            AgeVerificationService.isUnderParentalSupervision(ageSignals);
        await AdmobService().initialize(childDirected: isChildDirected);
        debugPrint('✓ AdMob initialized successfully');
      } catch (e) {
        debugPrint('✗ Error initializing AdMob: $e');
      }

      // 🔎 Cek sinyal usia menggunakan service
      final ageSignals = await AgeVerificationService.getAgeSignals();
      debugPrint("✓ Age signals retrieved: $ageSignals");

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
            ChangeNotifierProvider<AdProvider>(
              create: (_) => AdProvider(),
              lazy: false,
            ),
            ChangeNotifierProvider<ThemeProvider>(
              create: (_) => ThemeProvider(),
              lazy: false,
            ),
            // WebSocketService is a singleton; no Provider needed
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
  }, (error, stackTrace) {
    debugPrint('═══════════════════════════════════════════');
    debugPrint('Async Error Caught:');
    debugPrint('Error: $error');
    debugPrint('Stack trace: $stackTrace');
    debugPrint('═══════════════════════════════════════════');
  });
}

class MyApp extends StatelessWidget {
  final Map<String, dynamic> ageSignals;
  const MyApp({super.key, required this.ageSignals});

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context).theme;
    return MaterialApp(
      title: 'My BTS Idol Wallpaper 2026',
      debugShowCheckedModeBanner: false,
      theme: theme,
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
      // home: WillPopScope(
      //   onWillPop: () async {
      //     // intercept tombol back/exit
      //     showDialog(
      //       context: context,
      //       builder: (_) => RatingDialog(), // dialog rating Play Store
      //     );
      //     return false; // cegah keluar langsung
      //   },
      //   child: SplashScreen(ageSignals: ageSignals),
      // ),
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
                  'My BTS Idol Wallpaper 2026',
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
