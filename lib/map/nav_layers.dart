import 'package:maplibre_gl/maplibre_gl.dart';

import 'map_icons.dart';

/// طبقات الملاحة (تصميم YMAP مستوحى من وظائف تطبيقات الملاحة):
/// - مسار عريض يملأ الحارة عند التقريب (العرض يكبر مع الزوم).
/// - الجزء المقطوع رمادي، والباقي أزرق بأسهم اتجاه.
/// - سهم الالتفاف القادم مرسوم على الطريق نفسه.
/// - السيارة مسطحة على الطريق وتدور مع اتجاهك.
class NavLayers {
  NavLayers(this.c);
  final MapLibreMapController c;

  static const _full = 'ymap-nav-full';
  static const _rem = 'ymap-nav-rem';
  static const _turn = 'ymap-nav-turn';
  static const _turnEnd = 'ymap-nav-turn-end';
  static const _car = 'ymap-nav-car';

  static const _layers = [
    'ymap-nav-full-casing', 'ymap-nav-full-fill',
    'ymap-nav-rem-casing', 'ymap-nav-rem-fill', 'ymap-nav-rem-dir',
    'ymap-nav-turn-casing', 'ymap-nav-turn-fill', 'ymap-nav-turn-head',
    'ymap-nav-car-layer',
  ];
  static const _sources = [_full, _rem, _turn, _turnEnd, _car];

  bool _ready = false;
  bool get ready => _ready;

  /// عرض الخط بالبكسل حسب الزوم (يتضاعف تقريباً كل مستوى مثل الطريق).
  static List<Object> _width(double z12, double z15, double z17, double z18, double z20) => [
        'interpolate', ['exponential', 1.8], ['zoom'],
        12, z12, 15, z15, 17, z17, 18, z18, 20, z20,
      ];

  static Map<String, dynamic> _line(List<LatLng> pts) => {
        'type': 'FeatureCollection',
        'features': [
          if (pts.length >= 2)
            {
              'type': 'Feature',
              'properties': <String, dynamic>{},
              'geometry': {
                'type': 'LineString',
                'coordinates': [
                  for (final p in pts) [p.longitude, p.latitude],
                ],
              },
            },
        ],
      };

  static Map<String, dynamic> _point(LatLng? p, double rot) => {
        'type': 'FeatureCollection',
        'features': [
          if (p != null)
            {
              'type': 'Feature',
              'properties': {'r': rot},
              'geometry': {
                'type': 'Point',
                'coordinates': [p.longitude, p.latitude],
              },
            },
        ],
      };

  Future<void> show(List<LatLng> route) async {
    await clear();
    try {
      await c.addImage(MapIcons.chevron, await MapIcons.chevronPng(), false, 2);
      await c.addImage(MapIcons.turnHead, await MapIcons.turnHeadPng(), false, 2);
      await c.addImage(MapIcons.car, await MapIcons.carPng(), false, 2);

      await c.addGeoJsonSource(_full, _line(route));
      await c.addGeoJsonSource(_rem, _line(route));
      await c.addGeoJsonSource(_turn, _line(const []));
      await c.addGeoJsonSource(_turnEnd, _point(null, 0));
      await c.addGeoJsonSource(_car, _point(null, 0));

      // المقطوع: رمادي
      await c.addLineLayer(_full, 'ymap-nav-full-casing',
          LineLayerProperties(lineColor: '#8D9AAB', lineWidth: _width(6, 12, 30, 56, 190), lineJoin: 'round', lineCap: 'round'),
          enableInteraction: false);
      await c.addLineLayer(_full, 'ymap-nav-full-fill',
          LineLayerProperties(lineColor: '#C7D0DC', lineWidth: _width(4, 9, 24, 46, 160), lineJoin: 'round', lineCap: 'round'),
          enableInteraction: false);
      // الباقي: أزرق
      await c.addLineLayer(_rem, 'ymap-nav-rem-casing',
          LineLayerProperties(lineColor: '#0A4FB0', lineWidth: _width(6, 12, 30, 56, 190), lineJoin: 'round', lineCap: 'round'),
          enableInteraction: false);
      await c.addLineLayer(_rem, 'ymap-nav-rem-fill',
          LineLayerProperties(lineColor: '#2E8BFF', lineWidth: _width(4, 9, 24, 46, 160), lineJoin: 'round', lineCap: 'round'),
          enableInteraction: false);
      await c.addSymbolLayer(_rem, 'ymap-nav-rem-dir',
          SymbolLayerProperties(
            symbolPlacement: 'line',
            symbolSpacing: 90,
            iconImage: MapIcons.chevron,
            iconSize: ['interpolate', ['linear'], ['zoom'], 13, 0.45, 17, 0.8, 19, 1.4],
            iconAllowOverlap: true,
            iconIgnorePlacement: true,
            iconRotationAlignment: 'map',
            iconPitchAlignment: 'map',
          ),
          enableInteraction: false);
      // سهم الالتفاف على الطريق
      await c.addLineLayer(_turn, 'ymap-nav-turn-casing',
          LineLayerProperties(lineColor: '#0A4FB0', lineWidth: _width(4, 8, 20, 38, 130), lineJoin: 'round', lineCap: 'butt'),
          enableInteraction: false);
      await c.addLineLayer(_turn, 'ymap-nav-turn-fill',
          LineLayerProperties(lineColor: '#FFFFFF', lineWidth: _width(2, 5, 12, 24, 84), lineJoin: 'round', lineCap: 'butt'),
          enableInteraction: false);
      await c.addSymbolLayer(_turnEnd, 'ymap-nav-turn-head',
          SymbolLayerProperties(
            iconImage: MapIcons.turnHead,
            iconRotate: ['get', 'r'],
            iconSize: ['interpolate', ['exponential', 1.8], ['zoom'], 14, 0.12, 17, 0.5, 18, 0.95, 20, 3.2],
            iconAllowOverlap: true,
            iconIgnorePlacement: true,
            iconRotationAlignment: 'map',
            iconPitchAlignment: 'map',
          ),
          enableInteraction: false);
      // السيارة
      await c.addSymbolLayer(_car, 'ymap-nav-car-layer',
          SymbolLayerProperties(
            iconImage: MapIcons.car,
            iconRotate: ['get', 'r'],
            iconSize: ['interpolate', ['exponential', 1.6], ['zoom'], 13, 0.45, 16, 0.75, 18, 1.15, 20, 2.2],
            iconAllowOverlap: true,
            iconIgnorePlacement: true,
            iconRotationAlignment: 'map',
            iconPitchAlignment: 'map',
          ),
          enableInteraction: false);
      _ready = true;
    } catch (_) {
      _ready = false;
    }
  }

  Future<void> updateRemaining(List<LatLng> rem) async {
    if (!_ready) return;
    try {
      await c.setGeoJsonSource(_rem, _line(rem));
    } catch (_) {}
  }

  /// سهم الالتفاف: خط من قبل نقطة الالتفاف إلى بعدها + رأس السهم.
  Future<void> setTurnArrow(List<LatLng>? pts, double headBearing) async {
    if (!_ready) return;
    try {
      await c.setGeoJsonSource(_turn, _line(pts ?? const []));
      await c.setGeoJsonSource(
          _turnEnd, _point(pts == null || pts.length < 2 ? null : pts.last, headBearing));
    } catch (_) {}
  }

  Future<void> setCar(LatLng? at, double bearing) async {
    if (!_ready) return;
    try {
      await c.setGeoJsonSource(_car, _point(at, bearing));
    } catch (_) {}
  }

  Future<void> clear() async {
    _ready = false;
    for (final l in _layers) {
      try {
        await c.removeLayer(l);
      } catch (_) {}
    }
    for (final s in _sources) {
      try {
        await c.removeSource(s);
      } catch (_) {}
    }
  }
}

/// نقطة موقعك خارج الملاحة: دائرة زرقاء + هالة + مخروط الاتجاه.
class MeLayer {
  MeLayer(this.c);
  final MapLibreMapController c;
  static const _src = 'ymap-me';
  bool _ready = false;

  static Map<String, dynamic> _data(LatLng? p, double? heading) => {
        'type': 'FeatureCollection',
        'features': [
          if (p != null)
            {
              'type': 'Feature',
              'properties': {
                'h': heading ?? 0,
                'hasH': heading != null,
              },
              'geometry': {
                'type': 'Point',
                'coordinates': [p.longitude, p.latitude],
              },
            },
        ],
      };

  Future<void> ensure() async {
    if (_ready) return;
    try {
      await c.addImage(MapIcons.cone, await MapIcons.conePng(), false, 2);
      await c.addGeoJsonSource(_src, _data(null, null));
      await c.addSymbolLayer(_src, 'ymap-me-cone',
          const SymbolLayerProperties(
            iconImage: MapIcons.cone,
            iconRotate: ['get', 'h'],
            iconSize: 0.9,
            iconAllowOverlap: true,
            iconIgnorePlacement: true,
            iconRotationAlignment: 'map',
            iconPitchAlignment: 'map',
          ),
          filter: ['==', ['get', 'hasH'], true],
          enableInteraction: false);
      await c.addCircleLayer(_src, 'ymap-me-halo',
          const CircleLayerProperties(circleRadius: 20, circleColor: '#1F8FFF', circleOpacity: 0.16),
          enableInteraction: false);
      await c.addCircleLayer(_src, 'ymap-me-dot',
          const CircleLayerProperties(
            circleRadius: 8,
            circleColor: '#1F8FFF',
            circleStrokeColor: '#FFFFFF',
            circleStrokeWidth: 3,
          ),
          enableInteraction: false);
      _ready = true;
    } catch (_) {}
  }

  Future<void> update(LatLng? p, double? heading) async {
    await ensure();
    if (!_ready) return;
    try {
      await c.setGeoJsonSource(_src, _data(p, heading));
    } catch (_) {}
  }

  void reset() => _ready = false;
}
