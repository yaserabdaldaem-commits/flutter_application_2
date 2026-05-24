import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../app_config.dart';

class NotificationService {
  NotificationService._();

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

  static Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    await _plugin.initialize(
      const InitializationSettings(android: androidSettings),
    );

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(_channel);
    await androidPlugin?.requestNotificationsPermission();
  }

  static Future<void> showAdhanNotification() async {
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

    await _plugin.show(
      1001,
      AppConfig.adhanNotificationTitle,
      AppConfig.adhanNotificationBody,
      details,
    );
  }

  static Future<void> showBackgroundAdhanNotification() async {
    final plugin = FlutterLocalNotificationsPlugin();
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    await plugin.initialize(
      const InitializationSettings(android: androidSettings),
    );

    final androidPlugin = plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(_channel);

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

    await plugin.show(
      1002,
      AppConfig.adhanNotificationTitle,
      AppConfig.adhanNotificationBody,
      details,
    );
  }
}
