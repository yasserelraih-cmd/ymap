import 'dart:convert';

import 'package:http/http.dart' as http;

import '../navigation/geo.dart';
import 'route.dart';

/// حدود السرعة على طول المسار (من بيانات OpenStreetMap عبر Valhalla).
/// ليست كل الطرق مسجّل لها حد سرعة؛ عندها لا نعرض شيئاً.
class SpeedLimits {
  SpeedLimits(this._ranges);

  /// (من متر، إلى متر، الحد كم/س) على طول المسار.
  final List<(double, double, int)> _ranges;

  static final empty = SpeedLimits(const []);

  bool get isEmpty => _ranges.isEmpty;

  int? at(double progressM) {
    for (final (a, b, v) in _ranges) {
      if (progressM >= a && progressM < b) return v;
    }
    return null;
  }

  /// يحوّل مخرجات trace_attributes إلى مقاطع بالمتر.
  static SpeedLimits fromTrace(Map<String, dynamic> body, RouteResult route) {
    final pts = route.points;
    if (pts.length < 2) return empty;
    final cum = List<double>.filled(pts.length, 0);
    for (var i = 1; i < pts.length; i++) {
      cum[i] = cum[i - 1] +
          distanceMeters(pts[i - 1].lat, pts[i - 1].lon, pts[i].lat, pts[i].lon);
    }
    final out = <(double, double, int)>[];
    for (final e in (body['edges'] as List?) ?? const []) {
      final v = e['speed_limit'];
      if (v is! num || v <= 0) continue;
      final a = (e['begin_shape_index'] as num?)?.toInt();
      final b = (e['end_shape_index'] as num?)?.toInt();
      if (a == null || b == null) continue;
      out.add((
        cum[a.clamp(0, pts.length - 1)],
        cum[b.clamp(0, pts.length - 1)],
        v.round(),
      ));
    }
    return SpeedLimits(out);
  }
}

class SpeedLimitService {
  SpeedLimitService({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;
  static const _endpoint = 'https://valhalla1.openstreetmap.de/trace_attributes';

  Future<SpeedLimits> forRoute(RouteResult route) async {
    if (route.points.length < 2) return SpeedLimits.empty;
    try {
      final request = {
        'shape': [
          for (final p in route.points) {'lat': p.lat, 'lon': p.lon},
        ],
        'costing': 'auto',
        'shape_match': 'map_snap',
        'filters': {
          'attributes': [
            'edge.speed_limit',
            'edge.begin_shape_index',
            'edge.end_shape_index',
          ],
          'action': 'include',
        },
      };
      final res = await _client
          .post(Uri.parse(_endpoint),
              headers: {'content-type': 'application/json'},
              body: jsonEncode(request))
          .timeout(const Duration(seconds: 20));
      if (res.statusCode != 200) return SpeedLimits.empty;
      return SpeedLimits.fromTrace(
          jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>, route);
    } catch (_) {
      return SpeedLimits.empty;
    }
  }
}
