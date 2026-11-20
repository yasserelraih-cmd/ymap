import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../navigation/geo.dart';

/// نقطة من مسار مسجّل.
class TrackPoint {
  const TrackPoint(this.lat, this.lon, this.time, {this.speedMps});
  final double lat;
  final double lon;
  final DateTime time;
  final double? speedMps;
}

/// بلاغ «الخريطة هنا غير دقيقة».
class MapIssue {
  const MapIssue({
    required this.lat,
    required this.lon,
    required this.note,
    required this.createdAt,
  });
  final double lat;
  final double lon;
  final String note;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'lat': lat,
        'lon': lon,
        'note': note,
        'createdAt': createdAt.toIso8601String(),
      };

  static MapIssue fromJson(Map<String, dynamic> j) => MapIssue(
        lat: (j['lat'] as num).toDouble(),
        lon: (j['lon'] as num).toDouble(),
        note: j['note'] as String? ?? '',
        createdAt: DateTime.parse(j['createdAt'] as String),
      );
}

/// يحذف أول وآخر [meters] متر من المسار حتى لا يظهر مكان بيتك أو عملك.
List<TrackPoint> trimEnds(List<TrackPoint> pts, {double meters = 200}) {
  if (pts.length < 3) return const [];
  var start = 0;
  var d = 0.0;
  while (start < pts.length - 1 && d < meters) {
    d += distanceMeters(pts[start].lat, pts[start].lon, pts[start + 1].lat,
        pts[start + 1].lon);
    start++;
  }
  var end = pts.length - 1;
  d = 0;
  while (end > start && d < meters) {
    d += distanceMeters(
        pts[end].lat, pts[end].lon, pts[end - 1].lat, pts[end - 1].lon);
    end--;
  }
  if (end - start < 2) return const [];
  return pts.sublist(start, end + 1);
}

/// مساهماتك في تحسين الخريطة: مسارات مسجلة (بموافقتك) وبلاغات أخطاء.
/// كلها على جهازك فقط الآن؛ الرفع للخادم يأتي في المرحلة 2 مع الحسابات.
class Contributions {
  static const _kConsent = 'track_consent'; // null = لم نسأل بعد
  static const _kTracks = 'tracks';
  static const _kIssues = 'map_issues';
  static const maxTracks = 50;

  Future<bool?> consent() async =>
      (await SharedPreferences.getInstance()).getBool(_kConsent);

  Future<void> setConsent(bool on) async =>
      (await SharedPreferences.getInstance()).setBool(_kConsent, on);

  /// يحفظ المسار بعد قص الأطراف. يرجع false إذا كان قصيراً جداً.
  Future<bool> saveTrack(List<TrackPoint> raw) async {
    final pts = trimEnds(raw);
    if (pts.isEmpty) return false;
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_kTracks) ?? <String>[];
    list.add(jsonEncode({
      'start': pts.first.time.toIso8601String(),
      'coords': [
        for (final p in pts)
          [
            double.parse(p.lon.toStringAsFixed(6)),
            double.parse(p.lat.toStringAsFixed(6)),
          ],
      ],
    }));
    while (list.length > maxTracks) {
      list.removeAt(0);
    }
    await prefs.setStringList(_kTracks, list);
    return true;
  }

  Future<int> trackCount() async =>
      ((await SharedPreferences.getInstance()).getStringList(_kTracks) ?? const [])
          .length;

  Future<void> addIssue(MapIssue issue) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_kIssues) ?? <String>[];
    list.add(jsonEncode(issue.toJson()));
    await prefs.setStringList(_kIssues, list);
  }

  Future<List<MapIssue>> issues() async {
    final prefs = await SharedPreferences.getInstance();
    return [
      for (final s in prefs.getStringList(_kIssues) ?? const <String>[])
        MapIssue.fromJson(jsonDecode(s) as Map<String, dynamic>),
    ];
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kTracks);
    await prefs.remove(_kIssues);
  }

  /// كل مساهماتك كـ GeoJSON (للتصدير أو المراجعة).
  Future<String> exportGeoJson() async {
    final prefs = await SharedPreferences.getInstance();
    final features = <Map<String, dynamic>>[];
    for (final s in prefs.getStringList(_kTracks) ?? const <String>[]) {
      final t = jsonDecode(s) as Map<String, dynamic>;
      features.add({
        'type': 'Feature',
        'geometry': {'type': 'LineString', 'coordinates': t['coords']},
        'properties': {'kind': 'track', 'start': t['start']},
      });
    }
    for (final i in await issues()) {
      features.add({
        'type': 'Feature',
        'geometry': {
          'type': 'Point',
          'coordinates': [i.lon, i.lat],
        },
        'properties': {
          'kind': 'map_issue',
          'note': i.note,
          'createdAt': i.createdAt.toIso8601String(),
        },
      });
    }
    return jsonEncode({'type': 'FeatureCollection', 'features': features});
  }
}
