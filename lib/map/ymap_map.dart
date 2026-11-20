import 'dart:math' as math;
import 'dart:math' show Point;

import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:material_ui/material_ui.dart';

import '../alerts/road_alert.dart';
import '../l10n/app_localizations.dart';
import '../routing/route.dart';
import 'location_service.dart';
import 'map_style.dart';

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
  MyLocationTrackingMode _tracking = MyLocationTrackingMode.none;
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
    _tracking = MyLocationTrackingMode.none;
    await _controller?.updateMyLocationTrackingMode(MyLocationTrackingMode.none);
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
  Future<void> showRoutes(List<RouteResult> routes, int selected,
      {EdgeInsets? padding}) async {
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
    _tracking = MyLocationTrackingMode.none;
    await _controller?.updateMyLocationTrackingMode(MyLocationTrackingMode.none);
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
  Circle? _puckHalo;
  Circle? _puckDot;
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

  Future<void> setPuck(double lat, double lon) async {
    final c = _controller;
    if (c == null) return;
    _puckAt = LatLng(lat, lon);
    if (_puckDot == null) {
      _puckHalo = await c.addCircle(CircleOptions(
        geometry: _puckAt,
        circleRadius: 22,
        circleColor: '#2F7DF6',
        circleOpacity: 0.18,
      ));
      _puckDot = await c.addCircle(CircleOptions(
        geometry: _puckAt,
        circleRadius: 9,
        circleColor: '#2F7DF6',
        circleStrokeColor: '#FFFFFF',
        circleStrokeWidth: 4,
      ));
    } else {
      await c.updateCircle(_puckHalo!, CircleOptions(geometry: _puckAt));
      await c.updateCircle(_puckDot!, CircleOptions(geometry: _puckAt));
    }
  }

  Future<void> clearPuck() async {
    final c = _controller;
    final ids = [?_puckHalo, ?_puckDot];
    _puckHalo = null;
    _puckDot = null;
    _puckAt = null;
    if (c != null && ids.isNotEmpty) {
      try {
        await c.removeCircles(ids);
      } catch (_) {}
    }
  }

  /// كاميرا القيادة: سيارتك في الثلث السفلي، الخريطة تدور مع الطريق.
  Future<void> followDriving({
    required double lat,
    required double lon,
    required double bearing,
    required double speedMps,
    required bool threeD,
    bool northUp = false,
  }) async {
    if (!mounted) return;
    _puckFollow = true;
    final zoom = speedMps > 22 ? 15.6 : (speedMps > 12 ? 16.3 : 17.0);
    final height = context.size?.height ?? 800;
    // كم متر نتقدم للأمام حتى تظهر السيارة أسفل منتصف الشاشة.
    final metersPerPx =
        156543.03 * math.cos(lat * math.pi / 180) / math.pow(2, zoom) / 2;
    final ahead = northUp ? 0.0 : height * (threeD ? 0.16 : 0.22) * metersPerPx;
    final target = _moveBy(lat, lon, bearing, ahead);
    await _controller?.animateCamera(
      CameraUpdate.newCameraPosition(CameraPosition(
        target: target,
        zoom: zoom,
        tilt: threeD && !northUp ? 60 : 0,
        bearing: northUp ? 0 : bearing,
      )),
      duration: const Duration(milliseconds: 600),
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
    if (_routes.isEmpty) return;
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

  /// عند فتح التطبيق: نطلب صلاحية الموقع وننتقل لموقعك إن سمحت.
  Future<void> _startLocation() async {
    final status = await _location.ensurePermission();
    if (!mounted || status != LocationStatus.granted) return;
    setState(() => _locationOn = true);
    final pos = await _location.current();
    if (pos == null || !mounted) return;
    _user = LatLng(pos.latitude, pos.longitude);
    if (_placeTarget != null) return; // لا ننقل الخريطة إن كنت تشاهد مكاناً
    await _controller?.animateCamera(
      CameraUpdate.newLatLngZoom(LatLng(pos.latitude, pos.longitude), 15),
    );
  }

  /// زر «موقعي»: الضغطة الأولى تتبعك، والثانية تدير الخريطة مع اتجاهك.
  Future<void> goToMyLocation() async {
    final t = AppLocalizations.of(context);
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
    final next = _tracking == MyLocationTrackingMode.tracking
        ? MyLocationTrackingMode.trackingCompass
        : MyLocationTrackingMode.tracking;
    setState(() {
      _locationOn = true;
      _tracking = next;
    });
    final pos = await _location.current();
    if (pos != null) _user = LatLng(pos.latitude, pos.longitude);
    if (pos != null && mounted) {
      await _controller?.animateCamera(
        CameraUpdate.newCameraPosition(CameraPosition(
          target: LatLng(pos.latitude, pos.longitude),
          zoom: 16,
          tilt: _is3D ? 60 : 0,
        )),
      );
    }
    await _controller?.updateMyLocationTrackingMode(next);
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
        c.onLineTapped.add(_onLineTapped);
      },
      // تغيير التصميم (ليلي/لغة) يمسح العلامات والمسارات، فنعيد رسمها.
      onStyleLoadedCallback: () async {
        await _drawRoutes();
        await _drawPlaceMarker();
        _alertCircles.clear();
        await _drawAlerts();
        final puck = _puckAt;
        if (puck != null) {
          _puckHalo = null;
          _puckDot = null;
          await setPuck(puck.latitude, puck.longitude);
        }
      },
      onUserLocationUpdated: (loc) => _user = loc.position,
      trackCameraPosition: true,
      myLocationEnabled: _locationOn,
      myLocationTrackingMode: _tracking,
      myLocationRenderMode: _locationOn
          ? MyLocationRenderMode.compass
          : MyLocationRenderMode.normal,
      onCameraTrackingDismissed: () =>
          setState(() => _tracking = MyLocationTrackingMode.none),
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
