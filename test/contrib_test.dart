import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ymap/contrib/contributions.dart';

/// خط مستقيم شمالاً: نقطة كل ~11 متر لمسافة ~1.1 كم.
List<TrackPoint> _line() => [
      for (var i = 0; i <= 100; i++)
        TrackPoint(24.70 + i * 0.0001, 46.68, DateTime(2026, 11, 20, 8, 0, i)),
    ];

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('قص أول وآخر 200 متر', () {
    final pts = _line();
    final trimmed = trimEnds(pts);
    // كل نقطة ~11.1م، إذن نحذف ~18 نقطة من كل طرف.
    expect(trimmed.first.lat, greaterThan(24.70 + 0.0017));
    expect(trimmed.last.lat, lessThan(24.71 - 0.0017));
    expect(trimEnds(pts.sublist(0, 20)), isEmpty); // رحلة قصيرة جداً لا تُحفظ
  });

  test('الموافقة والحفظ والتصدير والحذف', () async {
    final c = Contributions();
    expect(await c.consent(), isNull);
    await c.setConsent(true);
    expect(await c.consent(), isTrue);
    expect(await c.saveTrack(_line()), isTrue);
    await c.addIssue(MapIssue(
        lat: 24.7, lon: 46.7, note: 'الدوار تغيّر', createdAt: DateTime(2026)));
    expect(await c.trackCount(), 1);
    final geo = jsonDecode(await c.exportGeoJson()) as Map;
    final kinds = [for (final f in geo['features']) f['properties']['kind']];
    expect(kinds, ['track', 'map_issue']);
    await c.clearAll();
    expect(await c.trackCount(), 0);
    expect(await c.issues(), isEmpty);
  });
}
