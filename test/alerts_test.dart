import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ymap/alerts/alert_watcher.dart';
import 'package:ymap/alerts/osm_cameras.dart';
import 'package:ymap/alerts/road_alert.dart';
import 'package:ymap/routing/routing_service.dart';
import 'package:ymap/routing/speed_limits.dart';

RoadAlert _cam(String id, double lat, double lon) => RoadAlert(
    id: id, type: AlertType.camera, lat: lat, lon: lon, createdAt: DateTime(2026));

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('AlertWatcher', () {
    // نسير شمالاً (اتجاه 0) من هذه النقطة.
    const lat = 24.70, lon = 46.68;

    test('ينبه للكاميرا أمامك فقط، ومرة واحدة', () {
      final ahead = _cam('a', 24.7020, 46.68); // ~220م شمالاً
      final behind = _cam('b', 24.6980, 46.68); // خلفك
      final side = _cam('c', 24.70, 46.6820); // يمينك
      final w = AlertWatcher([ahead, behind, side]);
      final u = w.toAnnounce(lat, lon, 0, speedMps: 15);
      expect(u?.alert.id, 'a');
      expect(u!.distanceM, closeTo(222, 5));
      expect(w.toAnnounce(lat, lon, 0, speedMps: 15), isNull);
      // ما زالت تظهر في الواجهة حتى تتجاوزها.
      expect(w.nearestAhead(lat, lon, 0, speedMps: 15)?.alert.id, 'a');
    });

    test('مسافة الإنذار أطول على السريع', () {
      final far = _cam('f', 24.7060, 46.68); // ~660م
      final w = AlertWatcher([far]);
      expect(w.nearestAhead(lat, lon, 0, speedMps: 10), isNull);
      expect(w.nearestAhead(lat, lon, 0, speedMps: 30)?.alert.id, 'f');
    });
  });

  test('بلاغ الحادث ينتهي بعد ساعتين والكاميرا تبقى', () async {
    final store = AlertStore();
    final t0 = DateTime(2026, 11, 20, 10);
    await store.add(AlertType.accident, 24.7, 46.7, now: t0);
    await store.add(AlertType.camera, 24.71, 46.71, now: t0);
    expect((await store.load(now: t0.add(const Duration(hours: 1)))).length, 2);
    final later = await store.load(now: t0.add(const Duration(hours: 3)));
    expect(later.map((a) => a.type), [AlertType.camera]);
    final geo = jsonDecode(await store.exportGeoJson()) as Map;
    expect(geo['type'], 'FeatureCollection');
  });

  test('قراءة كاميرات OSM من Overpass', () {
    final list = OsmCameraService.parse({
      'elements': [
        {'id': 1, 'lat': 24.7, 'lon': 46.7, 'tags': {'highway': 'speed_camera', 'maxspeed': '80'}},
      ],
    });
    expect(list.single.maxSpeedKmh, 80);
    expect(list.single.source, AlertSource.osm);
  });

  test('حدود السرعة على مسار الرياض الحقيقي', () {
    final route = ValhallaRoutingService.parseValhalla(jsonDecode(
        File('test/fixtures/valhalla_route.json').readAsStringSync())).first;
    final limits = SpeedLimits.fromTrace(
        jsonDecode(File('test/fixtures/trace_attributes.json').readAsStringSync())
            as Map<String, dynamic>,
        route);
    expect(limits.isEmpty, isFalse);
    final seen = <int>{};
    for (var m = 0.0; m < route.distanceKm * 1000; m += 100) {
      final v = limits.at(m);
      if (v != null) seen.add(v);
    }
    expect(seen, containsAll([60, 80]));
    expect(limits.at(-1), isNull);
  });
}
