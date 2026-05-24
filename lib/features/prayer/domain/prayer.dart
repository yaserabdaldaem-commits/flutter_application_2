import 'dart:convert';

Prayer prayerFromJson(String raw) => Prayer.fromJson(json.decode(raw));

class Prayer {
  const Prayer({
    required this.code,
    required this.status,
    required this.timings,
  });

  final int code;
  final String status;
  final Timings timings;

  factory Prayer.fromJson(Map<String, dynamic> json) {
    return Prayer(
      code: json['code'] as int,
      status: json['status'] as String,
      timings: Timings.fromJson(
        json['data']['timings'] as Map<String, dynamic>,
      ),
    );
  }
}

class Timings {
  const Timings({
    required this.fajr,
    required this.sunrise,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
  });

  final String fajr;
  final String sunrise;
  final String dhuhr;
  final String asr;
  final String maghrib;
  final String isha;

  factory Timings.fromJson(Map<String, dynamic> json) {
    return Timings(
      fajr: json['Fajr'] as String,
      sunrise: json['Sunrise'] as String,
      dhuhr: json['Dhuhr'] as String,
      asr: json['Asr'] as String,
      maghrib: json['Maghrib'] as String,
      isha: json['Isha'] as String,
    );
  }

  Map<String, String> toDisplayMap() {
    return {
      'الفجر': fajr,
      'الشروق': sunrise,
      'الظهر': dhuhr,
      'العصر': asr,
      'المغرب': maghrib,
      'العشاء': isha,
    };
  }
}
