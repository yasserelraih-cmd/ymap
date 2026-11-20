import 'dart:math' show Point;

import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:material_ui/material_ui.dart';

import '../l10n/app_localizations.dart';
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
  });

  final String languageCode;
  final bool dark;
  final bool isTablet;
  final void Function(String message) onMessage;

  /// وسط الرياض.
  static const riyadh = LatLng(24.7136, 46.6753);

  @override
  State<YmapMap> createState() => YmapMapState();
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
      initialCameraPosition:
          const CameraPosition(target: YmapMap.riyadh, zoom: 11),
      onMapCreated: (c) => _controller = c,
      // تغيير التصميم (ليلي/لغة) يمسح العلامات، فنعيد رسمها.
      onStyleLoadedCallback: _drawPlaceMarker,
      onUserLocationUpdated: (loc) => _user = loc.position,
      trackCameraPosition: true,
      myLocationEnabled: _locationOn,
      myLocationTrackingMode: _tracking,
      myLocationRenderMode: _locationOn
          ? MyLocationRenderMode.compass
          : MyLocationRenderMode.normal,
      onCameraTrackingDismissed: () =>
          setState(() => _tracking = MyLocationTrackingMode.none),
      compassEnabled: true,
      compassViewPosition: compassPosition,
      compassViewMargins: compassMargins,
      logoEnabled: false,
      // النسب لـOpenStreetMap يظهر داخل لوحة البحث.
      attributionEnabled: false,
      minMaxZoomPreference: const MinMaxZoomPreference(3, 20),
    );
  }
}
