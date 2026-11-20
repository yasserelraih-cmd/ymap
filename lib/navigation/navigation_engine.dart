import '../routing/route.dart';
import 'geo.dart';

/// قراءة موقع واحدة أثناء الملاحة.
class NavFix {
  const NavFix({
    required this.lat,
    required this.lon,
    this.speedMps,
    this.headingDeg,
    this.accuracyM,
  });
  final double lat;
  final double lon;
  final double? speedMps;
  final double? headingDeg;
  final double? accuracyM;
}

/// حالة الملاحة بعد كل قراءة موقع.
class NavState {
  const NavState({
    required this.nextManeuver,
    required this.distanceToManeuverM,
    required this.remainingM,
    required this.remainingSec,
    required this.snappedLat,
    required this.snappedLon,
    required this.bearing,
    required this.progressM,
    required this.offRoute,
    required this.arrived,
  });

  /// رقم التعليمة القادمة في route.maneuvers.
  final int nextManeuver;
  final double distanceToManeuverM;
  final double remainingM;
  final double remainingSec;

  /// موقعك ملتصقاً بالمسار (لعرض السيارة على الطريق).
  final double snappedLat;
  final double snappedLon;

  /// اتجاه الطريق عند موقعك (لتدوير الخريطة).
  final double bearing;
  final double progressM;
  final bool offRoute;
  final bool arrived;
}

/// محرك الملاحة: يتابع موقعك على المسار ويحسب التعليمة القادمة.
/// بدون واجهة ولا إنترنت، لذلك يُختبر بسهولة.
class NavigationEngine {
  NavigationEngine(this.route) {
    final pts = route.points;
    _cum = List<double>.filled(pts.length, 0);
    for (var i = 1; i < pts.length; i++) {
      _cum[i] = _cum[i - 1] +
          distanceMeters(pts[i - 1].lat, pts[i - 1].lon, pts[i].lat, pts[i].lon);
    }
    _maneuverPos = [
      for (final m in route.maneuvers)
        _cum[m.beginShapeIndex.clamp(0, pts.length - 1)],
    ];
  }

  final RouteResult route;
  late final List<double> _cum;
  late final List<double> _maneuverPos;

  /// الابتعاد عن المسار أكثر من هذا (بالمتر) يعني الخروج عنه.
  static const offRouteMeters = 45.0;

  /// عدد القراءات المتتالية خارج المسار قبل إعادة الحساب (لتفادي أخطاء GPS).
  static const offRouteFixes = 3;

  /// المسافة المتبقية التي نعتبر عندها أنك وصلت.
  static const arrivalMeters = 30.0;

  int _segment = 0;
  int _offCount = 0;
  bool _arrived = false;

  double get totalMeters => _cum.isEmpty ? 0 : _cum.last;

  /// موقع التعليمة رقم i من بداية المسار (بالمتر).
  double maneuverPosition(int i) => _maneuverPos[i];

  NavState update(NavFix fix) {
    final pts = route.points;
    // نبحث قرب آخر موقع معروف (للأمام أكثر من الخلف) حتى لا نقفز لجزء آخر من المسار.
    final from = (_segment - 5).clamp(0, pts.length - 2);
    final to = (_segment + 400).clamp(0, pts.length - 2);
    var best = _segment.clamp(0, pts.length - 2);
    var bestT = 0.0;
    var bestD = double.infinity;
    for (var i = from; i <= to; i++) {
      final p = projectOnSegment(fix.lat, fix.lon, pts[i].lat, pts[i].lon,
          pts[i + 1].lat, pts[i + 1].lon);
      if (p.distance < bestD - 0.5) {
        bestD = p.distance;
        best = i;
        bestT = p.t;
      }
    }
    _segment = best;
    final segLen = _cum[best + 1] - _cum[best];
    final progress = _cum[best] + segLen * bestT;
    final snapped = interpolate(pts[best].lat, pts[best].lon, pts[best + 1].lat,
        pts[best + 1].lon, bestT);
    final bearing = bearingDegrees(pts[best].lat, pts[best].lon,
        pts[best + 1].lat, pts[best + 1].lon);

    _offCount = bestD > offRouteMeters ? _offCount + 1 : 0;

    var next = route.maneuvers.length - 1;
    for (var i = 0; i < _maneuverPos.length; i++) {
      if (_maneuverPos[i] > progress + 3) {
        next = i;
        break;
      }
    }
    final remaining = (totalMeters - progress).clamp(0.0, double.infinity);
    if (remaining <= arrivalMeters) _arrived = true;
    final ratio = totalMeters == 0 ? 0.0 : remaining / totalMeters;

    return NavState(
      nextManeuver: next,
      distanceToManeuverM:
          (_maneuverPos[next] - progress).clamp(0.0, double.infinity),
      remainingM: remaining,
      remainingSec: route.durationSec * ratio,
      snappedLat: snapped.lat,
      snappedLon: snapped.lon,
      bearing: bearing,
      progressM: progress,
      offRoute: _offCount >= offRouteFixes && !_arrived,
      arrived: _arrived,
    );
  }
}
