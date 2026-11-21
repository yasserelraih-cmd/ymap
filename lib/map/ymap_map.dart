import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:math' show Point;

import 'package:flutter/services.dart' show rootBundle;
import 'package:geolocator/geolocator.dart' show Position;
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:material_ui/material_ui.dart';

import '../alerts/road_alert.dart';
import '../l10n/app_localizations.dart';
import '../routing/route.dart';
import 'compass/compass.dart';
import 'location_service.dart';
import 'map_style.dart';
import 'nav_layers.dart';

/// خريطة YMAP: بيانات OpenStreetMap عبر OpenFreeMap، تُعرض بمحرك MapLibre.
class YmapMap extends StatefulWidget {
  const YmapMap({
    super.key,
    required this.languageCode,
    required this.dark,
    required this.isTablet,
    required this.onMessage,
    this.onRouteTapped,
    this.navigating = false,
  });

  /// أثناء الملاحة نخفي البوصلة (الشريط العلوي يغطي مكانها).
  final bool navigating;

  final String languageCode;
  final bool dark;
  final bool isTablet;
  final void Function(String message) onMessage;

  /// عند الضغط على مسار بديل في الخريطة (يرجع رقمه).
  final void Function(int index)? onRouteTapped;

  /// وسط الرياض.
  static const riyadh = LatLng(24.7136, 46.6753);

  @override
  State<YmapMap> createState() => YmapMapState();
}

/// كاميرا تُظهر المستطيل كاملاً داخل المساحة الظاهرة (بعد طرح البطاقات).
/// حسابات Web Mercator بمربعات 512 بكسل كما في MapLibre.
CameraPosition fitBounds({
  required double minLat,
  required double minLon,
  required double maxLat,
  required double maxLon,
  required double width,
  required double height,
  required EdgeInsets padding,
}) {
  double mercY(double lat) {
    final s = math.sin(lat * math.pi / 180).clamp(-0.9999, 0.9999);
    return 0.5 - math.log((1 + s) / (1 - s)) / (4 * math.pi);
  }

  final availW = math.max(width - padding.left - padding.right, 64.0);
  final availH = math.max(height - padding.top - padding.bottom, 64.0);
  final dx = math.max((maxLon - minLon) / 360, 1e-9);
  final dy = math.max((mercY(minLat) - mercY(maxLat)).abs(), 1e-9);
  final zoom = math
      .min(math.log(availW / (512 * dx)) / math.ln2,
          math.log(availH / (512 * dy)) / math.ln2)
      .clamp(3.0, 17.0);

  // مركز المستطيل بالبكسل، ثم نزيحه بنصف فرق الهوامش.
  final scale = 512 * math.pow(2, zoom);
  final cx = ((minLon + maxLon) / 2 + 180) / 360 * scale;
  final cy = (mercY(minLat) + mercY(maxLat)) / 2 * scale;
  final px = cx - (padding.left - padding.right) / 2;
  final py = cy + (padding.bottom - padding.top) / 2;
  final lon = px / scale * 360 - 180;
  final n = math.pi - 2 * math.pi * py / scale;
  final lat = 180 / math.pi * math.atan(0.5 * (math.exp(n) - math.exp(-n)));
  return CameraPosition(target: LatLng(lat, lon), zoom: zoom.toDouble());
}

class YmapMapState extends State<YmapMap> {
  final _styles = MapStyleLoader();
  final _location = LocationService();

  MapLibreMapController? _controller;
  String? _style;
  bool _styleError = false;
  bool _locationOn = false;
  bool _is3D = false;
  LatLng? _user; // آخر موقع معروف لك
  LatLng? _placeTarget; // المكان المختار من البحث
  Circle? _placeMarker;

  bool get is3D => _is3D;

  /// آخر موقع معروف لك (null إن لم تسمح بالموقع).
  LatLng? get userLocation => _user;

  /// مركز الخريطة الحالي.
  LatLng get center => _controller?.cameraPosition?.target ?? YmapMap.riyadh;

  /// يعرض مكاناً من البحث: علامة على الخريطة + انتقال إليه.
  Future<void> showPlace(double lat, double lon) async {
    _placeTarget = LatLng(lat, lon);
    await _drawPlaceMarker();
    await _controller?.animateCamera(
      CameraUpdate.newCameraPosition(CameraPosition(
        target: _placeTarget!,
        zoom: 16,
        tilt: _is3D ? 60 : 0,
      )),
    );
  }

  // ===== المسارات =====
  List<RouteResult> _routes = const [];
  int _selectedRoute = 0;
  final _routeLines = <Line, int>{}; // الخط ← رقم المسار

  /// تحديد موقعك (يطلب الإذن عند الحاجة). يرجع null إن لم يتوفر.
  Future<LatLng?> locateUser() async {
    final status = await _location.ensurePermission();
    if (status != LocationStatus.granted) return null;
    if (mounted && !_locationOn) setState(() => _locationOn = true);
    final pos = await _location.current();
    if (pos != null) _user = LatLng(pos.latitude, pos.longitude);
    return _user;
  }

  /// يرسم المسارات: البدائل رمادية والمختار أزرق عريض بحافة بيضاء.
  bool _navStyle = false;
  NavLayers? _nav;
  MeLayer? _me;

  /// يقصّ الخط الأزرق ليبدأ من مكانك (ما قطعته يبقى رمادياً).
  Future<void> updateNavProgress(List<LatLng> remaining) async {
    if (remaining.length < 2) return;
    await _nav?.updateRemaining(remaining);
  }

  /// سهم الالتفاف القادم مرسوماً على الطريق (null = إخفاء).
  Future<void> showTurnArrow(List<LatLng>? pts, double headBearing) async {
    await _nav?.setTurnArrow(pts, headBearing);
  }

  Future<void> showRoutes(List<RouteResult> routes, int selected,
      {EdgeInsets? padding, bool nav = false}) async {
    _navStyle = nav;
    _routes = routes;
    _selectedRoute = selected;
    await _drawRoutes();
    if (padding == null) return; // أثناء الملاحة الكاميرا تتبعك
    final pts = routes[selected].points;
    if (pts.isEmpty) return;
    var minLat = pts.first.lat, maxLat = minLat;
    var minLon = pts.first.lon, maxLon = minLon;
    for (final p in pts) {
      if (p.lat < minLat) minLat = p.lat;
      if (p.lat > maxLat) maxLat = p.lat;
      if (p.lon < minLon) minLon = p.lon;
      if (p.lon > maxLon) maxLon = p.lon;
    }
    // نحسب الإطار بأنفسنا: newLatLngBounds في نسخة الويب يقفز لمكان خاطئ.
    if (!mounted) return;
    final size = context.size ?? MediaQuery.sizeOf(context);
    final camera = fitBounds(
      minLat: minLat,
      minLon: minLon,
      maxLat: maxLat,
      maxLon: maxLon,
      width: size.width,
      height: size.height,
      padding: padding,
    );
    await _controller?.animateCamera(CameraUpdate.newCameraPosition(camera));
    _puckFollow = false;
  }

  // ===== الملاحة: علامة سيارتك وكاميرا تتبعك =====
  LatLng? _puckAt;
  bool _puckFollow = false;

  /// يرسم موقعك أثناء الملاحة (دائرة زرقاء بحافة بيضاء وهالة).
  // ===== التنبيهات (كاميرات/حوادث/زحام) =====
  List<RoadAlert> _alerts = const [];
  final List<Circle> _alertCircles = [];

  Future<void> showAlerts(List<RoadAlert> alerts) async {
    _alerts = alerts;
    await _drawAlerts();
  }

  Future<void> _drawAlerts() async {
    final c = _controller;
    if (c == null) return;
    if (_alertCircles.isNotEmpty) {
      try {
        await c.removeCircles(List.of(_alertCircles));
      } catch (_) {}
      _alertCircles.clear();
    }
    if (_alerts.isEmpty) return;
    final added = await c.addCircles([
      for (final a in _alerts)
        CircleOptions(
          geometry: LatLng(a.lat, a.lon),
          circleRadius: 8,
          circleColor: a.type.color,
          circleStrokeColor: '#FFFFFF',
          circleStrokeWidth: 3,
        ),
    ]);
    _alertCircles.addAll(added);
  }

  // ===== مترو الرياض (بيانات OpenStreetMap) =====
  static const _metroSource = 'ymap-metro-src';
  bool _metroOn = false;
  bool _metroDrawn = false;
  bool get metroOn => _metroOn;

  Future<void> setMetro(bool on) async {
    _metroOn = on;
    await _drawMetro();
  }

  Future<void> _drawMetro() async {
    final c = _controller;
    if (c == null) return;
    if (_metroDrawn) {
      _metroDrawn = false;
      for (final id in ['ymap-metro-stops', 'ymap-metro-names', 'ymap-metro-lines', 'ymap-metro-casing']) {
        try {
          await c.removeLayer(id);
        } catch (_) {}
      }
      try {
        await c.removeSource(_metroSource);
      } catch (_) {}
    }
    if (!_metroOn) return;
    try {
      final data = await rootBundle.loadString('assets/data/riyadh_metro.geojson');
      await c.addGeoJsonSource(_metroSource, jsonDecode(data) as Map<String, dynamic>);
      await c.addLineLayer(
        _metroSource,
        'ymap-metro-casing',
        const LineLayerProperties(
          lineColor: '#FFFFFF',
          lineWidth: 7,
          lineJoin: 'round',
          lineCap: 'round',
        ),
        filter: ['==', ['get', 'kind'], 'line'],
        enableInteraction: false,
      );
      await c.addLineLayer(
        _metroSource,
        'ymap-metro-lines',
        const LineLayerProperties(
          lineColor: ['get', 'color'],
          lineWidth: 4,
          lineJoin: 'round',
          lineCap: 'round',
        ),
        filter: ['==', ['get', 'kind'], 'line'],
        enableInteraction: false,
      );
      await c.addCircleLayer(
        _metroSource,
        'ymap-metro-stops',
        const CircleLayerProperties(
          circleRadius: 4.5,
          circleColor: '#FFFFFF',
          circleStrokeColor: '#1F2A37',
          circleStrokeWidth: 2,
        ),
        filter: ['==', ['get', 'kind'], 'stop'],
        minzoom: 11,
        enableInteraction: false,
      );
      await c.addSymbolLayer(
        _metroSource,
        'ymap-metro-names',
        SymbolLayerProperties(
          textField: ['get', widget.languageCode == 'ar' ? 'name_ar' : 'name_en'],
          textSize: 12,
          textOffset: const [0, 1.3],
          textAnchor: 'top',
          textColor: widget.dark ? '#E6EEF0' : '#1F2A37',
          textHaloColor: widget.dark ? '#0F1A1C' : '#FFFFFF',
          textHaloWidth: 1.5,
          textFont: const ['Noto Sans Regular'],
        ),
        filter: ['all', ['==', ['get', 'kind'], 'stop'], ['has', 'name_ar']],
        minzoom: 13,
        enableInteraction: false,
      );
      _metroDrawn = true;
    } catch (_) {}
  }

  // ===== السيارة أثناء الملاحة (تتحرك بنعومة بين قراءات الـGPS) =====
  double _puckBearing = 0;
  int _puckAnim = 0;

  Future<void> setPuck(double lat, double lon, {double? bearing, bool animate = true}) async {
    final from = _puckAt;
    final fromB = _puckBearing;
    final toB = bearing ?? _puckBearing;
    final gen = ++_puckAnim;
    final far = from == null ||
        (from.latitude - lat).abs() + (from.longitude - lon).abs() > 0.003;
    if (!animate || far) return _placePuck(lat, lon, toB);
    var diff = (toB - fromB) % 360;
    if (diff > 180) diff -= 360;
    if (diff < -180) diff += 360;
    const steps = 12;
    for (var i = 1; i <= steps; i++) {
      if (gen != _puckAnim || !mounted) return;
      final t = i / steps;
      await _placePuck(
        from.latitude + (lat - from.latitude) * t,
        from.longitude + (lon - from.longitude) * t,
        fromB + diff * t,
      );
      if (i < steps) await Future<void>.delayed(const Duration(milliseconds: 70));
    }
  }

  Future<void> _placePuck(double lat, double lon, double bearing) async {
    _puckAt = LatLng(lat, lon);
    _puckBearing = bearing;
    await _nav?.setCar(_puckAt, bearing);
  }

  Future<void> clearPuck() async {
    _puckAt = null;
    ++_puckAnim;
    await _nav?.setCar(null, 0);
  }

  // ===== نقطة موقعك (خارج الملاحة) مع مخروط الاتجاه من البوصلة =====
  StreamSubscription<Position>? _meSub;
  Timer? _compassTimer;
  double? _heading;
  bool _compassFollow = false; // الضغطة الثانية على «موقعي»: الخريطة تدور مع اتجاهك

  void _startMeUpdates() {
    _meSub ??= _location.stream().listen((pos) {
      _user = LatLng(pos.latitude, pos.longitude);
      if (pos.heading > 0 && pos.speed > 1.5 && Compass.heading == null) {
        _heading = pos.heading;
      }
      _drawMe();
    }, onError: (_) {});
    // البوصلة تعمل مباشرة في أندرويد؛ آيفون يحتاج ضغطة منك (زر «موقعي»).
    if (!Compass.needsPermission) unawaited(Compass.start());
    _compassTimer ??= Timer.periodic(const Duration(milliseconds: 250), (_) {
      final h = Compass.heading;
      if (h == null) return;
      final old = _heading;
      if (old != null && ((h - old + 540) % 360 - 180).abs() < 3) return;
      _heading = h;
      _drawMe();
      if (_compassFollow && !widget.navigating && _user != null) {
        _controller?.moveCamera(CameraUpdate.bearingTo(h));
      }
    });
  }

  Future<void> _drawMe() async {
    final me = _me;
    if (me == null) return;
    await me.update(widget.navigating ? null : _user, _heading);
  }

  /// كاميرا القيادة: سيارتك في الثلث السفلي، الخريطة تدور مع الطريق.
  Future<void> followDriving({
    required double lat,
    required double lon,
    required double bearing,
    required double speedMps,
    required bool threeD,
    bool northUp = false,
    bool nearTurn = false,
  }) async {
    if (!mounted) return;
    _puckFollow = true;
    // قريب من الالتفاف: نقرّب كثيراً لتظهر الحارات وسهم الالتفاف بوضوح.
    final zoom = nearTurn
        ? 18.3
        : (speedMps > 22 ? 16.2 : (speedMps > 12 ? 16.9 : 17.6));
    final height = context.size?.height ?? 800;
    // كم متر نتقدم للأمام حتى تظهر السيارة أسفل منتصف الشاشة.
    final metersPerPx =
        156543.03 * math.cos(lat * math.pi / 180) / math.pow(2, zoom) / 2;
    final ahead = northUp ? 0.0 : height * (nearTurn ? 0.08 : (threeD ? 0.15 : 0.2)) * metersPerPx;
    final target = _moveBy(lat, lon, bearing, ahead);
    await _controller?.animateCamera(
      CameraUpdate.newCameraPosition(CameraPosition(
        target: target,
        zoom: zoom,
        tilt: threeD && !northUp ? 60 : 0,
        bearing: northUp ? 0 : bearing,
      )),
      // قريبة من فترة الـGPS (ثانية) لتبدو الحركة متصلة.
      duration: const Duration(milliseconds: 950),
    );
  }

  /// نظرة عامة على المسار كله أثناء الملاحة.
  bool get followingPuck => _puckFollow;

  static LatLng _moveBy(double lat, double lon, double bearingDeg, double meters) {
    const r = 6371008.8;
    final d = meters / r;
    final b = bearingDeg * math.pi / 180;
    final la = lat * math.pi / 180, lo = lon * math.pi / 180;
    final la2 = math.asin(math.sin(la) * math.cos(d) +
        math.cos(la) * math.sin(d) * math.cos(b));
    final lo2 = lo +
        math.atan2(math.sin(b) * math.sin(d) * math.cos(la),
            math.cos(d) - math.sin(la) * math.sin(la2));
    return LatLng(la2 * 180 / math.pi, lo2 * 180 / math.pi);
  }

  Future<void> clearRoutes() async {
    _navStyle = false;
    _routes = const [];
    await _drawRoutes();
  }

  Future<void> _drawRoutes() async {
    final c = _controller;
    if (c == null) return;
    final old = _routeLines.keys.toList();
    _routeLines.clear();
    if (old.isNotEmpty) {
      try {
        await c.removeLines(old);
      } catch (_) {}
    }
    if (_routes.isEmpty) {
      await _nav?.clear();
      return;
    }
    if (_navStyle) {
      // أثناء الملاحة: طبقات خاصة (مسار عريض، أسهم، سهم الالتفاف، السيارة).
      await _nav?.show([for (final p in _routes[_selectedRoute].points) LatLng(p.lat, p.lon)]);
      final puck = _puckAt;
      if (puck != null) await _nav?.setCar(puck, _puckBearing);
      await _drawPlaceMarker();
      return;
    }
    await _nav?.clear();
    final order = [
      for (var i = 0; i < _routes.length; i++)
        if (i != _selectedRoute) i,
      _selectedRoute,
    ];
    for (final i in order) {
      final geometry = [for (final p in _routes[i].points) LatLng(p.lat, p.lon)];
      final main = i == _selectedRoute;
      final casing = await c.addLine(LineOptions(
        geometry: geometry,
        lineColor: '#FFFFFF',
        lineWidth: main ? 12 : 9,
        lineJoin: 'round',
      ));
      final line = await c.addLine(LineOptions(
        geometry: geometry,
        lineColor: main ? '#2F7DF6' : '#97A6BA',
        lineWidth: main ? 8 : 6,
        lineJoin: 'round',
      ));
      _routeLines[casing] = i;
      _routeLines[line] = i;
    }
    // علامة الوجهة فوق المسار.
    await _drawPlaceMarker();
  }

  void _onLineTapped(Line line) {
    final i = _routeLines[line];
    if (i != null && i != _selectedRoute) widget.onRouteTapped?.call(i);
  }

  Future<void> clearPlace() async {
    _placeTarget = null;
    final m = _placeMarker;
    _placeMarker = null;
    if (m != null) await _controller?.removeCircle(m);
  }

  Future<void> _drawPlaceMarker() async {
    final c = _controller;
    final target = _placeTarget;
    if (c == null) return;
    final old = _placeMarker;
    _placeMarker = null;
    if (old != null) {
      try {
        await c.removeCircle(old);
      } catch (_) {}
    }
    if (target == null) return;
    _placeMarker = await c.addCircle(CircleOptions(
      geometry: target,
      circleRadius: 9,
      circleColor: '#0B7A75',
      circleStrokeColor: '#FFFFFF',
      circleStrokeWidth: 3,
    ));
  }

  @override
  void initState() {
    super.initState();
    _loadStyle();
    _startLocation();
  }

  @override
  void didUpdateWidget(YmapMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.languageCode != widget.languageCode ||
        oldWidget.dark != widget.dark) {
      _loadStyle();
    }
  }

  Future<void> _loadStyle() async {
    setState(() => _styleError = false);
    try {
      final style = await _styles.load(
        dark: widget.dark,
        languageCode: widget.languageCode,
      );
      if (!mounted) return;
      final hadStyle = _style != null;
      setState(() => _style = style);
      if (hadStyle) await _controller?.setStyle(style);
    } catch (_) {
      if (mounted) setState(() => _styleError = true);
    }
  }

  final _mapReady = Completer<void>();

  /// عند فتح التطبيق: نطلب صلاحية الموقع، ننتظر جاهزية الخريطة، ثم ننتقل لموقعك.
  Future<void> _startLocation() async {
    final status = await _location.ensurePermission();
    if (!mounted || status != LocationStatus.granted) return;
    setState(() => _locationOn = true);
    final pos = await _location.current();
    if (pos == null || !mounted) return;
    _user = LatLng(pos.latitude, pos.longitude);
    _startMeUpdates();
    await _mapReady.future;
    if (!mounted) return;
    await _drawMe();
    if (_placeTarget != null || widget.navigating) return; // لا ننقل الخريطة إن كنت تشاهد مكاناً
    await _controller?.animateCamera(
      CameraUpdate.newCameraPosition(CameraPosition(target: _user!, zoom: 16)),
    );
  }

  @override
  void dispose() {
    _meSub?.cancel();
    _compassTimer?.cancel();
    super.dispose();
  }

  /// زر «موقعي»: الضغطة الأولى تنقلك لموقعك، والثانية تدير الخريطة مع اتجاهك،
  /// والثالثة ترجعها للشمال.
  Future<void> goToMyLocation() async {
    final t = AppLocalizations.of(context);
    // آيفون: إذن البوصلة يجب أن يُطلب من ضغطة زر.
    unawaited(Compass.start());
    final status = await _location.ensurePermission();
    if (!mounted) return;
    switch (status) {
      case LocationStatus.serviceOff:
        widget.onMessage(t.locationServiceOff);
        return;
      case LocationStatus.denied:
      case LocationStatus.deniedForever:
        widget.onMessage(t.locationDenied);
        return;
      case LocationStatus.granted:
        break;
    }
    setState(() => _locationOn = true);
    _startMeUpdates();
    final pos = await _location.current();
    if (pos != null) _user = LatLng(pos.latitude, pos.longitude);
    final me = _user;
    if (me == null || !mounted) return;
    await _drawMe();
    final cam = _controller?.cameraPosition;
    final centered = cam != null &&
        (cam.target.latitude - me.latitude).abs() < 0.0005 &&
        (cam.target.longitude - me.longitude).abs() < 0.0005;
    if (centered && !_compassFollow && _heading != null) {
      _compassFollow = true;
      await _controller?.animateCamera(CameraUpdate.newCameraPosition(
          CameraPosition(target: me, zoom: 17, tilt: 45, bearing: _heading!)));
      return;
    }
    _compassFollow = false;
    await _controller?.animateCamera(
      CameraUpdate.newCameraPosition(CameraPosition(
        target: me,
        zoom: 16.5,
        tilt: _is3D ? 60 : 0,
      )),
    );
  }

  /// زر «الطبقات» مؤقتاً: تبديل بين منظور 2D ومنظور مائل 3D.
  Future<bool> toggle3D() async {
    setState(() => _is3D = !_is3D);
    await _controller?.animateCamera(CameraUpdate.tiltTo(_is3D ? 60 : 0));
    return _is3D;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final style = _style;

    if (style == null) {
      return ColoredBox(
        color: scheme.surfaceContainerLow,
        child: Center(
          child: _styleError
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.cloud_off, size: 48, color: scheme.error),
                    const SizedBox(height: 8),
                    Text(t.mapLoadError),
                    const SizedBox(height: 8),
                    FilledButton(onPressed: _loadStyle, child: Text(t.retry)),
                  ],
                )
              : const CircularProgressIndicator(),
        ),
      );
    }

    final rtl = Directionality.of(context) == TextDirection.rtl;
    final top = MediaQuery.paddingOf(context).top;
    // البوصلة بعيداً عن أزرارنا ولوحة البحث.
    final compassPosition = widget.isTablet
        ? (rtl ? CompassViewPosition.bottomLeft : CompassViewPosition.bottomRight)
        : (rtl ? CompassViewPosition.topRight : CompassViewPosition.topLeft);
    final compassMargins = widget.isTablet
        ? const Point<num>(24, 32)
        : Point<num>(16, top + 16);

    return MapLibreMap(
      styleString: style,
      // رابط مشاركة: نفتح على المكان مباشرة.
      initialCameraPosition: _placeTarget != null
          ? CameraPosition(target: _placeTarget!, zoom: 16)
          : const CameraPosition(target: YmapMap.riyadh, zoom: 11),
      onMapCreated: (c) {
        _controller = c;
        _nav = NavLayers(c);
        _me = MeLayer(c);
        c.onLineTapped.add(_onLineTapped);
      },
      // تغيير التصميم (ليلي/لغة) يمسح العلامات والمسارات، فنعيد رسمها.
      onStyleLoadedCallback: () async {
        // تصميم جديد = صور وطبقات جديدة.
        _me?.reset();
        await _drawMe();
        _metroDrawn = false;
        await _drawMetro();
        await _drawRoutes();
        await _drawPlaceMarker();
        _alertCircles.clear();
        await _drawAlerts();
        final puck = _puckAt;
        if (puck != null) {
          await setPuck(puck.latitude, puck.longitude, animate: false);
        }
        if (!_mapReady.isCompleted) _mapReady.complete();
      },
      onUserLocationUpdated: (loc) => _user = loc.position,
      trackCameraPosition: true,
      // أثناء الملاحة نخفي نقطة الموقع العادية؛ سهم السيارة يكفي.
      // نقطة الموقع نرسمها بأنفسنا (طبقة «ymap-me») لأنها أوضح وتعمل في آيفون.
      myLocationEnabled: false,
      compassEnabled: !widget.navigating,
      compassViewPosition: compassPosition,
      compassViewMargins: compassMargins,
      logoEnabled: false,
      // النسب لـOpenStreetMap يظهر داخل لوحة البحث.
      attributionEnabled: false,
      minMaxZoomPreference: const MinMaxZoomPreference(3, 20),
    );
  }
}
