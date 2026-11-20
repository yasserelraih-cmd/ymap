import 'dart:async';

import 'package:geolocator/geolocator.dart';

import '../routing/route.dart';
import 'geo.dart';
import 'navigation_engine.dart';

/// مصدر قراءات الموقع أثناء الملاحة: GPS الحقيقي أو محاكاة القيادة.
abstract class PositionSource {
  Stream<NavFix> get fixes;
  bool get isSimulation;
  void dispose();
}

/// GPS الحقيقي من الجوال.
class GpsPositionSource implements PositionSource {
  StreamSubscription<Position>? _sub;
  final _controller = StreamController<NavFix>.broadcast();

  GpsPositionSource() {
    _sub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 2,
      ),
    ).listen((p) => _controller.add(NavFix(
          lat: p.latitude,
          lon: p.longitude,
          speedMps: p.speed >= 0 ? p.speed : null,
          headingDeg: p.heading >= 0 ? p.heading : null,
          accuracyM: p.accuracy,
        )));
  }

  @override
  Stream<NavFix> get fixes => _controller.stream;
  @override
  bool get isSimulation => false;
  @override
  void dispose() {
    _sub?.cancel();
    _controller.close();
  }
}

/// «معاينة القيادة»: سيارة افتراضية تسير على المسار بسرعة الطريق الحقيقية × المضاعف.
/// مفيدة لتجربة الملاحة من البيت، ولاختبار التطبيق.
class SimulatedPositionSource implements PositionSource {
  SimulatedPositionSource(this.route, {this.speedFactor = 4, this.tick = const Duration(milliseconds: 500)}) {
    final pts = route.points;
    _cum = [0];
    for (var i = 1; i < pts.length; i++) {
      _cum.add(_cum.last +
          distanceMeters(pts[i - 1].lat, pts[i - 1].lon, pts[i].lat, pts[i].lon));
    }
    // متوسط السرعة الحقيقي للمسار (م/ث) من الوقت المتوقع.
    _speed = route.durationSec > 0 ? _cum.last / route.durationSec : 12;
    _timer = Timer.periodic(tick, (_) => _step());
  }

  final RouteResult route;
  final double speedFactor;
  final Duration tick;
  late final List<double> _cum;
  late final double _speed;
  late final Timer _timer;
  final _controller = StreamController<NavFix>.broadcast();
  double _pos = 0;
  int _seg = 0;

  void _step() {
    final pts = route.points;
    _pos += _speed * speedFactor * tick.inMilliseconds / 1000;
    if (_pos >= _cum.last) {
      _pos = _cum.last;
      _timer.cancel();
    }
    while (_seg < pts.length - 2 && _cum[_seg + 1] < _pos) {
      _seg++;
    }
    final len = _cum[_seg + 1] - _cum[_seg];
    final t = len == 0 ? 0.0 : ((_pos - _cum[_seg]) / len).clamp(0.0, 1.0);
    final p = interpolate(pts[_seg].lat, pts[_seg].lon, pts[_seg + 1].lat,
        pts[_seg + 1].lon, t);
    _controller.add(NavFix(
      lat: p.lat,
      lon: p.lon,
      speedMps: _pos >= _cum.last ? 0 : _speed,
      headingDeg: bearingDegrees(pts[_seg].lat, pts[_seg].lon,
          pts[_seg + 1].lat, pts[_seg + 1].lon),
    ));
  }

  @override
  Stream<NavFix> get fixes => _controller.stream;
  @override
  bool get isSimulation => true;
  @override
  void dispose() {
    _timer.cancel();
    _controller.close();
  }
}
