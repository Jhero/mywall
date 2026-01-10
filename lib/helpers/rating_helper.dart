import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';

class RatingHelper {
  // Keys untuk menyimpan data di SharedPreferences
  static const String _keyLastPrompt = 'last_rating_prompt_date';
  static const String _keyAppLaunches = 'app_launch_count';
  static const String _keyHasRated = 'user_has_rated';
  static const String _keyFirstLaunchDate = 'first_launch_date';

  // Konfigurasi - Sesuaikan dengan kebutuhan Anda
  static const int minLaunchesBeforePrompt = 5; // Minimal 5x buka app
  static const int daysBetweenPrompts = 30; // Jeda 30 hari antar prompt
  static const int daysAfterFirstLaunch = 3; // Tunggu 3 hari sejak install

  // ============================================
  // METHOD 1: Increment App Launches
  // ============================================
  static Future<void> incrementAppLaunches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Ambil jumlah launches saat ini
      int currentLaunches = prefs.getInt(_keyAppLaunches) ?? 0;
      
      // Increment
      int newLaunches = currentLaunches + 1;
      
      // Simpan kembali
      await prefs.setInt(_keyAppLaunches, newLaunches);
      
      // Simpan tanggal first launch jika belum ada
      if (!prefs.containsKey(_keyFirstLaunchDate)) {
        await prefs.setString(
          _keyFirstLaunchDate,
          DateTime.now().toIso8601String(),
        );
      }
      
      debugPrint('📱 App launched: $newLaunches times');
    } catch (e) {
      debugPrint('❌ Error incrementing app launches: $e');
    }
  }

  // ============================================
  // METHOD 2: Cek Apakah Harus Tampilkan Dialog
  // ============================================
  static Future<bool> shouldShowRatingPrompt() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 1. Cek apakah user sudah pernah rating
      bool hasRated = prefs.getBool(_keyHasRated) ?? false;
      if (hasRated) {
        debugPrint('✅ User sudah rating, jangan tampilkan lagi');
        return false;
      }
      
      // 2. Cek jumlah launches
      int launches = prefs.getInt(_keyAppLaunches) ?? 0;
      if (launches < minLaunchesBeforePrompt) {
        debugPrint('🔢 Launch count: $launches/$minLaunchesBeforePrompt');
        return false;
      }
      
      // 3. Cek berapa lama sejak first launch
      String? firstLaunchStr = prefs.getString(_keyFirstLaunchDate);
      if (firstLaunchStr != null) {
        DateTime firstLaunch = DateTime.parse(firstLaunchStr);
        int daysSinceFirstLaunch = DateTime.now().difference(firstLaunch).inDays;
        
        if (daysSinceFirstLaunch < daysAfterFirstLaunch) {
          debugPrint('📅 Days since install: $daysSinceFirstLaunch/$daysAfterFirstLaunch');
          return false;
        }
      }
      
      // 4. Cek apakah sudah pernah ditampilkan sebelumnya
      String? lastPromptStr = prefs.getString(_keyLastPrompt);
      if (lastPromptStr != null) {
        DateTime lastPrompt = DateTime.parse(lastPromptStr);
        int daysSinceLastPrompt = DateTime.now().difference(lastPrompt).inDays;
        
        if (daysSinceLastPrompt < daysBetweenPrompts) {
          debugPrint('⏰ Days since last prompt: $daysSinceLastPrompt/$daysBetweenPrompts');
          return false;
        }
      }
      
      // Semua kondisi terpenuhi!
      debugPrint('⭐ Showing rating prompt!');
      return true;
      
    } catch (e) {
      debugPrint('❌ Error checking rating prompt: $e');
      return false;
    }
  }

  // ============================================
  // METHOD 3: Simpan Bahwa User Sudah Rating
  // ============================================
  static Future<void> markAsRated() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyHasRated, true);
      debugPrint('✅ User marked as rated');
    } catch (e) {
      debugPrint('❌ Error marking as rated: $e');
    }
  }

  // ============================================
  // METHOD 4: Simpan Waktu Terakhir Prompt Ditampilkan
  // ============================================
  static Future<void> saveLastPromptDate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _keyLastPrompt,
        DateTime.now().toIso8601String(),
      );
      debugPrint('📅 Last prompt date saved');
    } catch (e) {
      debugPrint('❌ Error saving last prompt date: $e');
    }
  }

  // ============================================
  // METHOD 5: Reset Semua Data (untuk testing)
  // ============================================
  static Future<void> resetRatingData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyLastPrompt);
      await prefs.remove(_keyAppLaunches);
      await prefs.remove(_keyHasRated);
      await prefs.remove(_keyFirstLaunchDate);
      debugPrint('🔄 Rating data reset');
    } catch (e) {
      debugPrint('❌ Error resetting rating data: $e');
    }
  }

  // ============================================
  // METHOD 6: Tampilkan Dialog Otomatis
  // ============================================
  static Future<void> showRatingDialogIfNeeded(BuildContext context) async {
    // Tunggu sebentar agar UI sudah fully loaded
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (!context.mounted) return;
    
    // Cek apakah harus tampilkan
    if (await shouldShowRatingPrompt()) {
      final result = await showDialog<bool>(
        context: context,
        barrierDismissible: false, // User harus pilih salah satu
        builder: (_) => const RatingDialog(),
      );

      // Simpan status
      await saveLastPromptDate();
      
      if (result == true) {
        await markAsRated();
      }
    }
  }

  // ============================================
  // METHOD 7: Get Statistics (untuk debugging)
  // ============================================
  static Future<Map<String, dynamic>> getStatistics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      return {
        'launches': prefs.getInt(_keyAppLaunches) ?? 0,
        'hasRated': prefs.getBool(_keyHasRated) ?? false,
        'lastPrompt': prefs.getString(_keyLastPrompt),
        'firstLaunch': prefs.getString(_keyFirstLaunchDate),
      };
    } catch (e) {
      debugPrint('❌ Error getting statistics: $e');
      return {};
    }
  }
}

// ============================================
// RATING DIALOG
// ============================================

class RatingDialog extends StatefulWidget {
  const RatingDialog({super.key});

  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
  final InAppReview _inAppReview = InAppReview.instance;
  bool _isLoading = false;
  String _errorMessage = '';

  Future<void> _requestReview() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final isAvailable = await _inAppReview.isAvailable();
      
      if (isAvailable) {
        // Tampilkan native in-app review dialog
        await _inAppReview.requestReview();
      } else {
        // Fallback: Buka Play Store/App Store
        await _inAppReview.openStoreListing(
          appStoreId: 'com.myjovan.mywall', // Ganti dengan App Store ID untuk iOS
        );
      }
      
      if (mounted) {
        Navigator.pop(context, true); // true = user sudah rating
      }
    } catch (e) {
      debugPrint('❌ Error requesting review: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = "Sorry, we couldn't open the rating dialog. Please try again.";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          Icon(Icons.star_rounded, color: Colors.amber[700], size: 28),
          const SizedBox(width: 8),
          const Text("Rate Our App"),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "Are you enjoying our app?",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          const Text(
            "Please give us a rating to help us improve! ⭐",
            style: TextStyle(fontSize: 14, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          if (_errorMessage.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage,
                      style: const TextStyle(color: Colors.red, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (_isLoading) ...[
            const SizedBox(height: 16),
            const CircularProgressIndicator(),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context, false),
          child: const Text("Later"),
        ),
        ElevatedButton.icon(
          onPressed: _isLoading ? null : _requestReview,
          icon: const Icon(Icons.star, size: 18),
          label: const Text("Rate Now"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amber[700],
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================
// EXAMPLE: Debug Screen (untuk testing)
// ============================================

class RatingDebugScreen extends StatefulWidget {
  const RatingDebugScreen({super.key});

  @override
  State<RatingDebugScreen> createState() => _RatingDebugScreenState();
}

class _RatingDebugScreenState extends State<RatingDebugScreen> {
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final stats = await RatingHelper.getStatistics();
    setState(() => _stats = stats);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rating Debug')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('App Launches: ${_stats['launches'] ?? 0}'),
            Text('Has Rated: ${_stats['hasRated'] ?? false}'),
            Text('Last Prompt: ${_stats['lastPrompt'] ?? 'Never'}'),
            Text('First Launch: ${_stats['firstLaunch'] ?? 'Unknown'}'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await RatingHelper.incrementAppLaunches();
                _loadStats();
              },
              child: const Text('Increment Launch'),
            ),
            ElevatedButton(
              onPressed: () async {
                await RatingHelper.showRatingDialogIfNeeded(context);
                _loadStats();
              },
              child: const Text('Test Rating Dialog'),
            ),
            ElevatedButton(
              onPressed: () async {
                await RatingHelper.resetRatingData();
                _loadStats();
              },
              child: const Text('Reset All Data'),
            ),
          ],
        ),
      ),
    );
  }
}