import 'dart:math' as math;

/// طريقة الحساب.
enum PrayerMethod {
  /// تقويم أم القرى (السعودية): الفجر 18.5°، العشاء بعد المغرب بـ 90 دقيقة (120 في رمضان).
  ummAlQura(fajrAngle: 18.5, ishaAngle: null, ishaMinutes: 90),

  /// الهيئة المصرية العامة للمساحة: الفجر 19.5°، العشاء 17.5°.
  egypt(fajrAngle: 19.5, ishaAngle: 17.5, ishaMinutes: null);

  const PrayerMethod({
    required this.fajrAngle,
    required this.ishaAngle,
    required this.ishaMinutes,
  });
  final double fajrAngle;
  final double? ishaAngle;
  final int? ishaMinutes;

  /// نختار الطريقة حسب مكانك: مصر أو غيرها (السعودية افتراضياً).
  static PrayerMethod forLocation(double lat, double lon) =>
      (lat > 21.5 && lat < 31.8 && lon > 24.6 && lon < 35.2 &&
              !(lat < 29.6 && lon > 34.9))
          ? egypt
          : ummAlQura;
}

enum Prayer { fajr, sunrise, dhuhr, asr, maghrib, isha }

class PrayerDay {
  const PrayerDay(this.times);
  final Map<Prayer, DateTime> times;

  /// الصلاة القادمة (الشروق ليس صلاة فيُتخطى).
  (Prayer, DateTime)? nextAfter(DateTime now) {
    for (final p in Prayer.values) {
      if (p == Prayer.sunrise) continue;
      final t = times[p]!;
      if (t.isAfter(now)) return (p, t);
    }
    return null;
  }
}

/// حساب أوقات الصلاة فلكياً على الجهاز (بدون إنترنت).
/// المعادلات الفلكية القياسية لموقع الشمس؛ المذهب في العصر: ظل المثل (الجمهور).
class PrayerCalculator {
  static PrayerDay compute({
    required DateTime date,
    required double lat,
    required double lon,
    PrayerMethod? method,
    Duration? utcOffset,
    bool ramadan = false,
  }) {
    final m = method ?? PrayerMethod.forLocation(lat, lon);
    final offset = utcOffset ?? date.timeZoneOffset;
    final tz = offset.inMinutes / 60.0;
    final jd = _julian(date.year, date.month, date.day) - lon / (15 * 24);

    double hours(double t) => t;
    final noon = _midDay(jd, 12 / 24.0);
    final dhuhr = noon;
    final sunrise = noon - _sunAngleTime(jd, 0.833, lat, 6 / 24.0);
    final maghrib = noon + _sunAngleTime(jd, 0.833, lat, 18 / 24.0);
    final fajr = noon - _sunAngleTime(jd, m.fajrAngle, lat, 5 / 24.0);
    final asr = noon + _asrTime(jd, 1, lat, 13 / 24.0);
    final isha = m.ishaAngle != null
        ? noon + _sunAngleTime(jd, m.ishaAngle!, lat, 18 / 24.0)
        : maghrib + (ramadan ? 120 : m.ishaMinutes!) / 60.0;

    DateTime at(double utcHours) {
      final local = hours(utcHours) + tz - lon / 15.0;
      final base = DateTime(date.year, date.month, date.day);
      // دقيقة احتياط (تمكين)، ثم التقريب لأقرب دقيقة كما في التقاويم.
      final minutes = (local * 60).round();
      return base.add(Duration(minutes: minutes));
    }

    return PrayerDay({
      Prayer.fajr: at(fajr),
      Prayer.sunrise: at(sunrise),
      Prayer.dhuhr: at(dhuhr).add(const Duration(minutes: 1)),
      Prayer.asr: at(asr),
      Prayer.maghrib: at(maghrib).add(const Duration(minutes: 1)),
      Prayer.isha: at(isha),
    });
  }

  // ===== فلك =====
  static double _julian(int y, int mo, int d) {
    if (mo <= 2) {
      y -= 1;
      mo += 12;
    }
    final a = (y / 100).floor();
    final b = 2 - a + (a / 4).floor();
    return (365.25 * (y + 4716)).floor() +
        (30.6001 * (mo + 1)).floor() +
        d +
        b -
        1524.5;
  }

  static double _rad(double d) => d * math.pi / 180;
  static double _deg(double r) => r * 180 / math.pi;
  static double _fix(double a, double b) {
    final r = a - b * (a / b).floor();
    return r < 0 ? r + b : r;
  }

  /// يرجع (الميل، معادلة الزمن بالساعات).
  static (double, double) _sun(double jd) {
    final d = jd - 2451545.0;
    final g = _fix(357.529 + 0.98560028 * d, 360);
    final q = _fix(280.459 + 0.98564736 * d, 360);
    final l = _fix(q + 1.915 * math.sin(_rad(g)) + 0.020 * math.sin(_rad(2 * g)), 360);
    final e = 23.439 - 0.00000036 * d;
    final ra = _fix(
            _deg(math.atan2(math.cos(_rad(e)) * math.sin(_rad(l)), math.cos(_rad(l)))) /
                15,
            24);
    final decl = _deg(math.asin(math.sin(_rad(e)) * math.sin(_rad(l))));
    final eqt = q / 15 - ra;
    return (decl, eqt);
  }

  static double _midDay(double jd, double t) {
    final (_, eqt) = _sun(jd + t);
    return _fix(12 - eqt, 24);
  }

  static double _sunAngleTime(double jd, double angle, double lat, double t) {
    final (decl, _) = _sun(jd + t);
    final v = (-math.sin(_rad(angle)) - math.sin(_rad(decl)) * math.sin(_rad(lat))) /
        (math.cos(_rad(decl)) * math.cos(_rad(lat)));
    return _deg(math.acos(v.clamp(-1.0, 1.0))) / 15;
  }

  static double _asrTime(double jd, int factor, double lat, double t) {
    final (decl, _) = _sun(jd + t);
    final angle = -_deg(_atanCot(factor + math.tan(_rad((lat - decl).abs()))));
    return _sunAngleTime(jd, angle, lat, t);
  }

  static double _atanCot(double x) => math.atan(1 / x);
}
