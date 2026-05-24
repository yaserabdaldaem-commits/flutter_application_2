import 'package:flutter/foundation.dart';

import '../../../core/app_config.dart';
import '../../prayer/application/adhan_scheduler.dart';
import '../../prayer/data/cloud_service.dart';
import '../../prayer/data/prayer_service.dart';
import '../../prayer/domain/prayer.dart';

class PrayerController extends ChangeNotifier {
  PrayerController({
    required PrayerService prayerService,
    required CloudService cloudService,
    required AdhanScheduler scheduler,
  }) : _prayerService = prayerService,
       _cloudService = cloudService,
       _scheduler = scheduler;

  final PrayerService _prayerService;
  final CloudService _cloudService;
  final AdhanScheduler _scheduler;

  Prayer? _prayer;
  bool _isLoading = true;
  String _cloudMessage = 'جاري الاتصال بالسحاب...';
  String _nextPrayerName = 'جاري الحساب...';

  Prayer? get prayer => _prayer;
  bool get isLoading => _isLoading;
  String get cloudMessage => _cloudMessage;
  String get nextPrayerName => _nextPrayerName;
  String get appLink => AppConfig.appLink;

  Map<String, String> get displayTimes => _prayer?.timings.toDisplayMap() ?? {};

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    await _loadFromCache();

    await Future.wait([
      refreshPrayerData(notifyLoading: false),
      _refreshRemoteConfig(),
      _logVisit(),
    ]);

    _isLoading = false;
    notifyListeners();
  }

  Future<void> refreshPrayerData({bool notifyLoading = true}) async {
    if (notifyLoading) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      _prayer = await _prayerService.fetchPrayerTimes();

      final scheduleResult = await _scheduler.scheduleAndResolveNext(
        _prayer!.timings,
      );
      _nextPrayerName = 'الصلاة القادمة: ${scheduleResult.nextPrayerName}';
    } catch (e) {
      debugPrint('Prayer refresh failed: $e');
    } finally {
      if (notifyLoading) {
        _isLoading = false;
      }
      notifyListeners();
    }
  }

  Future<void> scheduleTestAdhan() {
    return _scheduler.scheduleTestAlarm(
      DateTime.now().add(const Duration(seconds: 5)),
    );
  }

  Future<void> _loadFromCache() async {
    try {
      _prayer = await _prayerService.loadCachedPrayer();
      if (_prayer != null) {
        final scheduleResult = await _scheduler.scheduleAndResolveNext(
          _prayer!.timings,
        );
        _nextPrayerName = 'الصلاة القادمة: ${scheduleResult.nextPrayerName}';
      }
    } catch (e) {
      debugPrint('Cache load failed: $e');
    }
  }

  Future<void> _refreshRemoteConfig() async {
    try {
      _cloudMessage = await _cloudService.fetchRemoteMessage();
      notifyListeners();
    } catch (e) {
      debugPrint('Remote config failed: $e');
    }
  }

  Future<void> _logVisit() async {
    try {
      await _cloudService.logVisit();
    } catch (e) {
      debugPrint('Visit log failed: $e');
    }
  }
}
