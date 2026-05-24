import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../../core/app_config.dart';
import '../data/prayer_models.dart';

class AdhanScheduler {
  AdhanScheduler._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    AppConfig.adhanNotificationChannelId,
    AppConfig.adhanNotificationChannelName,
    description: AppConfig.adhanNotificationChannelDescription,
    importance: Importance.max,
    playSound: true,
    sound: RawResourceAndroidNotificationSound(
      AppConfig.adhanNotificationSoundResource,
    ),
  );

  static const Map<String, int> _alarmIds = {
    'Fajr': 1001,
    'Dhuhr': 1002,
    'Asr': 1003,
    'Maghrib': 1004,
    'Isha': 1005,
  };

  static bool _isInitialized = false;

  static Future<void> initialize() async {
    if (_isInitialized) return;

    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Damascus'));

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    await _plugin.initialize(
      const InitializationSettings(android: androidSettings),
    );

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(_channel);
    await androidPlugin?.requestNotificationsPermission();
    await androidPlugin?.requestExactAlarmsPermission();

    _isInitialized = true;
  }

  static Future<bool> ensureExactAlarmPermission({
    void Function(String message)? onFeedback,
  }) async {
    await initialize();

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    final notificationStatus = await Permission.notification.status;
    if (!notificationStatus.isGranted) {
      final requestedStatus = await Permission.notification.request();
      if (!requestedStatus.isGranted) {
        onFeedback?.call(
          'Notification permission is required before scheduling Adhan alarms.',
        );
        if (requestedStatus.isPermanentlyDenied) {
          await openAppSettings();
        }
        return false;
      }
    }

    final exactAlarmGranted =
        await androidPlugin?.requestExactAlarmsPermission() ?? false;

    if (!exactAlarmGranted) {
      onFeedback?.call(
        'Exact alarm access is blocked by Android. Open system settings and allow exact alarms for this app.',
      );
      await openAppSettings();
      return false;
    }

    return true;
  }

  static Future<bool> schedulePrayerAlarms(
    PrayerResponse prayer, {
    void Function(String message)? onFeedback,
  }) async {
    await initialize();

    final hasExactAlarmPermission = await ensureExactAlarmPermission(
      onFeedback: onFeedback,
    );

    if (!hasExactAlarmPermission) {
      return false;
    }

    final timings = prayer.data.timings;
    final entries = <MapEntry<String, String>>[
      MapEntry('Fajr', timings.fajr),
      MapEntry('Dhuhr', timings.dhuhr),
      MapEntry('Asr', timings.asr),
      MapEntry('Maghrib', timings.maghrib),
      MapEntry('Isha', timings.isha),
    ];

    for (final entry in entries) {
      final id = _alarmIds[entry.key];
      if (id == null) continue;

      await _plugin.cancel(id);
      await _scheduleSinglePrayerAlarm(
        id: id,
        title: 'حان وقت ${_arabicPrayerName(entry.key)}',
        time: entry.value,
      );
    }

    return true;
  }

  static Future<void> cancelPrayerAlarms() async {
    await initialize();
    for (final id in _alarmIds.values) {
      await _plugin.cancel(id);
    }
  }

  static Future<void> _scheduleSinglePrayerAlarm({
    required int id,
    required String title,
    required String time,
  }) async {
    final scheduledTime = _nextOccurrence(time);

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        AppConfig.adhanNotificationChannelId,
        AppConfig.adhanNotificationChannelName,
        channelDescription: AppConfig.adhanNotificationChannelDescription,
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        sound: RawResourceAndroidNotificationSound(
          AppConfig.adhanNotificationSoundResource,
        ),
      ),
    );

    await _plugin.zonedSchedule(
      id,
      title,
      AppConfig.adhanNotificationBody,
      scheduledTime,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  static tz.TZDateTime _nextOccurrence(String timeText) {
    final normalized = _normalizeTime(timeText);
    final parts = normalized.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    return scheduled;
  }

  static String _normalizeTime(String raw) {
    final trimmed = raw.trim();
    final spaceSplit = trimmed.split(' ');
    final firstPart = spaceSplit.isNotEmpty ? spaceSplit.first : trimmed;
    return firstPart.split('(').first.trim();
  }

  static String _arabicPrayerName(String englishName) {
    switch (englishName) {
      case 'Fajr':
        return 'الفجر';
      case 'Dhuhr':
        return 'الظهر';
      case 'Asr':
        return 'العصر';
      case 'Maghrib':
        return 'المغرب';
      case 'Isha':
        return 'العشاء';
      default:
        return englishName;
    }
  }
}
