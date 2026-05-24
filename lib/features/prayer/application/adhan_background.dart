import 'dart:async';
import 'dart:ui';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/widgets.dart';

import '../../../core/app_config.dart';
import '../../../core/services/notification_service.dart';

@pragma('vm:entry-point')
Future<void> playAdhanCallback() async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();

  await NotificationService.showBackgroundAdhanNotification();

  final player = AudioPlayer();
  try {
    await player.setReleaseMode(ReleaseMode.stop);
    await player.play(AssetSource(AppConfig.adhanAsset));
    unawaited(player.onPlayerComplete.first.then((_) => player.dispose()));
  } catch (_) {
    await player.dispose();
  }
}
