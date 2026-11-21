import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:maplibre_gl/maplibre_gl.dart' show LatLng;
import 'package:share_plus/share_plus.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../l10n/app_localizations.dart';
import '../map/ymap_map.dart';
import '../navigation/navigation_engine.dart';
import '../navigation/navigation_view.dart';
import '../navigation/position_source.dart';
import '../navigation/speaker.dart';
import '../navigation/voice_guide.dart';
import '../routing/instructions.dart';
import '../routing/route.dart';
import '../routing/routing_service.dart';
import '../alerts/alert_watcher.dart';
import '../alerts/osm_cameras.dart';
import '../alerts/road_alert.dart';
import '../routing/speed_limits.dart';
import '../contrib/contributions.dart';
import '../saved/saved_places.dart';
import '../navigation/geo.dart';
import '../search/categories.dart';
import '../search/location_link.dart';
import '../search/place.dart';
import '../voice/speech_input.dart';
import '../voice/voice_command.dart';
import '../prayer/prayer_times.dart';
import '../widgets/prayer_sheet.dart';
import '../search/recent_searches.dart';
import '../search/search_service.dart';
import '../state/settings_controller.dart';
import '../widgets/place_card.dart';
import '../widgets/route_card.dart';
import '../widgets/contrib_dialogs.dart';
import '../widgets/saved_sheet.dart';
import '../widgets/search_panel.dart';
import '../widgets/settings_sheet.dart';
import 'search_screen.dart';

/// يبني طبقة الخريطة. في الاختبارات نمرر بديلاً لا يحتاج إنترنت.
typedef MapBuilder = Widget Function(
  BuildContext context,
  GlobalKey<YmapMapState> key,
  bool isTablet,
  void Function(String message) onMessage,
);

/// الشاشة الرئيسية. تتكيف مع حجم الشاشة:
/// - الجوال: الخريطة بكامل الشاشة + بطاقة سفلية قابلة للسحب.
/// - التابلت والآيباد (عرض 700 فأكثر): لوحة جانبية بجانب الخريطة.
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.settings,
    this.mapBuilder,
    this.searchService,
    this.routingService,
  });

  final SettingsController settings;
  final MapBuilder? mapBuilder;
  final SearchService? searchService;
  final RoutingService? routingService;

  static const tabletBreakpoint = 700.0;
  static const sidePanelWidth = 380.0;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _mapKey = GlobalKey<YmapMapState>();
  final _recent = RecentSearches();
  late final SearchService _search =
      widget.searchService ?? PhotonSearchService();
  late final RoutingService _routing =
      widget.routingService ?? ValhallaRoutingService();
  bool _is3D = false;
  Place? _place; // المكان المختار من البحث
  List<RouteResult>? _routes; // null = لسنا في وضع المسار
  int _selectedRoute = 0;
  bool _routeLoading = false;

  EdgeInsets _routePadding() {
    final size = MediaQuery.sizeOf(context);
    final top = MediaQuery.paddingOf(context).top;
    if (size.width >= HomeScreen.tabletBreakpoint) {
      final side = HomeScreen.sidePanelWidth + 48;
      final rtl = Directionality.of(context) == TextDirection.rtl;
      return EdgeInsets.fromLTRB(rtl ? 48 : side, top + 48, rtl ? side : 48, 48);
    }
    return EdgeInsets.fromLTRB(40, top + 72, 40, size.height * 0.5);
  }

  /// محطة على الطريق (مثل بنزينة أضفتها بالصوت أثناء الملاحة).
  List<GeoPoint> _via = const [];

  @override
  void initState() {
    super.initState();
    // فتح رابط YMAP مُشارك: ?p=lat,lon&n=الاسم
    if (kIsWeb) {
      final shared = LocationLink.parse(Uri.base.toString());
      if (shared != null && Uri.base.queryParameters.containsKey('p')) {
        _place = shared;
        WidgetsBinding.instance.addPostFrameCallback(
            (_) => _mapKey.currentState?.showPlace(shared.lat, shared.lon));
      }
    }
  }

  // ===== المشاركة =====
  Future<void> _sharePlace(Place place) async {
    final t = AppLocalizations.of(context);
    final link = LocationLink.ymap(place.lat, place.lon, name: place.name);
    await _share('${place.name}\n$link\n${t.openInGoogle}: '
        '${LocationLink.googleMaps(place.lat, place.lon)}');
  }

  Future<void> _shareTrip() async {
    final t = AppLocalizations.of(context);
    final s = _navState;
    final place = _place;
    if (s == null || place == null) return;
    final eta = TimeOfDay.fromDateTime(
            DateTime.now().add(Duration(seconds: s.remainingSec.round())))
        .format(context);
    final here = LocationLink.ymap(s.snappedLat, s.snappedLon, name: t.myLocation);
    await _share(t.shareTripText(place.name, eta, '$here'));
  }

  Future<void> _share(String text) async {
    try {
      await SharePlus.instance.share(ShareParams(text: text));
    } catch (_) {
      // متصفح لا يدعم المشاركة: ننسخ النص.
      await Clipboard.setData(ClipboardData(text: text));
      if (mounted) _showMessage(AppLocalizations.of(context).copied);
    }
  }

  // ===== أوقات الصلاة =====
  String? _prayerLabel() {
    final map = _mapKey.currentState;
    final at = map?.userLocation ?? map?.center;
    if (at == null) return null;
    final t = AppLocalizations.of(context);
    final (p, time) = nextPrayer(at.latitude, at.longitude, DateTime.now());
    return '${prayerName(t, p)} ${TimeOfDay.fromDateTime(time).format(context)}';
  }

  Future<void> _openPrayer() async {
    final map = _mapKey.currentState;
    final at = map?.userLocation ?? map?.center ?? YmapMap.riyadh;
    final wantMosque = await showPrayerSheet(context, at.latitude, at.longitude);
    if (wantMosque == true && mounted) {
      await _goNearest(PlaceCategory.mosque, at.latitude, at.longitude, navigate: false);
    }
  }

  // ===== الأوامر الصوتية =====
  Future<void> _voiceCommand() async {
    final lang = Localizations.localeOf(context).languageCode;
    final text = await listenOnce(context, lang: lang);
    if (text == null || text.trim().isEmpty || !mounted) return;
    final cmd = VoiceCommand.parse(text);
    final map = _mapKey.currentState;
    final here = map?.userLocation ?? map?.center ?? YmapMap.riyadh;

    // أثناء الملاحة: «أقرب بنزينة على طريقي» → نضيفها محطة.
    if (_navigating && cmd.category != null) {
      await _addStopAlongRoute(cmd.category!);
      return;
    }
    if (cmd.category != null && (cmd.nearest || cmd.navigate || cmd.query.split(' ').length == 1)) {
      await _goNearest(cmd.category!, here.latitude, here.longitude, navigate: cmd.navigate);
      return;
    }
    if (cmd.query.isEmpty) return;
    final place = await _pickPlace(initialQuery: cmd.query);
    if (place == null || !mounted) return;
    await _selectPlace(place);
    if (cmd.navigate) await _startRouting();
  }

  Future<void> _goNearest(PlaceCategory c, double lat, double lon,
      {required bool navigate}) async {
    final t = AppLocalizations.of(context);
    try {
      final list = await _search.nearby(c, nearLat: lat, nearLon: lon);
      if (!mounted) return;
      if (list.isEmpty) {
        _showMessage(t.noResults);
        return;
      }
      await _selectPlace(list.first);
      if (navigate) await _startRouting();
    } catch (_) {
      if (mounted) _showMessage(t.searchError);
    }
  }

  /// يبحث حول نقطة أمامك على المسار (~2 كم) ويختار الأقرب للمسار.
  Future<void> _addStopAlongRoute(PlaceCategory c) async {
    final t = AppLocalizations.of(context);
    final route = _navRoute;
    final s = _navState;
    if (route == null || s == null) return;
    final ahead = pointAlong(route.points, s.progressM + 2000);
    try {
      final list = await _search.nearby(c, nearLat: ahead.lat, nearLon: ahead.lon);
      if (!mounted || list.isEmpty) {
        if (mounted) _showMessage(t.noResults);
        return;
      }
      double offRoute(Place p) {
        var best = double.infinity;
        for (var i = 0; i < route.points.length; i += 3) {
          final d = distanceMeters(p.lat, p.lon, route.points[i].lat, route.points[i].lon);
          if (d < best) best = d;
        }
        return best;
      }
      final stop = (list.toList()..sort((a, b) => offRoute(a).compareTo(offRoute(b)))).first;
      _via = [GeoPoint(stop.lat, stop.lon)];
      unawaited(_speaker.say(t.stopAddedSpeech(stop.name)));
      _showMessage(t.stopAdded(stop.name));
      await _reroute(NavFix(lat: s.snappedLat, lon: s.snappedLon));
    } catch (_) {
      if (mounted) _showMessage(t.searchError);
    }
  }

  /// «ابدأ» من بطاقة المكان: نحسب المسار ثم ندخل شاشة الملاحة فوراً.
  Future<void> _goNow() async {
    await _startRouting();
    if (!mounted || (_routes?.isEmpty ?? true)) return;
    await _startNavigation(simulate: false);
  }

  Future<void> _startRouting() async {
    final place = _place;
    if (place == null) return;
    final t = AppLocalizations.of(context);
    setState(() {
      _routes = const [];
      _routeLoading = true;
      _selectedRoute = 0;
    });
    final from = await _mapKey.currentState?.locateUser();
    if (!mounted) return;
    if (from == null) {
      setState(() => _routes = null);
      _showMessage(t.needLocation);
      return;
    }
    try {
      final routes = await _routing.route(
        fromLat: from.latitude,
        fromLon: from.longitude,
        toLat: place.lat,
        toLon: place.lon,
        mode: _mode,
        via: _via,
      );
      if (!mounted || _routes == null) return;
      setState(() {
        _routes = routes;
        _routeLoading = false;
      });
      await _mapKey.currentState
          ?.showRoutes(routes, 0, padding: _routePadding());
    } catch (_) {
      if (!mounted) return;
      setState(() => _routes = null);
      _showMessage(t.routeError);
    }
  }

  Future<void> _selectRoute(int i) async {
    final routes = _routes;
    if (routes == null || i >= routes.length) return;
    setState(() => _selectedRoute = i);
    await _mapKey.currentState?.showRoutes(routes, i, padding: _routePadding());
  }

  // ===== الملاحة =====
  final _speaker = Speaker();
  NavigationEngine? _engine;
  VoiceGuide? _voice;
  PositionSource? _source;
  StreamSubscription<NavFix>? _fixSub;
  RouteResult? _navRoute;
  NavState? _navState;
  double _navSpeed = 0;
  bool _navOverview = false;
  bool _rerouting = false;
  NavViewMode _navView = NavViewMode.threeD;
  VoiceDialect get _dialect => VoiceDialect.fromCode(widget.settings.voiceDialect);

  // ===== التنبيهات وحدود السرعة =====
  final _alertStore = AlertStore();
  final _cameras = OsmCameraService();
  final _limitsService = SpeedLimitService();
  AlertWatcher? _watcher;
  SpeedLimits _limits = SpeedLimits.empty;
  UpcomingAlert? _upcoming;
  int? _limitNow;
  int? _overSpeedWarnedFor;

  // ===== تسجيل المسار (بموافقتك) =====
  final _contrib = Contributions();
  List<TrackPoint>? _trackPts;

  Future<void> _finishTrack() async {
    final pts = _trackPts;
    _trackPts = null;
    if (pts != null && pts.length > 2) await _contrib.saveTrack(pts);
  }

  Future<void> _reportMapIssue(double lat, double lon) async {
    final t = AppLocalizations.of(context);
    final note = await askMapIssue(context);
    if (note == null || !mounted) return;
    await _contrib.addIssue(
        MapIssue(lat: lat, lon: lon, note: note, createdAt: DateTime.now()));
    _showMessage(t.mapIssueThanks);
  }
  TravelMode _mode = TravelMode.drive;

  bool get _navigating => _navRoute != null;

  /// ليل أثناء القيادة: الخريطة تصير داكنة تلقائياً بعد المغرب وقبل الشروق
  /// (إلا إذا اخترت «فاتح» صراحة من الإعدادات).
  bool _navNight = false;

  bool _isNightAt(double lat, double lon) {
    if (widget.settings.themeMode == ThemeMode.light) return false;
    final now = DateTime.now();
    final day = PrayerCalculator.compute(date: now, lat: lat, lon: lon);
    return now.isBefore(day.times[Prayer.sunrise]!) ||
        now.isAfter(day.times[Prayer.maghrib]!);
  }

  Future<void> _startNavigation({required bool simulate}) async {
    final routes = _routes;
    if (routes == null || routes.isEmpty || _place == null) return;
    final t = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final route = routes[_selectedRoute];
    if (!simulate) {
      var consent = await _contrib.consent();
      if (consent == null && mounted) {
        consent = await askTrackConsent(context);
        await _contrib.setConsent(consent);
      }
      _trackPts = consent == true ? <TrackPoint>[] : null;
      if (!mounted) return;
    }
    // أول جملة تُقال داخل ضغطة الزر: المتصفح (خصوصاً Safari) يسمح بالصوت بعدها.
    await _speaker.setLanguage(lang);
    unawaited(_speaker.say(
        '${lang == 'ar' ? _dialect.start : t.navStartSpeech} ${Instructions.spoken(route.maneuvers.first, lang, _dialect)}'));
    try {
      await WakelockPlus.enable(); // الشاشة لا تنطفئ أثناء القيادة
    } catch (_) {}
    if (!mounted) return;
    final start = route.points.first;
    setState(() {
      _navNight = _isNightAt(start.lat, start.lon);
      _navRoute = route;
      _navState = null;
      _navSpeed = 0;
      _navOverview = false;
      _rerouting = false;
    });
    // نبدأ التتبع أولاً؛ رسم المسار قد ينتظر تحميل التصميم الليلي.
    _track(route, simulate: simulate, lang: lang);
    unawaited(_mapKey.currentState?.showRoutes([route], 0, nav: true));
    unawaited(_loadRoadData(route));
  }

  /// نحمّل بلاغاتك وكاميرات OSM وحدود السرعة مرة واحدة عند بدء الملاحة،
  /// ثم تعمل التنبيهات بدون إنترنت.
  Future<void> _loadRoadData(RouteResult route) async {
    final mine = await _alertStore.load();
    _watcher = AlertWatcher(_visibleAlerts(mine));
    unawaited(_mapKey.currentState?.showAlerts(_watcher!.alerts));
    if (_mode == TravelMode.drive) {
      unawaited(_limitsService.forRoute(route).then((l) {
        if (identical(_navRoute, route)) _limits = l;
      }));
    }
    final osm = await _cameras.alongRoute(route);
    if (!mounted || !identical(_navRoute, route) || osm.isEmpty) return;
    _watcher!.alerts = _visibleAlerts([...mine, ...osm]);
    unawaited(_mapKey.currentState?.showAlerts(_watcher!.alerts));
  }

  List<RoadAlert> _visibleAlerts(List<RoadAlert> all) => widget.settings.cameraAlerts
      ? all
      : all.where((a) => a.type != AlertType.camera).toList();

  Future<void> _report() async {
    final s = _navState;
    if (s == null) return;
    final t = AppLocalizations.of(context);
    final type = await showModalBottomSheet<AlertType>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(t.reportTitle, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  for (final (type, label) in [
                    (AlertType.camera, t.alertCamera),
                    (AlertType.accident, t.alertAccident),
                    (AlertType.traffic, t.alertTraffic),
                    (AlertType.hazard, t.alertHazard),
                  ])
                    SizedBox(
                      width: 140,
                      height: 72,
                      child: FilledButton.tonalIcon(
                        onPressed: () => Navigator.of(context).pop(type),
                        icon: Icon(alertIcon(type)),
                        label: Text(label),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (type == null || !mounted) return;
    final alert = await _alertStore.add(type, s.snappedLat, s.snappedLon);
    final w = _watcher;
    if (w != null) {
      w.alerts = [...w.alerts, alert];
      unawaited(_mapKey.currentState?.showAlerts(w.alerts));
    }
    _showMessage(t.reportThanks);
  }

  String _alertName(AppLocalizations t, AlertType type) => switch (type) {
        AlertType.camera => t.speedCameraSpeech,
        AlertType.accident => t.alertAccident,
        AlertType.traffic => t.alertTraffic,
        AlertType.hazard => t.alertHazard,
      };

  void _track(RouteResult route, {required bool simulate, required String lang}) {
    _engine = NavigationEngine(route);
    _voice = VoiceGuide(route, lang: lang, dialect: _dialect);
    _fixSub?.cancel();
    _source?.dispose();
    final source = simulate ? SimulatedPositionSource(route) : GpsPositionSource();
    _source = source;
    _fixSub = source.fixes.listen(_onFix);
  }

  Future<void> _onFix(NavFix fix) async {
    final engine = _engine;
    final route = _navRoute;
    if (engine == null || route == null || !mounted) return;
    final s = engine.update(fix);
    final via = _via;
    if (via.isNotEmpty &&
        distanceMeters(fix.lat, fix.lon, via.first.lat, via.first.lon) < 60) {
      _via = const []; // وصلت للمحطة
    }
    _trackPts?.add(TrackPoint(fix.lat, fix.lon, DateTime.now(), speedMps: fix.speedMps));
    final speed = fix.speedMps ?? _navSpeed;
    setState(() {
      _navState = s;
      _navSpeed = speed;
    });
    final lat = s.offRoute ? fix.lat : s.snappedLat;
    final lon = s.offRoute ? fix.lon : s.snappedLon;
    final map = _mapKey.currentState;
    unawaited(map?.setPuck(lat, lon,
        bearing: s.offRoute ? (fix.headingDeg ?? s.bearing) : s.bearing));
    if (!s.offRoute) {
      unawaited(map?.updateNavProgress([
        // نبدأ الأزرق من حيث يبدأ السهم حركته (قبل ثانية) ليتطابقا.
        for (final p in remainingFrom(route.points, (s.progressM - speed * 0.9).clamp(0, double.infinity)))
          LatLng(p.lat, p.lon),
      ]));
    }
    _updateTurnArrow(route, s);
    if (!_navOverview) {
      await map?.followDriving(
        lat: lat,
        lon: lon,
        bearing: s.offRoute ? (fix.headingDeg ?? s.bearing) : s.bearing,
        speedMps: speed,
        threeD: _navView == NavViewMode.threeD,
        northUp: _navView == NavViewMode.northUp,
        nearTurn: _nearTurn(s),
      );
    }
    final say = _voice?.next(s, speedMps: speed);
    if (say != null) unawaited(_speaker.say(say));
    _checkAlertsAndSpeed(s, lat, lon, speed);
    if (s.offRoute && !_rerouting && !(_source?.isSimulation ?? true)) {
      unawaited(_reroute(fix));
    }
    if (s.arrived) {
      if (!(_source?.isSimulation ?? true)) {
        // عند الوصول نحفظ مكان سيارتك تلقائياً (مثل «آخر موقع ركنت فيه»).
        unawaited(_saved.saveCar(fix.lat, fix.lon));
      }
      unawaited(_fixSub?.cancel());
      unawaited(_finishTrack());
      try {
        await WakelockPlus.disable();
      } catch (_) {}
    }
  }

  void _checkAlertsAndSpeed(NavState s, double lat, double lon, double speed) {
    final t = AppLocalizations.of(context);
    final heading = s.bearing;
    final w = _watcher;
    UpcomingAlert? upcoming;
    if (w != null) {
      upcoming = w.nearestAhead(lat, lon, heading, speedMps: speed);
      final announce = w.toAnnounce(lat, lon, heading, speedMps: speed);
      if (announce != null && _voice != null) {
        unawaited(_speaker.say(t.alertSpeech(
            _voice!.distancePhrase(announce.distanceM),
            _alertName(t, announce.alert.type))));
      }
    }
    final limit = _limits.at(s.progressM);
    if (limit != null && speed * 3.6 > limit + 5) {
      if (_overSpeedWarnedFor != limit) {
        _overSpeedWarnedFor = limit;
        unawaited(_speaker.say(t.overSpeedSpeech));
      }
    } else if (limit == null || speed * 3.6 < limit) {
      _overSpeedWarnedFor = null;
    }
    if (upcoming?.alert.id != _upcoming?.alert.id ||
        (upcoming != null && _upcoming != null &&
            (upcoming.distanceM - _upcoming!.distanceM).abs() > 10) ||
        limit != _limitNow) {
      setState(() {
        _upcoming = upcoming;
        _limitNow = limit;
      });
    }
  }

  Future<void> _reroute(NavFix fix) async {
    final place = _place;
    if (place == null) return;
    final t = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    setState(() => _rerouting = true);
    unawaited(_speaker.say(Localizations.localeOf(context).languageCode == 'ar'
        ? _dialect.reroute
        : t.navRerouteSpeech));
    try {
      final routes = await _routing.route(
        fromLat: fix.lat,
        fromLon: fix.lon,
        toLat: place.lat,
        toLon: place.lon,
        mode: _mode,
        via: _via,
      );
      if (!mounted || !_navigating) return;
      final route = routes.first;
      setState(() {
        _routes = routes;
        _selectedRoute = 0;
        _navRoute = route;
      });
      _engine = NavigationEngine(route);
      _voice = VoiceGuide(route, lang: lang, dialect: _dialect);
      _turnShownFor = -1;
      _limits = SpeedLimits.empty;
      if (_mode == TravelMode.drive) {
        unawaited(_limitsService.forRoute(route).then((l) {
          if (identical(_navRoute, route)) _limits = l;
        }));
      }
      await _mapKey.currentState?.showRoutes([route], 0, nav: true);
    } catch (_) {
      // نحاول مرة أخرى مع القراءة التالية خارج المسار.
    } finally {
      if (mounted) setState(() => _rerouting = false);
    }
  }

  /// قرب الوجهة: نوجهك لأقرب موقف سيارات لها.
  Future<void> _parkingNearDestination() async {
    final dest = _place;
    if (dest == null) return;
    final t = AppLocalizations.of(context);
    try {
      final list = await _search.nearby(PlaceCategory.parking,
          nearLat: dest.lat, nearLon: dest.lon);
      if (!mounted) return;
      if (list.isEmpty) {
        _showMessage(t.noParking);
        return;
      }
      final p = list.first;
      await _endNavigation();
      if (!mounted) return;
      await _selectPlace(p);
      _showMessage(t.parkingFound(p.name));
      await _goNow();
    } catch (_) {
      if (mounted) _showMessage(t.searchError);
    }
  }

  /// قريب من التفافة حقيقية (ليست «استمر» ولا الوصول).
  bool _nearTurn(NavState s) {
    final route = _navRoute;
    if (route == null || s.offRoute) return false;
    if (s.nextManeuver >= route.maneuvers.length) return false;
    final type = route.maneuvers[s.nextManeuver].type;
    const notTurns = {1, 2, 3, 4, 5, 6, 8, 22};
    return !notTurns.contains(type) && s.distanceToManeuverM < 180;
  }

  int _turnShownFor = -1;

  /// سهم الالتفاف مرسوم على الطريق: من قبل الالتفاف بـ 40م إلى بعده بـ 30م.
  void _updateTurnArrow(RouteResult route, NavState s) {
    final map = _mapKey.currentState;
    if (map == null) return;
    final show = !s.offRoute &&
        s.nextManeuver < route.maneuvers.length &&
        s.distanceToManeuverM < 400 &&
        !const {1, 2, 3, 4, 5, 6, 8, 22}.contains(route.maneuvers[s.nextManeuver].type);
    if (!show) {
      if (_turnShownFor != -1) {
        _turnShownFor = -1;
        unawaited(map.showTurnArrow(null, 0));
      }
      return;
    }
    if (_turnShownFor == s.nextManeuver) return;
    _turnShownFor = s.nextManeuver;
    final at = s.progressM + s.distanceToManeuverM;
    final pts = sliceBetween(route.points, at - 40, at + 30);
    if (pts.length < 2) return;
    final a = pts[pts.length - 2], b = pts.last;
    unawaited(map.showTurnArrow(
      [for (final p in pts) LatLng(p.lat, p.lon)],
      bearingDegrees(a.lat, a.lon, b.lat, b.lon),
    ));
  }

  Future<void> _cycleNavView() async {
    setState(() => _navView =
        NavViewMode.values[(_navView.index + 1) % NavViewMode.values.length]);
    final s = _navState;
    if (s == null || _navOverview) return;
    await _mapKey.currentState?.followDriving(
      lat: s.snappedLat,
      lon: s.snappedLon,
      bearing: s.bearing,
      speedMps: _navSpeed,
      threeD: _navView == NavViewMode.threeD,
      northUp: _navView == NavViewMode.northUp,
      nearTurn: _nearTurn(s),
    );
  }

  Future<void> _toggleOverview() async {
    final route = _navRoute;
    if (route == null) return;
    setState(() => _navOverview = !_navOverview);
    final top = MediaQuery.paddingOf(context).top;
    if (_navOverview) {
      await _mapKey.currentState?.showRoutes([route], 0,
          nav: true, padding: EdgeInsets.fromLTRB(48, top + 150, 48, 150));
    } else if (_navState != null) {
      final s = _navState!;
      await _mapKey.currentState?.followDriving(
        lat: s.snappedLat,
        lon: s.snappedLon,
        bearing: s.bearing,
        speedMps: _navSpeed,
        threeD: _navView == NavViewMode.threeD,
        northUp: _navView == NavViewMode.northUp,
      );
    }
  }

  Future<void> _endNavigation() async {
    await _fixSub?.cancel();
    _fixSub = null;
    _source?.dispose();
    _source = null;
    _engine = null;
    _voice = null;
    unawaited(_finishTrack());
    _via = const [];
    _turnShownFor = -1;
    _watcher = null;
    _limits = SpeedLimits.empty;
    _upcoming = null;
    _limitNow = null;
    _overSpeedWarnedFor = null;
    await _speaker.stop();
    try {
      await WakelockPlus.disable();
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _navRoute = null;
      _navState = null;
    });
    final map = _mapKey.currentState;
    await map?.clearPuck();
    await map?.showAlerts(const []);
    final routes = _routes;
    if (routes != null && routes.isNotEmpty) {
      await map?.showRoutes(routes, _selectedRoute, padding: _routePadding());
    }
  }

  @override
  void dispose() {
    _fixSub?.cancel();
    _source?.dispose();
    _speaker.stop();
    super.dispose();
  }

  Future<void> _closeRoutes() async {
    setState(() {
      _routes = null;
      _routeLoading = false;
    });
    await _mapKey.currentState?.clearRoutes();
  }

  final _saved = SavedPlaces()..load();

  Future<Place?> _pickPlace({String? hint, String? initialQuery}) {
    final map = _mapKey.currentState;
    final near = map?.userLocation ?? map?.center;
    return Navigator.of(context).push<Place>(
      MaterialPageRoute(
        builder: (_) => SearchScreen(
          service: _search,
          recent: _recent,
          nearLat: near?.latitude ?? YmapMap.riyadh.latitude,
          nearLon: near?.longitude ?? YmapMap.riyadh.longitude,
          hint: hint,
          initialQuery: initialQuery,
        ),
      ),
    );
  }

  Future<void> _openSearch() async {
    final place = await _pickPlace();
    if (place != null && mounted) await _selectPlace(place);
  }

  Future<void> _selectPlace(Place place) async {
    if (_routes != null) await _closeRoutes();
    if (!mounted) return;
    setState(() => _place = place);
    await _mapKey.currentState?.showPlace(place.lat, place.lon);
  }

  /// البيت/العمل: إن كان محفوظاً نعرضه، وإلا نطلب اختياره من البحث.
  Future<void> _openHomeOrWork({required bool home}) async {
    final t = AppLocalizations.of(context);
    final current = home ? _saved.home : _saved.work;
    if (current != null) return _selectPlace(current);
    final picked = await _pickPlace(hint: home ? t.pickHome : t.pickWork);
    if (picked == null || !mounted) return;
    if (home) {
      await _saved.setHome(picked);
    } else {
      await _saved.setWork(picked);
    }
    _showMessage(home ? t.homeSaved : t.workSaved);
    await _selectPlace(picked);
  }

  Future<void> _openSaved() async {
    final place = await showSavedSheet(context, _saved);
    if (place != null && mounted) await _selectPlace(place);
  }

  Future<void> _saveCarHere() async {
    final t = AppLocalizations.of(context);
    final here = await _mapKey.currentState?.locateUser();
    if (!mounted) return;
    if (here == null) {
      _showMessage(t.needLocation);
      return;
    }
    await _saved.saveCar(here.latitude, here.longitude);
    _showMessage(t.carSaved);
  }

  Future<void> _openCar() async {
    final car = _saved.car;
    if (car == null) return;
    final t = AppLocalizations.of(context);
    await _selectPlace(Place(
      name: t.myCar,
      subtitle: t.carSavedAt(TimeOfDay.fromDateTime(car.savedAt).format(context)),
      lat: car.lat,
      lon: car.lon,
      osmKey: 'car',
    ));
  }

  Future<void> _closePlace() async {
    _via = const [];
    setState(() {
      _place = null;
      _routes = null;
    });
    await _mapKey.currentState?.clearRoutes();
    await _mapKey.currentState?.clearPlace();
  }

  Widget _panel({ScrollController? scrollController}) {
    final place = _place;
    final routes = _routes;
    if (place != null && routes != null) {
      return RouteCard(
        destination: place,
        routes: routes,
        selected: _selectedRoute,
        loading: _routeLoading,
        onSelect: _selectRoute,
        onClose: _closeRoutes,
        onStart: () => _startNavigation(simulate: false),
        onPreview: () => _startNavigation(simulate: true),
        mode: _mode,
        onModeChanged: (m) {
          if (m == _mode) return;
          setState(() => _mode = m);
          _startRouting();
        },
        scrollController: scrollController,
      );
    }
    if (place != null) {
      final user = _mapKey.currentState?.userLocation;
      return PlaceCard(
        key: ValueKey(place.key),
        place: place,
        fromLat: user?.latitude,
        fromLon: user?.longitude,
        onClose: _closePlace,
        onMessage: _showMessage,
        onDirections: _startRouting,
        onGo: _goNow,
        isFavorite: _saved.isFavorite(place),
        onToggleFavorite:
            place.osmKey == 'car' ? null : () => _saved.toggleFavorite(place),
        onSetHome: place.osmKey == 'car'
            ? null
            : () async {
                final t = AppLocalizations.of(context);
                await _saved.setHome(place);
                _showMessage(t.homeSaved);
              },
        onReportIssue: () => _reportMapIssue(place.lat, place.lon),
        onShare: () => _sharePlace(place),
        onSetWork: place.osmKey == 'car'
            ? null
            : () async {
                final t = AppLocalizations.of(context);
                await _saved.setWork(place);
                _showMessage(t.workSaved);
              },
        scrollController: scrollController,
      );
    }
    return SearchPanel(
      onOpenSettings: () => showSettingsSheet(context, widget.settings),
      onOpenSearch: _openSearch,
      onHome: () => _openHomeOrWork(home: true),
      onWork: () => _openHomeOrWork(home: false),
      onSaved: _openSaved,
      onNearby: _openSearch,
      onSaveCar: _saveCarHere,
      onCar: _saved.car == null ? null : _openCar,
      onVoice: _voiceCommand,
      onPrayer: _openPrayer,
      prayerLabel: _prayerLabel(),
      homeSet: _saved.home != null,
      workSet: _saved.work != null,
      scrollController: scrollController,
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildMap(BuildContext context, bool isTablet) {
    final custom = widget.mapBuilder;
    if (custom != null) return custom(context, _mapKey, isTablet, _showMessage);
    return YmapMap(
      key: _mapKey,
      languageCode: Localizations.localeOf(context).languageCode,
      dark: Theme.of(context).brightness == Brightness.dark || (_navigating && _navNight),
      isTablet: isTablet,
      onMessage: _showMessage,
      onRouteTapped: _selectRoute,
      navigating: _navigating,
    );
  }

  bool _metroOn = false;
  Future<void> _toggleMetro() async {
    setState(() => _metroOn = !_metroOn);
    await _mapKey.currentState?.setMetro(_metroOn);
    if (_metroOn && mounted) _showMessage(AppLocalizations.of(context).metroShown);
  }

  Future<void> _toggle3D() async {
    final is3D = await _mapKey.currentState?.toggle3D();
    if (is3D != null && mounted) setState(() => _is3D = is3D);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _saved,
      builder: (context, _) => _scaffold(context),
    );
  }

  Widget _scaffold(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isTablet = constraints.maxWidth >= HomeScreen.tabletBreakpoint;
          final navRoute = _navRoute;
          if (navRoute != null) {
            return Stack(
              children: [
                Positioned.fill(child: _buildMap(context, isTablet)),
                Positioned.fill(
                  child: NavigationView(
                    route: navRoute,
                    state: _navState,
                    speedMps: _navSpeed,
                    muted: _speaker.muted,
                    overview: _navOverview,
                    simulation: _source?.isSimulation ?? false,
                    rerouting: _rerouting,
                    onToggleMute: () =>
                        setState(() => _speaker.muted = !_speaker.muted),
                    onToggleOverview: _toggleOverview,
                    onEnd: _endNavigation,
                    viewMode: _navView,
                    onCycleView: _cycleNavView,
                    onReport: _mode == TravelMode.drive ? _report : null,
                    onShare: _shareTrip,
                    onParking: _mode == TravelMode.drive ? _parkingNearDestination : null,
                    onVoice: _voiceCommand,
                    speedLimitKmh: _limitNow,
                    upcomingAlert: _upcoming?.alert.type,
                    upcomingAlertM: _upcoming?.distanceM,
                  ),
                ),
              ],
            );
          }
          return Stack(
            children: [
              Positioned.fill(child: _buildMap(context, isTablet)),
              PositionedDirectional(
                end: 16,
                top: MediaQuery.paddingOf(context).top + 16,
                child: MapControls(
                  is3D: _is3D,
                  onToggle3D: _toggle3D,
                  onMyLocation: () => _mapKey.currentState?.goToMyLocation(),
                  metroOn: _metroOn,
                  onToggleMetro: _toggleMetro,
                ),
              ),
              if (isTablet)
                PositionedDirectional(
                  start: 16,
                  top: MediaQuery.paddingOf(context).top + 16,
                  bottom: 16,
                  width: HomeScreen.sidePanelWidth,
                  child: Card(
                    elevation: 3,
                    clipBehavior: Clip.antiAlias,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: _panel(),
                    ),
                  ),
                )
              else
                DraggableScrollableSheet(
                  // بطاقة المكان تفتح أطول لتظهر كل أزرارها.
                  key: ValueKey(
                      '${_place?.key ?? 'search'}|${_routes == null ? 'place' : 'route'}'),
                  initialChildSize:
                      _place == null ? 0.22 : (_routes == null ? 0.36 : 0.42),
                  minChildSize: 0.12,
                  maxChildSize: 0.85,
                  builder: (context, scrollController) => Material(
                    elevation: 8,
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(24)),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        const _DragHandle(),
                        Expanded(
                          child: _panel(scrollController: scrollController),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// مكان بديل للخريطة (يُستخدم في الاختبارات).
class MapPlaceholder extends StatelessWidget {
  const MapPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ColoredBox(
      color: scheme.surfaceContainerLow,
      child: Center(
        child: Icon(Icons.map_outlined, size: 72, color: scheme.primary),
      ),
    );
  }
}

/// أزرار الخريطة الجانبية (منظور 2D/3D، موقعي).
class MapControls extends StatelessWidget {
  const MapControls({
    super.key,
    required this.is3D,
    required this.onToggle3D,
    required this.onMyLocation,
    this.metroOn = false,
    this.onToggleMetro,
  });

  final bool metroOn;
  final VoidCallback? onToggleMetro;
  final bool is3D;
  final VoidCallback onToggle3D;
  final VoidCallback onMyLocation;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Column(
      children: [
        IconButton.filledTonal(
          tooltip: is3D ? t.view2d : t.view3d,
          onPressed: onToggle3D,
          icon: Icon(is3D ? Icons.map_outlined : Icons.view_in_ar_outlined),
        ),
        if (onToggleMetro != null) ...[
          const SizedBox(height: 8),
          metroOn
              ? IconButton.filled(
                  tooltip: t.metro,
                  onPressed: onToggleMetro,
                  icon: const Icon(Icons.subway),
                )
              : IconButton.filledTonal(
                  tooltip: t.metro,
                  onPressed: onToggleMetro,
                  icon: const Icon(Icons.subway_outlined),
                ),
        ],
        const SizedBox(height: 8),
        IconButton.filledTonal(
          tooltip: t.myLocation,
          onPressed: onMyLocation,
          icon: const Icon(Icons.my_location),
        ),
      ],
    );
  }
}

class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.outlineVariant,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}
