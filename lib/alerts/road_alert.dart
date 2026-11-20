import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// أنواع التنبيهات على الطريق.
enum AlertType {
  camera(persistent: true, color: '#E5484D'),
  accident(persistent: false, color: '#F2A541'),
  traffic(persistent: false, color: '#D97706'),
  hazard(persistent: false, color: '#8B5CF6');

  const AlertType({required this.persistent, required this.color});

  /// الكاميرات ثابتة؛ الحوادث والزحام والمخاطر تنتهي بعد ساعتين.
  final bool persistent;
  final String color;
}

/// مصدر التنبيه: OpenStreetMap أو بلاغك أنت.
enum AlertSource { osm, user }

class RoadAlert {
  const RoadAlert({
    required this.id,
    required this.type,
    required this.lat,
    required this.lon,
    required this.createdAt,
    this.source = AlertSource.user,
    this.maxSpeedKmh,
  });

  final String id;
  final AlertType type;
  final double lat;
  final double lon;
  final DateTime createdAt;
  final AlertSource source;
  final int? maxSpeedKmh;

  static const lifetime = Duration(hours: 2);

  bool isExpired(DateTime now) =>
      !type.persistent && now.difference(createdAt) > lifetime;

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'lat': lat,
        'lon': lon,
        'createdAt': createdAt.toIso8601String(),
        'source': source.name,
        if (maxSpeedKmh != null) 'max': maxSpeedKmh,
      };

  static RoadAlert fromJson(Map<String, dynamic> j) => RoadAlert(
        id: j['id'] as String,
        type: AlertType.values.byName(j['type'] as String),
        lat: (j['lat'] as num).toDouble(),
        lon: (j['lon'] as num).toDouble(),
        createdAt: DateTime.parse(j['createdAt'] as String),
        source: AlertSource.values.byName(j['source'] as String? ?? 'user'),
        maxSpeedKmh: j['max'] as int?,
      );
}

/// بلاغاتك محفوظة على جهازك (تُشارك مع المجتمع في المرحلة 2 بعد الحسابات).
class AlertStore {
  static const _key = 'user_alerts';

  Future<List<RoadAlert>> load({DateTime? now}) async {
    final prefs = await SharedPreferences.getInstance();
    final t = now ?? DateTime.now();
    final all = <RoadAlert>[];
    for (final s in prefs.getStringList(_key) ?? const <String>[]) {
      try {
        all.add(RoadAlert.fromJson(jsonDecode(s) as Map<String, dynamic>));
      } catch (_) {}
    }
    return all.where((a) => !a.isExpired(t)).toList();
  }

  Future<RoadAlert> add(AlertType type, double lat, double lon,
      {DateTime? now}) async {
    final t = now ?? DateTime.now();
    final alert = RoadAlert(
      id: 'u${t.microsecondsSinceEpoch}',
      type: type,
      lat: lat,
      lon: lon,
      createdAt: t,
    );
    final list = [...await load(now: t), alert];
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        _key, [for (final a in list) jsonEncode(a.toJson())]);
    return alert;
  }

  Future<void> remove(String id) async {
    final list = (await load()).where((a) => a.id != id);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        _key, [for (final a in list) jsonEncode(a.toJson())]);
  }

  /// تصدير البلاغات كـ GeoJSON (للمراجعة أو المشاركة).
  Future<String> exportGeoJson() async {
    final list = await load();
    return jsonEncode({
      'type': 'FeatureCollection',
      'features': [
        for (final a in list)
          {
            'type': 'Feature',
            'geometry': {
              'type': 'Point',
              'coordinates': [a.lon, a.lat],
            },
            'properties': {
              'type': a.type.name,
              'createdAt': a.createdAt.toIso8601String(),
            },
          },
      ],
    });
  }
}
