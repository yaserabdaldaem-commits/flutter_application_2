class PrayerResponse {
  final int code;
  final String status;
  final PrayerData data;

  const PrayerResponse({
    required this.code,
    required this.status,
    required this.data,
  });

  factory PrayerResponse.fromJson(Map<String, dynamic> json) {
    return PrayerResponse(
      code: json['code'] as int,
      status: json['status'] as String,
      data: PrayerData.fromJson(json['data'] as Map<String, dynamic>),
    );
  }
}

class PrayerData {
  final PrayerTimings timings;
  final PrayerDate date;

  const PrayerData({required this.timings, required this.date});

  factory PrayerData.fromJson(Map<String, dynamic> json) {
    return PrayerData(
      timings: PrayerTimings.fromJson(json['timings'] as Map<String, dynamic>),
      date: PrayerDate.fromJson(json['date'] as Map<String, dynamic>),
    );
  }
}

class PrayerTimings {
  final String fajr;
  final String sunrise;
  final String dhuhr;
  final String asr;
  final String maghrib;
  final String isha;
  final String imsak;

  const PrayerTimings({
    required this.fajr,
    required this.sunrise,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
    required this.imsak,
  });

  factory PrayerTimings.fromJson(Map<String, dynamic> json) {
    return PrayerTimings(
      fajr: json['Fajr'] as String,
      sunrise: json['Sunrise'] as String,
      dhuhr: json['Dhuhr'] as String,
      asr: json['Asr'] as String,
      maghrib: json['Maghrib'] as String,
      isha: json['Isha'] as String,
      imsak: json['Imsak'] as String,
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

class PrayerDate {
  final PrayerHijri hijri;
  final String readable;

  const PrayerDate({required this.hijri, required this.readable});

  factory PrayerDate.fromJson(Map<String, dynamic> json) {
    return PrayerDate(
      hijri: PrayerHijri.fromJson(json['hijri'] as Map<String, dynamic>),
      readable: json['readable'] as String,
    );
  }
}

class PrayerHijri {
  final String date;
  final String day;
  final PrayerHijriMonth month;

  const PrayerHijri({
    required this.date,
    required this.day,
    required this.month,
  });

  factory PrayerHijri.fromJson(Map<String, dynamic> json) {
    return PrayerHijri(
      date: json['date'] as String,
      day: json['day'] as String,
      month: PrayerHijriMonth.fromJson(json['month'] as Map<String, dynamic>),
    );
  }
}

class PrayerHijriMonth {
  final String ar;

  const PrayerHijriMonth({required this.ar});

  factory PrayerHijriMonth.fromJson(Map<String, dynamic> json) {
    return PrayerHijriMonth(ar: json['ar'] as String);
  }
}
