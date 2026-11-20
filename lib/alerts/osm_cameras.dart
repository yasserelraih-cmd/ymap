import 'dart:convert';
import 'dart:math' as math;

import 'package:http/http.dart' as http;

import '../routing/route.dart';
import 'road_alert.dart';

/// كاميرات السرعة المسجلة في OpenStreetMap (highway=speed_camera)
/// حول مسارك. خدمة Overpass مجانية لكنها أحياناً بطيئة؛ لو فشلت نكمل بدونها.
class OsmCameraService {
  OsmCameraService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static const _endpoints = [
    'https://overpass-api.de/api/interpreter',
    'https://overpass.kumi.systems/api/interpreter',
  ];

  Future<List<RoadAlert>> alongRoute(RouteResult route) async {
    if (route.points.isEmpty) return const [];
    var minLat = 90.0, maxLat = -90.0, minLon = 180.0, maxLon = -180.0;
    for (final p in route.points) {
      minLat = math.min(minLat, p.lat);
      maxLat = math.max(maxLat, p.lat);
      minLon = math.min(minLon, p.lon);
      maxLon = math.max(maxLon, p.lon);
    }
    const pad = 0.01;
    final bbox =
        '${minLat - pad},${minLon - pad},${maxLat + pad},${maxLon + pad}';
    final query =
        '[out:json][timeout:15];node["highway"="speed_camera"]($bbox);out body;';
    for (final url in _endpoints) {
      try {
        final res = await _client
            .post(Uri.parse(url), body: {'data': query})
            .timeout(const Duration(seconds: 15));
        if (res.statusCode != 200) continue;
        return parse(jsonDecode(utf8.decode(res.bodyBytes)));
      } catch (_) {
        continue;
      }
    }
    return const [];
  }

  static List<RoadAlert> parse(dynamic body) {
    final out = <RoadAlert>[];
    for (final e in (body['elements'] as List?) ?? const []) {
      final tags = (e['tags'] as Map?) ?? const {};
      out.add(RoadAlert(
        id: 'osm${e['id']}',
        type: AlertType.camera,
        lat: (e['lat'] as num).toDouble(),
        lon: (e['lon'] as num).toDouble(),
        createdAt: DateTime.fromMillisecondsSinceEpoch(0),
        source: AlertSource.osm,
        maxSpeedKmh: int.tryParse('${tags['maxspeed'] ?? ''}'),
      ));
    }
    return out;
  }
}
