import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';

import '../../../core/app_config.dart';
import '../domain/prayer.dart';
import 'adhan_background.dart';

class ScheduleResult {
  const ScheduleResult({
    required this.nextPrayerName,
    required this.scheduledCount,
  });

  final String nextPrayerName;
  final int scheduledCount;
}

class AdhanScheduler {
  static final List<_PrayerAlarm> _alarms = [
    _PrayerAlarm(0, 'الفجر', (t) => t.fajr),
    _PrayerAlarm(1, 'الظهر', (t) => t.dhuhr),
    _PrayerAlarm(2, 'العصر', (t) => t.asr),
    _PrayerAlarm(3, 'المغرب', (t) => t.maghrib),
    _PrayerAlarm(4, 'العشاء', (t) => t.isha),
  ];

  Future<ScheduleResult> scheduleAndResolveNext(Timings timings) async {
    final now = DateTime.now();

    for (final alarm in _alarms) {
      await AndroidAlarmManager.cancel(alarm.id);
    }

    String nextPrayerName = _alarms.first.name;
    DateTime? nextPrayerTime;

    for (final alarm in _alarms) {
      final scheduleTime = _normalizeTime(alarm.timeOf(timings), now);

      await AndroidAlarmManager.oneShotAt(
        scheduleTime,
        alarm.id,
        playAdhanCallback,
        exact: true,
        wakeup: true,
        allowWhileIdle: true,
        rescheduleOnReboot: true,
      );

      if (nextPrayerTime == null || scheduleTime.isBefore(nextPrayerTime)) {
        nextPrayerTime = scheduleTime;
        nextPrayerName = alarm.name;
      }
    }

    return ScheduleResult(
      nextPrayerName: nextPrayerName,
      scheduledCount: _alarms.length,
    );
  }

  Future<void> scheduleTestAlarm(DateTime when) {
    return AndroidAlarmManager.oneShotAt(
      when,
      AppConfig.testAlarmId,
      playAdhanCallback,
      exact: true,
      wakeup: true,
      allowWhileIdle: true,
    );
  }

  DateTime _normalizeTime(String rawTime, DateTime now) {
    final normalized = rawTime.split(' ').first;
    final parts = normalized.split(':');

    var scheduleTime = DateTime(
      now.year,
      now.month,
      now.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );

    if (!scheduleTime.isAfter(now)) {
      scheduleTime = scheduleTime.add(const Duration(days: 1));
    }

    return scheduleTime;
  }
}

class _PrayerAlarm {
  const _PrayerAlarm(this.id, this.name, this.timeOf);

  final int id;
  final String name;
  final String Function(Timings) timeOf;
}
