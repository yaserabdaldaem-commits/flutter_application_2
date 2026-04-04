import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart'; // المكتبة الجديدة

// --- استدعاء جنود الفايربيس والمنبه الخلفي ---
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';

@pragma('vm:entry-point')
void playAdhanCallback() async {
  final player = AudioPlayer();
  try {
    await player.play(AssetSource('adhan.mp3'));
    debugPrint("صداح الأذان في الخلفية بنجاح يا مدير!");
  } catch (e) {
    debugPrint("خطأ في تشغيل صوت الأذان: $e");
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
    await AndroidAlarmManager.initialize();
    debugPrint("الأنظمة جاهزة للعمل بإشراف المبرمج ياسر!");
  } catch (e) {
    debugPrint("فشل تشغيل الأنظمة: $e");
  }

  runApp(const MaterialApp(
    home: DamascusLiveApp(),
    debugShowCheckedModeBanner: false,
  ));
}

class DamascusLiveApp extends StatefulWidget {
  const DamascusLiveApp({super.key});
  @override
  State<DamascusLiveApp> createState() => _DamascusLiveAppState();
}

class _DamascusLiveAppState extends State<DamascusLiveApp> {
  Prayer? prayerData;
  bool isLoading = true;
  String cloudMessage = "جاري الاتصال بالسحاب...";
  String nextPrayerName = "جاري الحساب...";
  final String appLink =
      "https://github.com/yaserabdaldaem-commits/flutter_application_2";

  @override
  void initState() {
    super.initState();
    _initialLoad();
  }

  Future<void> _initialLoad() async {
    // 1. تحميل البيانات من الذاكرة أولاً (لسرعة الفتح)
    await _loadFromLocal();
    // 2. تحديث البيانات من الإنترنت في الخلفية
    await fetchPrayerTimes();
    await _fetchRemoteConfig();
    _logVisitToFirebase();

    if (prayerData != null) {
      _scheduleAllPrayers();
      _calculateNextPrayer();
    }
  }

  // --- ميزة التخزين المحلي (Offline Support) ---
  Future<void> _loadFromLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final String? cached = prefs.getString('prayer_cache');
    if (cached != null) {
      setState(() {
        prayerData = prayerFromJson(cached);
        isLoading = false;
      });
    }
  }

  Future<void> fetchPrayerTimes() async {
    try {
      final url = Uri.parse(
          'https://api.aladhan.com/v1/timingsByCity?city=Damascus&country=Syria&method=3');
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('prayer_cache', response.body); // حفظ للمستقبل

        setState(() {
          prayerData = prayerFromJson(response.body);
          isLoading = false;
          _calculateNextPrayer();
        });
      }
    } catch (e) {
      setState(() => isLoading = false);
      debugPrint("خطأ في جلب المواقيت: $e");
    }
  }

  // --- ميزة حساب الصلاة القادمة ---
  void _calculateNextPrayer() {
    if (prayerData == null) return;
    final now = DateTime.now();
    final t = prayerData!.data.timings;

    Map<String, String> times = {
      "الفجر": t.fajr,
      "الظهر": t.dhuhr,
      "العصر": t.asr,
      "المغرب": t.maghrib,
      "العشاء": t.isha
    };

    String foundName = "الفجر";
    for (var entry in times.entries) {
      final parts = entry.value.split(':');
      final prayerTime = DateTime(now.year, now.month, now.day,
          int.parse(parts[0]), int.parse(parts[1]));
      if (prayerTime.isAfter(now)) {
        foundName = entry.key;
        break;
      }
    }
    setState(() => nextPrayerName = "الصلاة القادمة: $foundName");
  }

  void _scheduleAllPrayers() async {
    if (prayerData == null) return;

    // تنظيف المنبهات القديمة لمنع التكرار
    for (int i = 0; i < 5; i++) await AndroidAlarmManager.cancel(i);

    final t = prayerData!.data.timings;
    List<String> times = [t.fajr, t.dhuhr, t.asr, t.maghrib, t.isha];
    final now = DateTime.now();

    for (int i = 0; i < times.length; i++) {
      final parts = times[i].split(':');
      var scheduleTime = DateTime(now.year, now.month, now.day,
          int.parse(parts[0]), int.parse(parts[1]));

      if (scheduleTime.isBefore(now))
        scheduleTime = scheduleTime.add(const Duration(days: 1));

      await AndroidAlarmManager.oneShotAt(
        scheduleTime,
        i,
        playAdhanCallback,
        exact: true,
        wakeup: true,
        allowWhileIdle: true,
        rescheduleOnReboot: true,
      );
    }
    debugPrint("تمت إعادة جدولة المنبهات بنجاح.");
  }

  // --- Remote Config & Firebase ---
  Future<void> _fetchRemoteConfig() async {
    final remoteConfig = FirebaseRemoteConfig.instance;
    try {
      await remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: Duration.zero,
      ));
      await remoteConfig.fetchAndActivate();
      setState(() => cloudMessage = remoteConfig.getString('app_message'));
    } catch (e) {
      debugPrint("خطأ Remote Config: $e");
    }
  }

  void _logVisitToFirebase() {
    FirebaseFirestore.instance.collection('visits').add({
      'time': DateTime.now().toString(),
      'city': 'Damascus',
      'user': 'Yasser'
    });
  }

  @override
  Widget build(BuildContext context) {
    final timings = prayerData?.data.timings;
    final Map<String, String> displayTimes = timings == null
        ? {}
        : {
            "الفجر": timings.fajr,
            "الشروق": timings.sunrise,
            "الظهر": timings.dhuhr,
            "العصر": timings.asr,
            "المغرب": timings.maghrib,
            "العشاء": timings.isha,
          };

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      drawer: _buildDrawer(),
      body: Stack(
        children: [
          _buildBackground(),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 10),
                const Text("دمشق وريفها 2026",
                    style: TextStyle(
                        color: Color(0xFFCDA944),
                        fontSize: 28,
                        fontWeight: FontWeight.bold)),
                Text(nextPrayerName,
                    style: const TextStyle(color: Colors.white, fontSize: 18)),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Text(cloudMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontStyle: FontStyle.italic)),
                ),
                Expanded(
                  child: isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                              color: Color(0xFFCDA944)))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 25),
                          itemCount: displayTimes.length,
                          itemBuilder: (context, index) {
                            return _buildGlassCard(
                                displayTimes.keys.elementAt(index),
                                displayTimes.values.elementAt(index));
                          },
                        ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final testTime =
                        DateTime.now().add(const Duration(seconds: 5));
                    await AndroidAlarmManager.oneShotAt(
                        testTime, 999, playAdhanCallback,
                        exact: true, wakeup: true);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text("سيعمل الأذان خلال 5 ثوانٍ...")));
                  },
                  style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.white10),
                  child: const Text("تجربة صوت الأذان",
                      style: TextStyle(color: Colors.white)),
                ),
                const Padding(
                  padding: EdgeInsets.all(10),
                  child: Text("بإشراف المبرمج ياسر",
                      style: TextStyle(
                          color: Color(0xFFCDA944),
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return Container(
      decoration: const BoxDecoration(
          image: DecorationImage(
              image: NetworkImage(
                  'https://images.unsplash.com/photo-1542662565-7e4b66bae529'),
              fit: BoxFit.cover)),
      child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(color: Colors.black.withOpacity(0.6))),
    );
  }

  Widget _buildGlassCard(String name, String time) {
    bool isNext = nextPrayerName.contains(name);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: isNext
              ? Colors.white.withOpacity(0.15)
              : Colors.white.withOpacity(0.07),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: isNext
                  ? const Color(0xFFCDA944)
                  : Colors.white.withOpacity(0.1))),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(time,
            style: const TextStyle(
                color: Color(0xFFCDA944),
                fontSize: 26,
                fontWeight: FontWeight.bold)),
        Text(name, style: const TextStyle(color: Colors.white, fontSize: 20)),
      ]),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: const Color(0xFF020C1B).withOpacity(0.98),
      child: Column(children: [
        const DrawerHeader(
            child: Icon(Icons.mosque, size: 70, color: Color(0xFFCDA944))),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(15)),
          child:
              QrImageView(data: appLink, version: QrVersions.auto, size: 140.0),
        ),
        const SizedBox(height: 20),
        ListTile(
          leading: const Icon(Icons.refresh, color: Color(0xFFCDA944)),
          title: const Text("تحديث البيانات",
              style: TextStyle(color: Colors.white)),
          onTap: () {
            Navigator.pop(context);
            _initialLoad();
          },
        ),
      ]),
    );
  }
}

// --- Prayer Model Classes ---
Prayer prayerFromJson(String str) => Prayer.fromJson(json.decode(str));

class Prayer {
  int code;
  String status;
  Data data;
  Prayer({required this.code, required this.status, required this.data});
  factory Prayer.fromJson(Map<String, dynamic> json) => Prayer(
      code: json["code"],
      status: json["status"],
      data: Data.fromJson(json["data"]));
}

class Data {
  Timings timings;
  Data({required this.timings});
  factory Data.fromJson(Map<String, dynamic> json) =>
      Data(timings: Timings.fromJson(json["timings"]));
}

class Timings {
  String fajr, sunrise, dhuhr, asr, maghrib, isha;
  Timings(
      {required this.fajr,
      required this.sunrise,
      required this.dhuhr,
      required this.asr,
      required this.maghrib,
      required this.isha});
  factory Timings.fromJson(Map<String, dynamic> json) => Timings(
      fajr: json["Fajr"],
      sunrise: json["Sunrise"],
      dhuhr: json["Dhuhr"],
      asr: json["Asr"],
      maghrib: json["Maghrib"],
      isha: json["Isha"]);
}
