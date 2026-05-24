import 'dart:async';
import 'dart:ui';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import 'core/app_config.dart';
import 'features/prayer/data/prayer_models.dart';
import 'features/prayer/data/prayer_repository.dart';
import 'features/prayer/services/adhan_scheduler.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AdhanScheduler.initialize();
  runApp(const DamascusApp());
}

class DamascusApp extends StatelessWidget {
  const DamascusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: AppConfig.appName,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFCDA944),
          brightness: Brightness.dark,
        ),
      ),
      home: const PrayerHomePage(),
    );
  }
}

class PrayerHomePage extends StatefulWidget {
  const PrayerHomePage({super.key});

  @override
  State<PrayerHomePage> createState() => _PrayerHomePageState();
}

class _PrayerHomePageState extends State<PrayerHomePage> {
  final PrayerRepository _repository = const PrayerRepository();
  final AudioPlayer _audioPlayer = AudioPlayer();

  PrayerResponse? _prayerResponse;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _loadPrayerTimes();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadPrayerTimes({bool forceRefresh = false}) async {
    if (forceRefresh) {
      setState(() {
        _isRefreshing = true;
        _errorMessage = null;
      });
    } else {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      if (!forceRefresh) {
        final cachedResponse = await _repository.loadCachedPrayerTimes();
        if (cachedResponse != null && mounted) {
          setState(() {
            _prayerResponse = cachedResponse;
            _isLoading = false;
          });
          unawaited(_scheduleAlarms(cachedResponse));
        }
      }

      final response = await _repository.fetchLatestPrayerTimes();

      if (!mounted) return;

      setState(() {
        _prayerResponse = response;
        _isLoading = false;
        _isRefreshing = false;
      });

      await _scheduleAlarms(response);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = _prayerResponse == null ? error.toString() : null;
        _isLoading = false;
        _isRefreshing = false;
      });

      if (_prayerResponse != null) {
        _showSnackBar(
            'تم استخدام البيانات المحلية بسبب تعذر التحديث من الإنترنت.');
      }
    }
  }

  Future<void> _scheduleAlarms(PrayerResponse response) async {
    try {
      final scheduled = await AdhanScheduler.schedulePrayerAlarms(
        response,
        onFeedback: (message) {
          if (!mounted) return;
          _showSnackBar(message);
        },
      );

      if (!scheduled && mounted) {
        _showSnackBar(
          'Exact alarm scheduling is disabled. Open system settings and allow exact alarms for this app.',
        );
      }
    } catch (scheduleError) {
      if (!mounted) return;
      _showSnackBar(
        'تم تحميل البيانات، لكن جدولة التنبيهات تحتاج مراجعة الإذن أو إعدادات النظام.',
      );
      debugPrint('Alarm scheduling error: $scheduleError');
    }
  }

  Future<void> _playInAppAdhan() async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(
        AssetSource(AppConfig.adhanAsset),
      );
    } catch (error) {
      if (!mounted) return;
      _showSnackBar('تعذر تشغيل الأذان داخل التطبيق.');
      debugPrint('In-app audio error: $error');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
      ..removeCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final timings = _prayerResponse?.data.timings;
    final displayTimes = timings?.toDisplayMap() ?? const <String, String>{};

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(
          color: Color(0xFFCDA944),
          size: 30,
        ),
        actions: [
          IconButton(
            onPressed: _isRefreshing
                ? null
                : () => _loadPrayerTimes(forceRefresh: true),
            icon: _isRefreshing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: Stack(
        children: [
          _buildBackground(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  const Text(
                    'مواقيت دمشق وريفها',
                    style: TextStyle(
                      color: Color(0xFFCDA944),
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _prayerResponse == null
                        ? 'تحميل البيانات...'
                        : '${_prayerResponse!.data.date.readable} • ${_prayerResponse!.data.date.hijri.day} ${_prayerResponse!.data.date.hijri.month.ar}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_errorMessage != null) _buildErrorBanner(_errorMessage!),
                  Expanded(
                    child: _isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFFCDA944),
                            ),
                          )
                        : displayTimes.isEmpty
                            ? _buildEmptyState()
                            : ListView.separated(
                                physics: const BouncingScrollPhysics(),
                                padding: const EdgeInsets.only(bottom: 16),
                                itemCount: displayTimes.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  final title =
                                      displayTimes.keys.elementAt(index);
                                  final value =
                                      displayTimes.values.elementAt(index);
                                  return _buildGlassCard(title, value);
                                },
                              ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: Align(
                      alignment: Alignment.center,
                      child: Text(
                        'إشراف المهندس ياسر',
                        style: TextStyle(
                          color: Color(0xFFCDA944),
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
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
          image: NetworkImage(AppConfig.backgroundImageUrl),
          fit: BoxFit.cover,
        ),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(color: Colors.black.withValues(alpha: 0.62)),
      ),
    );
  }

  Widget _buildGlassCard(String name, String time) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            time,
            style: const TextStyle(
              color: Color(0xFFCDA944),
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off, color: Color(0xFFCDA944), size: 50),
          const SizedBox(height: 12),
          const Text(
            'لا توجد بيانات متاحة حالياً',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _isRefreshing
                ? null
                : () => _loadPrayerTimes(forceRefresh: true),
            icon: const Icon(Icons.refresh),
            label: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }

  Drawer _buildDrawer() {
    return Drawer(
      backgroundColor: const Color(0xFF020C1B).withValues(alpha: 0.98),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            const Icon(Icons.mosque, size: 72, color: Color(0xFFCDA944)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: QrImageView(
                data: AppConfig.appLink,
                version: QrVersions.auto,
                size: 140,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.refresh, color: Color(0xFFCDA944)),
              title: const Text(
                'تحديث البيانات',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () async {
                Navigator.pop(context);
                await _loadPrayerTimes(forceRefresh: true);
              },
            ),
            ListTile(
              leading: const Icon(Icons.alarm, color: Color(0xFFCDA944)),
              title: const Text(
                'إعادة جدولة التنبيهات',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () async {
                Navigator.pop(context);
                if (_prayerResponse != null) {
                  await AdhanScheduler.schedulePrayerAlarms(_prayerResponse!);
                  _showSnackBar('تمت إعادة جدولة التنبيهات');
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.volume_up, color: Color(0xFFCDA944)),
              title: const Text(
                'تجربة الأذان داخل التطبيق',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () async {
                Navigator.pop(context);
                await _playInAppAdhan();
              },
            ),
            ListTile(
              leading: const Icon(Icons.share, color: Color(0xFFCDA944)),
              title: const Text(
                'إرسال الرابط',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () => Share.share('إمساكية دمشق:\n${AppConfig.appLink}'),
            ),
            const Spacer(),
            const Padding(
              padding: EdgeInsets.only(bottom: 20),
              child: Text(
                'Adhan notifications are driven by native Android scheduling.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
