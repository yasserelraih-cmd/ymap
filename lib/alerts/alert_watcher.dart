import '../navigation/geo.dart';
import 'road_alert.dart';

/// تنبيه قادم أمامك.
class UpcomingAlert {
  const UpcomingAlert(this.alert, this.distanceM);
  final RoadAlert alert;
  final double distanceM;
}

/// يراقب التنبيهات أمامك في اتجاه سيرك فقط (ولا ينبه للمعاكس)،
/// وينطق كل تنبيه مرة واحدة. يعمل بدون إنترنت بعد تحميل التنبيهات.
class AlertWatcher {
  AlertWatcher(this.alerts);

  List<RoadAlert> alerts;
  final _announced = <String>{};

  /// أقصى زاوية بين اتجاهك واتجاه التنبيه لنعتبره «أمامك».
  static const coneDeg = 35.0;

  /// يرجع أقرب تنبيه أمامك ضمن مسافة الإنذار، أو null.
  UpcomingAlert? nearestAhead(double lat, double lon, double headingDeg,
      {required double speedMps}) {
    final range = warnDistance(speedMps);
    UpcomingAlert? best;
    for (final a in alerts) {
      final d = distanceMeters(lat, lon, a.lat, a.lon);
      if (d > range || d < 5) continue;
      final b = bearingDegrees(lat, lon, a.lat, a.lon);
      var diff = (b - headingDeg).abs() % 360;
      if (diff > 180) diff = 360 - diff;
      if (diff > coneDeg) continue;
      if (best == null || d < best.distanceM) best = UpcomingAlert(a, d);
    }
    return best;
  }

  /// يرجع التنبيه إذا لم يُنطق بعد (ثم يعلّمه كمنطوق).
  UpcomingAlert? toAnnounce(double lat, double lon, double headingDeg,
      {required double speedMps}) {
    final u = nearestAhead(lat, lon, headingDeg, speedMps: speedMps);
    if (u == null || _announced.contains(u.alert.id)) return null;
    _announced.add(u.alert.id);
    return u;
  }

  /// مسافة الإنذار: 300م في المدينة، حتى 800م على السريع.
  static double warnDistance(double speedMps) =>
      (speedMps * 25).clamp(300, 800).toDouble();
}
