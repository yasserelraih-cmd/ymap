import 'dart:convert';

import 'package:http/http.dart' as http;

import 'route.dart';

/// واجهة حساب المسار (لتسهيل الاختبار واستبدال الخادم لاحقاً بخادم YMAP).
/// طريقة التنقل.
enum TravelMode {
  drive('auto'),
  walk('pedestrian');

  const TravelMode(this.costing);
  final String costing;
}

abstract class RoutingService {
  /// يرجع المسار الأفضل أولاً ثم البدائل (حتى مسارين إضافيين).
  Future<List<RouteResult>> route({
    required double fromLat,
    required double fromLon,
    required double toLat,
    required double toLon,
    TravelMode mode = TravelMode.drive,
  });
}

/// Valhalla العام (خادم FOSSGIS التجريبي، مبني على OpenStreetMap).
/// مناسب للتجربة الشخصية؛ قبل النشر العام نشغّل Valhalla على خادم YMAP.
class ValhallaRoutingService implements RoutingService {
  ValhallaRoutingService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static const _endpoint = 'https://valhalla1.openstreetmap.de/route';

  @override
  Future<List<RouteResult>> route({
    required double fromLat,
    required double fromLon,
    required double toLat,
    required double toLon,
    TravelMode mode = TravelMode.drive,
  }) async {
    final request = {
      'locations': [
        {'lat': fromLat, 'lon': fromLon},
        {'lat': toLat, 'lon': toLon},
      ],
      'costing': mode.costing,
      'alternates': 2,
      'units': 'kilometers',
      'directions_options': {'units': 'kilometers'},
    };
    final uri = Uri.parse(_endpoint)
        .replace(queryParameters: {'json': jsonEncode(request)});
    final res = await _client.get(uri).timeout(const Duration(seconds: 20));
    final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    if (res.statusCode != 200 || body['trip'] == null) {
      throw RoutingException(body['error']?.toString() ?? 'HTTP ${res.statusCode}');
    }
    return parseValhalla(body);
  }

  /// يقرأ رد Valhalla: المسار الرئيسي ثم البدائل.
  static List<RouteResult> parseValhalla(Map<String, dynamic> body) {
    final routes = <RouteResult>[_trip(body['trip'] as Map<String, dynamic>)];
    for (final alt in (body['alternates'] as List?) ?? const []) {
      final trip = (alt as Map)['trip'];
      if (trip is Map<String, dynamic>) routes.add(_trip(trip));
    }
    return routes;
  }

  static RouteResult _trip(Map<String, dynamic> trip) {
    final summary = trip['summary'] as Map<String, dynamic>;
    final points = <GeoPoint>[];
    final maneuvers = <Maneuver>[];
    for (final leg in (trip['legs'] as List).cast<Map<String, dynamic>>()) {
      final offset = points.isEmpty ? 0 : points.length - 1;
      final legPoints = decodePolyline6(leg['shape'] as String);
      points.addAll(points.isEmpty ? legPoints : legPoints.skip(1));
      for (final m in (leg['maneuvers'] as List).cast<Map<String, dynamic>>()) {
        maneuvers.add(Maneuver(
          type: m['type'] as int,
          streetNames: ((m['street_names'] as List?) ?? const []).cast<String>(),
          lengthKm: (m['length'] as num).toDouble(),
          timeSec: (m['time'] as num).toDouble(),
          beginShapeIndex: (m['begin_shape_index'] as int) + offset,
          roundaboutExit: m['roundabout_exit_count'] as int?,
        ));
      }
    }
    return RouteResult(
      points: points,
      distanceKm: (summary['length'] as num).toDouble(),
      durationSec: (summary['time'] as num).toDouble(),
      maneuvers: maneuvers,
      hasToll: summary['has_toll'] == true,
    );
  }
}

class RoutingException implements Exception {
  RoutingException(this.message);
  final String message;
  @override
  String toString() => 'RoutingException: $message';
}
