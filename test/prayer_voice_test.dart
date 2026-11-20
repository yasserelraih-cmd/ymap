import 'package:flutter_test/flutter_test.dart';
import 'package:ymap/navigation/geo.dart';
import 'package:ymap/prayer/prayer_times.dart';
import 'package:ymap/routing/route.dart';
import 'package:ymap/search/categories.dart';
import 'package:ymap/search/location_link.dart';
import 'package:ymap/voice/voice_command.dart';

String hm(DateTime d) =>
    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

void main() {
  test('أوقات الصلاة — الرياض 20 نوفمبر 2026 (أم القرى)', () {
    final day = PrayerCalculator.compute(
      date: DateTime(2026, 11, 20),
      lat: 24.7136,
      lon: 46.6753,
      utcOffset: const Duration(hours: 3),
    );
    // ignore: avoid_print
    print({for (final e in day.times.entries) e.key.name: hm(e.value)});
    int mins(Prayer p) => day.times[p]!.hour * 60 + day.times[p]!.minute;
    // مرجع مستقل (خوارزمية NOAA): شروق 06:12، غروب 17:05، زوال 11:39.
    expect(mins(Prayer.fajr), closeTo(4 * 60 + 51, 3));
    expect(mins(Prayer.sunrise), closeTo(6 * 60 + 12, 2));
    expect(mins(Prayer.dhuhr), closeTo(11 * 60 + 40, 2));
    expect(mins(Prayer.asr), closeTo(14 * 60 + 43, 4));
    expect(mins(Prayer.maghrib), closeTo(17 * 60 + 6, 2));
    expect(mins(Prayer.isha), mins(Prayer.maghrib) - 1 + 90);
  });

  test('أسوان تستخدم طريقة الهيئة المصرية', () {
    expect(PrayerMethod.forLocation(24.09, 32.90), PrayerMethod.egypt);
    expect(PrayerMethod.forLocation(24.71, 46.67), PrayerMethod.ummAlQura);
  });

  group('الأوامر الصوتية', () {
    test('ودّني أقرب بنزينة على طريقي', () {
      final c = VoiceCommand.parse('ودّني أقرب بنزينة على طريقي');
      expect(c.category, PlaceCategory.fuel);
      expect(c.navigate, isTrue);
      expect(c.nearest, isTrue);
      expect(c.alongRoute, isTrue);
    });
    test('خذني لصيدلية', () {
      final c = VoiceCommand.parse('خذني لصيدلية');
      expect(c.category, PlaceCategory.pharmacy);
      expect(c.navigate, isTrue);
    });
    test('ودني إلى العليا مول = بحث عادي', () {
      final c = VoiceCommand.parse('ودني إلى العليا مول');
      expect(c.category, isNull);
      expect(c.query, 'العليا مول');
      expect(c.navigate, isTrue);
    });
    test('أقرب مسجد', () {
      final c = VoiceCommand.parse('أقرب مسجد');
      expect(c.category, PlaceCategory.mosque);
      expect(c.navigate, isFalse);
    });
  });

  test('رابط YMAP يُبنى ويُقرأ', () {
    final link = LocationLink.ymap(24.7136, 46.6753, name: 'برج المملكة');
    final p = LocationLink.parse(link.toString())!;
    expect(p.lat, closeTo(24.7136, 1e-6));
    expect(p.name, 'برج المملكة');
  });

  test('نقطة على بعد مسافة من بداية الخط', () {
    const pts = [GeoPoint(24.70, 46.68), GeoPoint(24.71, 46.68)];
    final half = pointAlong(pts, 555);
    expect(half.lat, closeTo(24.705, 0.0002));
    expect(pointAlong(pts, 99999).lat, 24.71);
  });
}

