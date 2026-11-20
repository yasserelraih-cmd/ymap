import 'package:material_ui/material_ui.dart';

import '../l10n/app_localizations.dart';
import '../map/ymap_map.dart';
import '../state/settings_controller.dart';
import '../widgets/search_panel.dart';
import '../widgets/settings_sheet.dart';

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
  const HomeScreen({super.key, required this.settings, this.mapBuilder});

  final SettingsController settings;
  final MapBuilder? mapBuilder;

  static const tabletBreakpoint = 700.0;
  static const sidePanelWidth = 380.0;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _mapKey = GlobalKey<YmapMapState>();
  bool _is3D = false;

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
    );
  }

  Future<void> _toggle3D() async {
    final is3D = await _mapKey.currentState?.toggle3D();
    if (is3D != null && mounted) setState(() => _is3D = is3D);
  }

  @override
  Widget build(BuildContext context) {
    void openSettings() => showSettingsSheet(context, widget.settings);

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isTablet = constraints.maxWidth >= HomeScreen.tabletBreakpoint;
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
                      child: SearchPanel(onOpenSettings: openSettings),
                    ),
                  ),
                )
              else
                DraggableScrollableSheet(
                  initialChildSize: 0.22,
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
                          child: SearchPanel(
                            onOpenSettings: openSettings,
                            scrollController: scrollController,
                          ),
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
