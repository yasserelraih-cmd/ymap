import 'dart:async';

import 'package:material_ui/material_ui.dart';
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
import '../search/place.dart';
import '../search/recent_searches.dart';
import '../search/search_service.dart';
import '../state/settings_controller.dart';
import '../widgets/place_card.dart';
import '../widgets/route_card.dart';
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
  bool _nav3D = true;

  bool get _navigating => _navRoute != null;

  Future<void> _startNavigation({required bool simulate}) async {
    final routes = _routes;
    if (routes == null || routes.isEmpty || _place == null) return;
    final t = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final route = routes[_selectedRoute];
    // أول جملة تُقال داخل ضغطة الزر: المتصفح (خصوصاً Safari) يسمح بالصوت بعدها.
    await _speaker.setLanguage(lang);
    unawaited(_speaker.say(
        '${t.navStartSpeech} ${Instructions.text(route.maneuvers.first, lang)}'));
    try {
      await WakelockPlus.enable(); // الشاشة لا تنطفئ أثناء القيادة
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _navRoute = route;
      _navState = null;
      _navSpeed = 0;
      _navOverview = false;
      _rerouting = false;
    });
    await _mapKey.currentState?.showRoutes([route], 0);
    _track(route, simulate: simulate, lang: lang);
  }

  void _track(RouteResult route, {required bool simulate, required String lang}) {
    _engine = NavigationEngine(route);
    _voice = VoiceGuide(route, lang: lang);
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
    final speed = fix.speedMps ?? _navSpeed;
    setState(() {
      _navState = s;
      _navSpeed = speed;
    });
    final lat = s.offRoute ? fix.lat : s.snappedLat;
    final lon = s.offRoute ? fix.lon : s.snappedLon;
    final map = _mapKey.currentState;
    await map?.setPuck(lat, lon);
    if (!_navOverview) {
      await map?.followDriving(
        lat: lat,
        lon: lon,
        bearing: s.offRoute ? (fix.headingDeg ?? s.bearing) : s.bearing,
        speedMps: speed,
        threeD: _nav3D,
      );
    }
    final say = _voice?.next(s, speedMps: speed);
    if (say != null) unawaited(_speaker.say(say));
    if (s.offRoute && !_rerouting && !(_source?.isSimulation ?? true)) {
      unawaited(_reroute(fix));
    }
    if (s.arrived) {
      unawaited(_fixSub?.cancel());
      try {
        await WakelockPlus.disable();
      } catch (_) {}
    }
  }

  Future<void> _reroute(NavFix fix) async {
    final place = _place;
    if (place == null) return;
    final t = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    setState(() => _rerouting = true);
    unawaited(_speaker.say(t.navRerouteSpeech));
    try {
      final routes = await _routing.route(
        fromLat: fix.lat,
        fromLon: fix.lon,
        toLat: place.lat,
        toLon: place.lon,
      );
      if (!mounted || !_navigating) return;
      final route = routes.first;
      setState(() {
        _routes = routes;
        _selectedRoute = 0;
        _navRoute = route;
      });
      _engine = NavigationEngine(route);
      _voice = VoiceGuide(route, lang: lang);
      await _mapKey.currentState?.showRoutes([route], 0);
    } catch (_) {
      // نحاول مرة أخرى مع القراءة التالية خارج المسار.
    } finally {
      if (mounted) setState(() => _rerouting = false);
    }
  }

  Future<void> _toggleOverview() async {
    final route = _navRoute;
    if (route == null) return;
    setState(() => _navOverview = !_navOverview);
    final top = MediaQuery.paddingOf(context).top;
    if (_navOverview) {
      await _mapKey.currentState?.showRoutes([route], 0,
          padding: EdgeInsets.fromLTRB(48, top + 150, 48, 130));
    } else if (_navState != null) {
      final s = _navState!;
      await _mapKey.currentState?.followDriving(
        lat: s.snappedLat,
        lon: s.snappedLon,
        bearing: s.bearing,
        speedMps: _navSpeed,
        threeD: _nav3D,
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

  Future<void> _openSearch() async {
    final map = _mapKey.currentState;
    final near = map?.userLocation ?? map?.center;
    final place = await Navigator.of(context).push<Place>(
      MaterialPageRoute(
        builder: (_) => SearchScreen(
          service: _search,
          recent: _recent,
          nearLat: near?.latitude ?? YmapMap.riyadh.latitude,
          nearLon: near?.longitude ?? YmapMap.riyadh.longitude,
        ),
      ),
    );
    if (place == null || !mounted) return;
    setState(() => _place = place);
    await _mapKey.currentState?.showPlace(place.lat, place.lon);
  }

  Future<void> _closePlace() async {
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
        scrollController: scrollController,
      );
    }
    return SearchPanel(
      onOpenSettings: () => showSettingsSheet(context, widget.settings),
      onOpenSearch: _openSearch,
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
      dark: Theme.of(context).brightness == Brightness.dark,
      isTablet: isTablet,
      onMessage: _showMessage,
      onRouteTapped: _selectRoute,
      navigating: _navigating,
    );
  }

  Future<void> _toggle3D() async {
    final is3D = await _mapKey.currentState?.toggle3D();
    if (is3D != null && mounted) setState(() => _is3D = is3D);
  }

  @override
  Widget build(BuildContext context) {
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
  });

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
