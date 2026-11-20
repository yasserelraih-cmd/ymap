/// نقطة على المسار.
class GeoPoint {
  const GeoPoint(this.lat, this.lon);
  final double lat;
  final double lon;
}

/// تعليمة واحدة في المسار (التفاف، مخرج، دوار...).
class Maneuver {
  const Maneuver({
    required this.type,
    required this.streetNames,
    required this.lengthKm,
    required this.timeSec,
    required this.beginShapeIndex,
    this.roundaboutExit,
  });

  /// نوع التعليمة حسب Valhalla (مثال: 10 = يمين، 15 = يسار، 4 = الوصول).
  final int type;
  final List<String> streetNames;
  final double lengthKm;
  final double timeSec;
  final int beginShapeIndex;
  final int? roundaboutExit;
}

/// مسار كامل من نقطة لنقطة.
class RouteResult {
  const RouteResult({
    required this.points,
    required this.distanceKm,
    required this.durationSec,
    required this.maneuvers,
    this.hasToll = false,
  });

  final List<GeoPoint> points;
  final double distanceKm;
  final double durationSec;
  final List<Maneuver> maneuvers;
  final bool hasToll;

  Duration get duration => Duration(seconds: durationSec.round());
}

/// فك ترميز خط المسار (Encoded Polyline بدقة 6 خانات كما يرسله Valhalla).
List<GeoPoint> decodePolyline6(String encoded) {
  final points = <GeoPoint>[];
  var index = 0, lat = 0, lon = 0;
  int next() {
    var result = 0, shift = 0, b = 0;
    do {
      b = encoded.codeUnitAt(index++) - 63;
      result |= (b & 0x1f) << shift;
      shift += 5;
    } while (b >= 0x20);
    // لا نستخدم ~ لأنه في المتصفح (JavaScript) يعطي رقماً موجباً كبيراً بدل السالب.
    return (result & 1) != 0 ? -(result >> 1) - 1 : (result >> 1);
  }

  while (index < encoded.length) {
    lat += next();
    lon += next();
    points.add(GeoPoint(lat / 1e6, lon / 1e6));
  }
  return points;
}
