import '../routing/instructions.dart';
import '../routing/route.dart';
import 'navigation_engine.dart';

/// يقرر متى تُقال كل جملة صوتية وما نصها (مرة واحدة لكل مرحلة).
/// المراحل: تنبيه مبكر (بعد X متر) ثم تنبيه عند الالتفاف.
class VoiceGuide {
  VoiceGuide(this.route, {required this.lang, this.dialect = VoiceDialect.saudi});

  final VoiceDialect dialect;

  final RouteResult route;
  final String lang;
  final _spoken = <String>{};

  /// يرجع الجملة التي يجب قولها الآن، أو null.
  String? next(NavState s, {double speedMps = 0}) {
    if (s.arrived) {
      return _once('arrived', lang == 'ar' ? dialect.arrived : 'You have arrived');
    }
    final i = s.nextManeuver;
    final m = route.maneuvers[i];
    final d = s.distanceToManeuverM;
    // مسافات التنبيه تكبر مع السرعة (على الطرق السريعة نحتاج وقتاً أطول).
    final far = speedMps * 25 > 600 ? 1000.0 : 500.0;
    final near = (speedMps * 7).clamp(60.0, 200.0);

    if (d <= near) {
      return _once('$i-now', Instructions.spoken(m, lang, dialect));
    }
    if (d <= far && d > near * 1.8 && m.type != 4 && m.type != 5 && m.type != 6) {
      return _once('$i-far', '${distancePhrase(d)}، ${Instructions.spoken(m, lang, dialect)}');
    }
    return null;
  }

  String? _once(String key, String text) => _spoken.add(key) ? text : null;

  /// «بعد 500 متر» / «بعد كيلو ونص» بصيغة طبيعية.
  String distancePhrase(double meters) {
    final ar = lang == 'ar';
    if (meters >= 950) {
      final km = (meters / 500).round() / 2; // أقرب نصف كيلو
      if (ar) {
        if (km == 1) return 'بعد كيلو';
        if (km == 1.5) return 'بعد كيلو ونص';
        if (km == 2) return 'بعد 2 كيلو';
        return 'بعد ${km.toStringAsFixed(km == km.roundToDouble() ? 0 : 1)} كيلو';
      }
      return 'In ${km.toStringAsFixed(km == km.roundToDouble() ? 0 : 1)} kilometers';
    }
    final m = meters >= 200 ? (meters / 100).round() * 100 : (meters / 50).round() * 50;
    return ar ? 'بعد $m متر' : 'In $m meters';
  }
}
