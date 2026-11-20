import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ymap/navigation/geo.dart';
import 'package:ymap/navigation/navigation_engine.dart';
import 'package:ymap/navigation/voice_guide.dart';
import 'package:ymap/routing/routing_service.dart';

void main() {
  final route = ValhallaRoutingService.parseValhalla(jsonDecode(
          File('test/fixtures/valhalla_route.json').readAsStringSync())
      as Map<String, dynamic>).first;

  /// نقاط على المسار كل [step] متر (قيادة افتراضية).
  List<NavFix> drive({double step = 25}) {
    final pts = route.points;
    final out = <NavFix>[];
    for (var i = 0; i < pts.length - 1; i++) {
      final len = distanceMeters(pts[i].lat, pts[i].lon, pts[i + 1].lat, pts[i + 1].lon);
      final n = (len / step).ceil().clamp(1, 1000);
      for (var k = 0; k < n; k++) {
        final p = interpolate(pts[i].lat, pts[i].lon, pts[i + 1].lat, pts[i + 1].lon, k / n);
        out.add(NavFix(lat: p.lat, lon: p.lon, speedMps: 14));
      }
    }
    out.add(NavFix(lat: pts.last.lat, lon: pts.last.lon, speedMps: 0));
    return out;
  }

  test('طول المسار المحسوب يطابق طول Valhalla تقريباً', () {
    final e = NavigationEngine(route);
    expect(e.totalMeters / 1000, closeTo(route.distanceKm, route.distanceKm * 0.03));
  });

  test('القيادة على المسار: التقدم يزيد، التعليمات تتقدم، ثم الوصول', () {
    final e = NavigationEngine(route);
    var lastProgress = -1.0;
    var lastManeuver = 0;
    NavState? s;
    for (final f in drive()) {
      s = e.update(f);
      expect(s.offRoute, isFalse);
      expect(s.progressM, greaterThanOrEqualTo(lastProgress - 1));
      expect(s.nextManeuver, greaterThanOrEqualTo(lastManeuver));
      lastProgress = s.progressM;
      lastManeuver = s.nextManeuver;
    }
    expect(s!.arrived, isTrue);
    expect(s.remainingM, lessThan(NavigationEngine.arrivalMeters));
    expect(lastManeuver, route.maneuvers.length - 1);
  });

  test('الخروج عن المسار يُكتشف بعد 3 قراءات متتالية فقط', () {
    final e = NavigationEngine(route);
    final p = route.points[40];
    e.update(NavFix(lat: p.lat, lon: p.lon));
    // 300 متر شمالاً تقريباً.
    final away = NavFix(lat: p.lat + 0.0027, lon: p.lon);
    expect(e.update(away).offRoute, isFalse);
    expect(e.update(away).offRoute, isFalse);
    expect(e.update(away).offRoute, isTrue);
    // العودة للمسار تلغي الحالة.
    expect(e.update(NavFix(lat: p.lat, lon: p.lon)).offRoute, isFalse);
  });

  test('الصوت: تنبيه مبكر ثم عند الالتفاف، بدون تكرار متتالٍ، ثم «وصلت»', () {
    final e = NavigationEngine(route);
    final v = VoiceGuide(route, lang: 'ar');
    final said = <String>[];
    for (final f in drive(step: 10)) {
      final text = v.next(e.update(f), speedMps: 14);
      if (text != null) said.add(text);
    }
    for (var i = 1; i < said.length; i++) {
      expect(said[i], isNot(said[i - 1]), reason: 'لا تكرار متتالٍ');
    }
    expect(said.last, 'وصلت إلى وجهتك');
    expect(said.where((s) => s.startsWith('بعد ')), isNotEmpty);
    // لا كلمات إنجليزية في الإرشاد العربي.
    for (final s in said) {
      expect(RegExp(r'\b(Turn|Keep|onto|In)\b').hasMatch(s), isFalse, reason: s);
    }
  });

  test('صيغ المسافة الطبيعية', () {
    final v = VoiceGuide(route, lang: 'ar');
    expect(v.distancePhrase(480), 'بعد 500 متر');
    expect(v.distancePhrase(130), 'بعد 150 متر');
    expect(v.distancePhrase(1020), 'بعد كيلو');
    expect(v.distancePhrase(1600), 'بعد كيلو ونص');
  });
}
