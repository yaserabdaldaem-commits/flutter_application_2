import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';

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
  // تواقيت دمشق الافتراضية (تظهر فوراً للمستخدم)
  Map<String, String> prayerTimes = {
    "الفجر": "05:48",
    "الشروق": "07:14",
    "الظهر": "12:49",
    "العصر": "15:57",
    "المغرب": "18:23",
    "العشاء": "20:24",
  };

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchPrayerTimes(); // جلب البيانات عند فتح التطبيق
  }

  // جلب البيانات من Aladhan API (موثوق وسريع جداً)
  Future<void> fetchPrayerTimes() async {
    try {
      // طلب التواقيت لمدينة دمشق
      final url = Uri.parse(
          'https://api.aladhan.com/v1/timingsByCity?city=Damascus&country=Syria&method=3');
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final timings = data['data']['timings'];

        setState(() {
          prayerTimes = {
            "الفجر": timings['Fajr'],
            "الشروق": timings['Sunrise'],
            "الظهر": timings['Dhuhr'],
            "العصر": timings['Asr'],
            "المغرب": timings['Maghrib'],
            "العشاء": timings['Isha'],
          };
          isLoading = false;
        });
      }
    } catch (e) {
      // في حال فشل الإنترنت، نتوقف عن التحميل ونعرض القيم الافتراضية
      setState(() => isLoading = false);
      debugPrint("فشل الجلب، تم اعتماد التوقيت المحلي: $e");
    }
  }

  void _shareApp() {
    Share.share(
        "🌙 إمساكية رمضان 2026 - دمشق\nتحديث حي ومباشر\nإشراف: المهندس ياسر");
  }

  @override
  Widget build(BuildContext context) {
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
          // الخلفية الشفافة الفخمة
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(
                    'https://images.unsplash.com/photo-1542662565-7e4b66bae529'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(color: Colors.black.withOpacity(0.5)),
          ),

          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 10),
                const Text("تواقيت دمشق وريفها",
                    style: TextStyle(
                        color: Color(0xFFCDA944),
                        fontSize: 32,
                        fontWeight: FontWeight.bold)),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text("اللهم أعنّا على ذكرك وشكرك وحسن عبادتك",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                          fontStyle: FontStyle.italic)),
                ),
                const SizedBox(height: 30),
                Expanded(
                  child: isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                              color: Color(0xFFCDA944)))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 25),
                          itemCount: prayerTimes.length,
                          itemBuilder: (context, index) {
                            String key = prayerTimes.keys.elementAt(index);
                            String value = prayerTimes.values.elementAt(index);
                            return _buildGlassCard(key, value);
                          },
                        ),
                ),
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text("تصميم المهندس ياسر",
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

  Widget _buildGlassCard(String name, String time) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(time,
              style: const TextStyle(
                  color: Color(0xFFCDA944),
                  fontSize: 28,
                  fontWeight: FontWeight.bold)),
          Text(name, style: const TextStyle(color: Colors.white, fontSize: 22)),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: const Color(0xFF020C1B).withOpacity(0.95),
      child: Column(
        children: [
          const DrawerHeader(
              child: Icon(Icons.mosque, size: 80, color: Color(0xFFCDA944))),
          ListTile(
            leading: const Icon(Icons.refresh, color: Color(0xFFCDA944)),
            title: const Text("تحديث البيانات",
                style: TextStyle(color: Colors.white, fontSize: 18)),
            onTap: () {
              Navigator.pop(context);
              setState(() => isLoading = true);
              fetchPrayerTimes();
            },
          ),
          ListTile(
            leading: const Icon(Icons.share, color: Color(0xFFCDA944)),
            title: const Text("مشاركة التطبيق",
                style: TextStyle(color: Colors.white, fontSize: 18)),
            onTap: () {
              Navigator.pop(context);
              _shareApp();
            },
          ),
          const Spacer(),
          const Text("إصدار دمشق 2026",
              style: TextStyle(color: Colors.white30, fontSize: 12)),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
