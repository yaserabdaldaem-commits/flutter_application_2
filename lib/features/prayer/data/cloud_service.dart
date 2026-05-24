import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';

import '../../../core/app_config.dart';

class CloudService {
  const CloudService();

  Future<String> fetchRemoteMessage() async {
    final remoteConfig = FirebaseRemoteConfig.instance;
    await remoteConfig.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: Duration.zero,
      ),
    );
    await remoteConfig.fetchAndActivate();
    return remoteConfig.getString('app_message');
  }

  Future<void> logVisit() async {
    await FirebaseFirestore.instance.collection('visits').add({
      'time': DateTime.now().toIso8601String(),
      'city': AppConfig.city,
      'user': AppConfig.userName,
    });
  }
}
