import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:convert';
import 'dart:async'; // ضروري للمؤقت الزمني
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:audioplayers/audioplayers.dart'; // مكتبة الصوت

void main() => runApp(const MaterialApp(
      home: DamascusLiveApp(),
      debugShowCheckedModeBanner: false,
    ));

class DamascusLiveApp extends StatefulWidget {
  const DamascusLiveApp({super.key});
  @override
  State<DamascusLiveApp> createState() => _DamascusLiveAppState();
}

class _DamascusLiveAppState extends State<DamascusLiveApp> {
  Prayer? prayerData;
  bool isLoading = true;
  final AudioPlayer _audioPlayer = AudioPlayer(); // مشغل الأذان
  Timer? _timer; // مؤقت لفحص الوقت دورياً

  final String appLink = "https://github.com/Yasser/damascus_imsakiya";

  @override
  void initState() {
    super.initState();
    fetchPrayerTimes();
    // بدء مراقبة الوقت كل دقيقة للأذان
    _timer = Timer.periodic(
        const Duration(minutes: 1), (timer) => _checkAdhanTime());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  // دالة فحص وقت الأذان
  void _checkAdhanTime() {
    if (prayerData == null) return;

    final now = DateTime.now();
    final currentTime =
        "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";

    final t = prayerData!.data.timings;
    List<String> adhanTimes = [t.fajr, t.dhuhr, t.asr, t.maghrib, t.isha];

    for (var time in adhanTimes) {
      if (time == currentTime) {
        _playAdhan();
        break;
      }
    }
  }

  Future<void> _playAdhan() async {
    try {
      await _audioPlayer.play(AssetSource('adhan.mp3'));
      debugPrint("حان وقت الصلاة: الله أكبر");
    } catch (e) {
      debugPrint("خطأ في تشغيل الصوت: $e");
    }
  }

  Future<void> fetchPrayerTimes() async {
    try {
      final url = Uri.parse(
          'https://api.aladhan.com/v1/timingsByCity?city=Damascus&country=Syria&method=3');
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        setState(() {
          prayerData = prayerFromJson(response.body);
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() => isLoading = false);
      debugPrint("فشل الجلب: $e");
    }
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
            "المغرب ": timings.maghrib,
            "العشاء": timings.isha,
          };

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFFCDA944), size: 30),
      ),
      drawer: _buildDrawer(),
      body: Stack(
        children: [
          _buildBackground(),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 10),
                const Text(" مواقيت دمشق وريفها  2026",
                    style: TextStyle(
                        color: Color(0xFFCDA944),
                        fontSize: 30,
                        fontWeight: FontWeight.bold)),

                // تم حذف سطر رمضان 6 والتاريخ من هنا ليبقى التصميم نظيفاً

                const SizedBox(height: 20),
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
                              displayTimes.values.elementAt(index),
                            );
                          },
                        ),
                ),
                const Padding(
                  padding: EdgeInsets.all(15),
                  child: Text("إشراف المهندس ياسر",
                      style: TextStyle(
                          color: Color(0xFFCDA944),
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2)),
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
          fit: BoxFit.cover,
        ),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(color: Colors.black.withOpacity(0.6)),
      ),
    );
  }

  Widget _buildGlassCard(String name, String time) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(time,
              style: const TextStyle(
                  color: Color(0xFFCDA944),
                  fontSize: 26,
                  fontWeight: FontWeight.bold)),
          Text(name, style: const TextStyle(color: Colors.white, fontSize: 20)),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: const Color(0xFF020C1B).withOpacity(0.98),
      child: Column(
        children: [
          const DrawerHeader(
              child: Icon(Icons.mosque, size: 70, color: Color(0xFFCDA944))),
          const Text("شارك التطبيق عبر الكود",
              style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(15)),
            child: QrImageView(
                data: appLink, version: QrVersions.auto, size: 140.0),
          ),
          const SizedBox(height: 20),
          ListTile(
            leading: const Icon(Icons.refresh, color: Color(0xFFCDA944)),
            title: const Text("تحديث دمشق الآن",
                style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              setState(() => isLoading = true);
              fetchPrayerTimes();
            },
          ),
          ListTile(
            leading: const Icon(Icons.share, color: Color(0xFFCDA944)),
            title: const Text("إرسال الرابط",
                style: TextStyle(color: Colors.white)),
            onTap: () {
              Share.share("إمساكية دمشق حية:\n$appLink");
            },
          ),
          ListTile(
            leading: const Icon(Icons.volume_up, color: Color(0xFFCDA944)),
            title: const Text("تجربة صوت الأذان",
                style: TextStyle(color: Colors.white)),
            onTap: () {
              _playAdhan();
            },
          ),
        ],
      ),
    );
  }
}

// --- قسم الـ Model المدمج ---
Prayer prayerFromJson(String str) => Prayer.fromJson(json.decode(str));

class Prayer {
  int code;
  String status;
  Data data;
  Prayer({required this.code, required this.status, required this.data});
  factory Prayer.fromJson(Map<String, dynamic> json) => Prayer(
        code: json["code"],
        status: json["status"],
        data: Data.fromJson(json["data"]),
      );
}

class Data {
  Timings timings;
  Date date;
  Data({required this.timings, required this.date});
  factory Data.fromJson(Map<String, dynamic> json) => Data(
        timings: Timings.fromJson(json["timings"]),
        date: Date.fromJson(json["date"]),
      );
}

class Timings {
  String fajr, sunrise, dhuhr, asr, maghrib, isha, imsak;
  Timings(
      {required this.fajr,
      required this.sunrise,
      required this.dhuhr,
      required this.asr,
      required this.maghrib,
      required this.isha,
      required this.imsak});
  factory Timings.fromJson(Map<String, dynamic> json) => Timings(
        fajr: json["Fajr"],
        sunrise: json["Sunrise"],
        dhuhr: json["Dhuhr"],
        asr: json["Asr"],
        maghrib: json["Maghrib"],
        isha: json["Isha"],
        imsak: json["Imsak"],
      );
}

class Date {
  Hijri hijri;
  String readable;
  Date({required this.hijri, required this.readable});
  factory Date.fromJson(Map<String, dynamic> json) => Date(
        hijri: Hijri.fromJson(json["hijri"]),
        readable: json["readable"],
      );
}

class Hijri {
  String date, day;
  HijriMonth month;
  Hijri({required this.date, required this.day, required this.month});
  factory Hijri.fromJson(Map<String, dynamic> json) => Hijri(
        date: json["date"],
        day: json["day"],
        month: HijriMonth.fromJson(json["month"]),
      );
}

class HijriMonth {
  String ar;
  HijriMonth({required this.ar});
  factory HijriMonth.fromJson(Map<String, dynamic> json) =>
      HijriMonth(ar: json["ar"]);
}
