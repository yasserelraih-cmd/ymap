import '../routing/route.dart';
import 'dart:math' as math;

const _earthRadius = 6371008.8; // متر

double _rad(double d) => d * math.pi / 180;

/// المسافة بالمتر بين نقطتين (Haversine).
double distanceMeters(double lat1, double lon1, double lat2, double lon2) {
  final dLat = _rad(lat2 - lat1);
  final dLon = _rad(lon2 - lon1);
  final a = math.pow(math.sin(dLat / 2), 2) +
      math.cos(_rad(lat1)) * math.cos(_rad(lat2)) * math.pow(math.sin(dLon / 2), 2);
  return 2 * _earthRadius * math.asin(math.min(1, math.sqrt(a)));
}

/// الاتجاه من نقطة لأخرى بالدرجات (0 = شمال، 90 = شرق).
double bearingDegrees(double lat1, double lon1, double lat2, double lon2) {
  final y = math.sin(_rad(lon2 - lon1)) * math.cos(_rad(lat2));
  final x = math.cos(_rad(lat1)) * math.sin(_rad(lat2)) -
      math.sin(_rad(lat1)) * math.cos(_rad(lat2)) * math.cos(_rad(lon2 - lon1));
  return (math.atan2(y, x) * 180 / math.pi + 360) % 360;
}

/// إسقاط نقطة على قطعة مستقيمة قصيرة (تقريب مستوٍ دقيق لمسافات المدن).
/// يرجع (t بين 0 و1، والمسافة الجانبية بالمتر).
({double t, double distance}) projectOnSegment(
  double lat,
  double lon,
  double aLat,
  double aLon,
  double bLat,
  double bLon,
) {
  final k = math.cos(_rad((aLat + bLat) / 2));
  final ax = aLon * k, ay = aLat, bx = bLon * k, by = bLat;
  final px = lon * k, py = lat;
  final dx = bx - ax, dy = by - ay;
  final len2 = dx * dx + dy * dy;
  var t = len2 == 0 ? 0.0 : ((px - ax) * dx + (py - ay) * dy) / len2;
  t = t.clamp(0.0, 1.0);
  final qLat = aLat + (bLat - aLat) * t;
  final qLon = aLon + (bLon - aLon) * t;
  return (t: t, distance: distanceMeters(lat, lon, qLat, qLon));
}

/// نقطة على بعد معيّن داخل قطعة.
({double lat, double lon}) interpolate(
        double aLat, double aLon, double bLat, double bLon, double t) =>
    (lat: aLat + (bLat - aLat) * t, lon: aLon + (bLon - aLon) * t);

/// النقطة التي تبعد [meters] متراً من بداية الخط (أو آخر نقطة).
GeoPoint pointAlong(List<GeoPoint> pts, double meters) {
  if (pts.isEmpty) return const GeoPoint(0, 0);
  var left = meters;
  for (var i = 1; i < pts.length; i++) {
    final d = distanceMeters(pts[i - 1].lat, pts[i - 1].lon, pts[i].lat, pts[i].lon);
    if (d >= left && d > 0) {
      final t = left / d;
      return GeoPoint(pts[i - 1].lat + (pts[i].lat - pts[i - 1].lat) * t,
          pts[i - 1].lon + (pts[i].lon - pts[i - 1].lon) * t);
    }
    left -= d;
  }
  return pts.last;
}
