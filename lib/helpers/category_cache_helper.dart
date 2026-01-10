import 'package:hive/hive.dart';

class CategoryCacheHelper {
  static const String _boxName = 'category_cache';
  static const String _dataKey = 'categories';
  static const String _timeKey = 'cached_time';

  static const Duration expiryDuration = Duration(hours: 24);

  static Box get _box => Hive.box(_boxName);

  /// Save categories + timestamp
  static Future<void> save(List<Map<String, dynamic>> categories) async {
    await _box.put(_dataKey, categories);
    await _box.put(_timeKey, DateTime.now().millisecondsSinceEpoch);
  }

  /// Load categories if exists & not expired
  static List<Map<String, dynamic>>? loadIfValid() {
    final cachedTime = _box.get(_timeKey);
    final cachedData = _box.get(_dataKey);

    if (cachedTime == null || cachedData == null) return null;

    final cachedDate =
        DateTime.fromMillisecondsSinceEpoch(cachedTime);

    final isExpired =
        DateTime.now().difference(cachedDate) > expiryDuration;

    if (isExpired) return null;

    return List<Map<String, dynamic>>.from(cachedData);
  }

  /// Force clear cache
  static Future<void> clear() async {
    await _box.delete(_dataKey);
    await _box.delete(_timeKey);
  }
}
