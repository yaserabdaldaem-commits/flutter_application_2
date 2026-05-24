import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/app_config.dart';
import 'prayer_models.dart';

class PrayerRepository {
  const PrayerRepository();

  Future<PrayerResponse?> loadCachedPrayerTimes() async {
    final cached = await _readCachedResponse();
    if (cached == null) {
      return null;
    }

    try {
      return PrayerResponse.fromJson(
        jsonDecode(cached) as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }

  Future<PrayerResponse> fetchLatestPrayerTimes() async {
    try {
      final response = await http
          .get(Uri.parse(AppConfig.prayerApiUrl))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw Exception('Prayer API returned ${response.statusCode}');
      }

      await _cacheResponse(response.body);
      return PrayerResponse.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } catch (error) {
      throw Exception('Unable to load prayer times: $error');
    }
  }

  Future<PrayerResponse> loadPrayerTimes({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cached = await loadCachedPrayerTimes();
      if (cached != null) {
        return cached;
      }
    }

    try {
      return await fetchLatestPrayerTimes();
    } catch (error) {
      final cached = await loadCachedPrayerTimes();
      if (cached != null) {
        return cached;
      }

      throw Exception('Unable to load prayer times: $error');
    }
  }

  Future<void> _cacheResponse(String payload) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConfig.prayerCacheKey, payload);
  }

  Future<String?> _readCachedResponse() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConfig.prayerCacheKey);
  }
}
