import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/app_config.dart';
import '../domain/prayer.dart';

class PrayerService {
  const PrayerService();

  Future<Prayer?> loadCachedPrayer() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(AppConfig.prayerCacheKey);
    if (cached == null || cached.isEmpty) {
      return null;
    }

    return prayerFromJson(cached);
  }

  Future<Prayer> fetchPrayerTimes() async {
    final response = await http
        .get(Uri.parse(AppConfig.prayerApiUrl))
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw StateError('Prayer API failed with status: ${response.statusCode}');
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConfig.prayerCacheKey, response.body);

    return prayerFromJson(response.body);
  }
}
