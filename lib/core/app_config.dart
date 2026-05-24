class AppConfig {
  AppConfig._();

  static const String appName = 'Damascus Live App';
  static const String appLink =
      'https://github.com/yaserabdaldaem-commits/flutter_application_2';

  static const String prayerApiUrl =
      'https://api.aladhan.com/v1/timingsByCity?city=Damascus&country=Syria&method=3';

  static const String backgroundImageUrl =
      'https://images.unsplash.com/photo-1542662565-7e4b66bae529';

  static const String city = 'Damascus';
  static const String userName = 'Yasser';

  static const String prayerCacheKey = 'prayer_cache';

  static const String adhanAsset = 'adhan.mp3';
  static const String adhanNotificationSoundResource = 'adhan';

  static const String adhanNotificationChannelId = 'adhan_channel';
  static const String adhanNotificationChannelName = 'Adhan Alerts';
  static const String adhanNotificationChannelDescription =
      'Shows adhan reminder notifications';
  static const String adhanNotificationTitle = 'حان وقت الصلاة';
  static const String adhanNotificationBody =
      'تقبل الله طاعتكم. تم تشغيل تنبيه الأذان.';

  static const int testAlarmId = 999;
}
