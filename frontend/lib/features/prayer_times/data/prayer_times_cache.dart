import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'prayer_times_model.dart';

class PrayerTimesCache {
  static const _kCacheKey = 'cache.prayerTimes';

  Future<void> save(PrayerTimesModel model) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kCacheKey, jsonEncode(model.toJson()));
  }

  Future<PrayerTimesModel?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kCacheKey);
    if (raw == null) return null;

    try {
      return PrayerTimesModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }
}
