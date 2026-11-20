import 'package:material_ui/material_ui.dart';

import '../alerts/road_alert.dart';
import '../l10n/app_localizations.dart';
import '../routing/instructions.dart';
import '../routing/route.dart';
import '../widgets/route_card.dart';
import 'navigation_engine.dart';

/// ألوان شاشة القيادة (هوية YMAP، بإلهام من تجربة AMap).
class NavColors {
  static const banner = Color(0xFF141B2D);
  static const bannerText = Colors.white;
  static const accent = Color(0xFF2F7DF6);
}

/// واجهة القيادة فوق الخريطة: الشريط العلوي، فقاعة السرعة، الأزرار، البطاقة السفلية.
/// طريقة عرض الخريطة أثناء الملاحة.
enum NavViewMode { threeD, headingUp, northUp }

class NavigationView extends StatelessWidget {
  const NavigationView({
    super.key,
    required this.route,
    required this.state,
    required this.speedMps,
    required this.muted,
    required this.overview,
    required this.simulation,
    required this.rerouting,
    required this.onToggleMute,
    required this.onToggleOverview,
    required this.onEnd,
    this.viewMode = NavViewMode.threeD,
    this.speedLimitKmh,
    this.upcomingAlert,
    this.upcomingAlertM,
    this.onCycleView,
    this.onReport,
  });

  final NavViewMode viewMode;

  /// حد السرعة للطريق الحالي (إن كان معروفاً).
  final int? speedLimitKmh;

  /// أقرب تنبيه أمامك (نوعه ومسافته).
  final AlertType? upcomingAlert;
  final double? upcomingAlertM;
  final VoidCallback? onCycleView;

  /// زر الإبلاغ (كاميرا/حادث/زحام) — يُفعّل في الخطوة 1.7.
  final VoidCallback? onReport;

  final RouteResult route;
  final NavState? state;
  final double speedMps;
  final bool muted;
  final bool overview;
  final bool simulation;
  final bool rerouting;
  final VoidCallback onToggleMute;
  final VoidCallback onToggleOverview;
  final VoidCallback onEnd;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final top = MediaQuery.paddingOf(context).top;
    final s = state;
    return Stack(
      children: [
        // الشريط العلوي.
        PositionedDirectional(
          start: 12,
          end: 12,
          top: top + 8,
          child: _Banner(
            route: route,
            state: s,
            lang: lang,
            rerouting: rerouting,
          ),
        ),
        // فقاعة السرعة.
        PositionedDirectional(
          start: 16,
          top: top + 136,
          child: Column(
            children: [
              _SpeedBubble(
                speedKmh: speedMps * 3.6,
                unit: t.navKmh,
                over: speedLimitKmh != null &&
                    speedMps * 3.6 > speedLimitKmh! + 5,
              ),
              if (speedLimitKmh != null) ...[
                const SizedBox(height: 8),
                _LimitSign(limit: speedLimitKmh!),
              ],
              if (upcomingAlert != null && upcomingAlertM != null) ...[
                const SizedBox(height: 8),
                _AlertChip(type: upcomingAlert!, meters: upcomingAlertM!),
              ],
            ],
          ),
        ),
        // أزرار جانبية.
        PositionedDirectional(
          end: 16,
          top: top + 136,
          child: Column(
            children: [
              _RoundButton(
                tooltip: muted ? t.navUnmute : t.navMute,
                icon: muted ? Icons.volume_off : Icons.volume_up,
                onTap: onToggleMute,
              ),
              const SizedBox(height: 10),
              _RoundButton(
                tooltip: overview ? t.navRecenter : t.navOverview,
                icon: overview ? Icons.navigation : Icons.alt_route,
                onTap: onToggleOverview,
              ),
              if (onCycleView != null) ...[
                const SizedBox(height: 10),
                _RoundButton(
                  tooltip: switch (viewMode) {
                    NavViewMode.threeD => t.navView3D,
                    NavViewMode.headingUp => t.navViewHeading,
                    NavViewMode.northUp => t.navViewNorth,
                  },
                  icon: switch (viewMode) {
                    NavViewMode.threeD => Icons.view_in_ar,
                    NavViewMode.headingUp => Icons.explore,
                    NavViewMode.northUp => Icons.north,
                  },
                  onTap: onCycleView!,
                ),
              ],
              if (onReport != null) ...[
                const SizedBox(height: 10),
                _RoundButton(
                  tooltip: t.report,
                  icon: Icons.campaign,
                  onTap: onReport!,
                ),
              ],
            ],
          ),
        ),
        if (simulation)
          PositionedDirectional(
            start: 0,
            end: 0,
            top: top + 136,
            child: Center(
              child: Chip(
                avatar: const Icon(Icons.play_circle_outline, size: 18),
                label: Text(t.navPreviewBadge),
              ),
            ),
          ),
        // البطاقة السفلية.
        PositionedDirectional(
          start: 12,
          end: 12,
          bottom: MediaQuery.paddingOf(context).bottom + 12,
          child: _BottomCard(
            state: s,
            route: route,
            onEnd: onEnd,
            onToggleOverview: onToggleOverview,
          ),
        ),
      ],
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.route,
    required this.state,
    required this.lang,
    required this.rerouting,
  });

  final RouteResult route;
  final NavState? state;
  final String lang;
  final bool rerouting;

  static String distanceText(double m, String lang) {
    final ar = lang == 'ar';
    if (m >= 1000) {
      return '${(m / 1000).toStringAsFixed(m >= 10000 ? 0 : 1)} ${ar ? 'كم' : 'km'}';
    }
    final r = m >= 100 ? (m / 10).round() * 10 : m.round();
    return '$r ${ar ? 'م' : 'm'}';
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final s = state;
    final text = Theme.of(context).textTheme;
    if (rerouting || s == null) {
      return _shell(
        child: Row(
          children: [
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
            ),
            const SizedBox(width: 16),
            Text(rerouting ? t.navRerouting : t.calculatingRoute,
                style: text.titleLarge?.copyWith(color: NavColors.bannerText)),
          ],
        ),
      );
    }
    if (s.arrived) {
      return _shell(
        child: Row(
          children: [
            const Icon(Icons.flag, color: Colors.white, size: 44),
            const SizedBox(width: 16),
            Text(t.navArrived,
                style: text.headlineSmall?.copyWith(
                    color: NavColors.bannerText, fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }
    final m = route.maneuvers[s.nextManeuver];
    final street = Instructions.street(m, lang);
    final dist = distanceText(s.distanceToManeuverM, lang);
    final parts = dist.split(' ');
    // «ثم»: التعليمة التي تليها إن كانت قريبة (أقل من 300 م بعدها).
    final nextIdx = s.nextManeuver + 1;
    final then = nextIdx < route.maneuvers.length &&
            route.maneuvers[s.nextManeuver].lengthKm < 0.3
        ? route.maneuvers[nextIdx]
        : null;

    return _shell(
      child: Row(
        children: [
          Icon(Instructions.icon(m), color: Colors.white, size: 56),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text.rich(
                  TextSpan(children: [
                    TextSpan(
                      text: parts.first,
                      style: text.displaySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        height: 1.0,
                      ),
                    ),
                    TextSpan(
                      text: ' ${parts.length > 1 ? parts[1] : ''}',
                      style: text.titleLarge?.copyWith(color: Colors.white70),
                    ),
                  ]),
                ),
                const SizedBox(height: 4),
                Text(
                  street ?? Instructions.text(m, lang),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.titleMedium?.copyWith(color: Colors.white),
                ),
              ],
            ),
          ),
          if (then != null) ...[
            const SizedBox(width: 8),
            Text(t.navThen, style: text.titleSmall?.copyWith(color: Colors.white70)),
            const SizedBox(width: 4),
            Icon(Instructions.icon(then), color: Colors.white70, size: 28),
          ],
        ],
      ),
    );
  }

  Widget _shell({required Widget child}) => Container(
        padding: const EdgeInsetsDirectional.fromSTEB(16, 14, 16, 14),
        decoration: BoxDecoration(
          color: NavColors.banner,
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [BoxShadow(blurRadius: 12, color: Colors.black26)],
        ),
        child: child,
      );
}

/// إشارة حد السرعة (دائرة حمراء).
class _LimitSign extends StatelessWidget {
  const _LimitSign({required this.limit});
  final int limit;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFE5484D), width: 5),
        boxShadow: const [BoxShadow(blurRadius: 6, color: Colors.black26)],
      ),
      child: Text(
        '$limit',
        style: const TextStyle(
            fontWeight: FontWeight.bold, fontSize: 17, color: Colors.black),
      ),
    );
  }
}

/// تنبيه قادم: كاميرا / حادث / زحام / خطر.
class _AlertChip extends StatelessWidget {
  const _AlertChip({required this.type, required this.meters});
  final AlertType type;
  final double meters;

  @override
  Widget build(BuildContext context) {
    final color = Color(int.parse('FF${type.color.substring(1)}', radix: 16));
    return Container(
      width: 76,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [BoxShadow(blurRadius: 6, color: Colors.black26)],
      ),
      child: Column(
        children: [
          Icon(alertIcon(type), color: Colors.white),
          Text(
            '${(meters / 10).round() * 10} ${AppLocalizations.of(context).metersShort}',
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

IconData alertIcon(AlertType t) => switch (t) {
      AlertType.camera => Icons.photo_camera,
      AlertType.accident => Icons.car_crash,
      AlertType.traffic => Icons.traffic,
      AlertType.hazard => Icons.warning_amber,
    };

class _SpeedBubble extends StatelessWidget {
  const _SpeedBubble(
      {required this.speedKmh, required this.unit, this.over = false});
  final double speedKmh;
  final String unit;
  final bool over;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        color: over ? const Color(0xFFE5484D) : Colors.white,
        shape: BoxShape.circle,
        boxShadow: const [BoxShadow(blurRadius: 10, color: Colors.black26)],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            speedKmh.round().toString(),
            style: text.headlineSmall?.copyWith(
              color: over ? Colors.white : NavColors.accent,
              fontWeight: FontWeight.bold,
              height: 1.0,
            ),
          ),
          Text(unit,
              style: text.labelSmall
                  ?.copyWith(color: over ? Colors.white : NavColors.accent)),
        ],
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.tooltip, required this.icon, required this.onTap});
  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 4,
      child: IconButton(
        tooltip: tooltip,
        iconSize: 26,
        color: NavColors.banner,
        onPressed: onTap,
        icon: Icon(icon),
      ),
    );
  }
}

class _BottomCard extends StatelessWidget {
  const _BottomCard({
    required this.state,
    required this.route,
    required this.onEnd,
    required this.onToggleOverview,
  });

  final NavState? state;
  final RouteResult route;
  final VoidCallback onEnd;
  final VoidCallback onToggleOverview;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final lang = Localizations.localeOf(context).languageCode;
    final remainingSec = state?.remainingSec ?? route.durationSec;
    final remainingM = state?.remainingM ?? route.distanceKm * 1000;
    final duration = Duration(seconds: remainingSec.round());
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(28),
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Row(
          children: [
            IconButton(
              tooltip: t.navEnd,
              iconSize: 30,
              onPressed: onEnd,
              icon: const Icon(Icons.close),
            ),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    t.navRemaining(
                      RouteCard.formatDuration(t, duration),
                      _Banner.distanceText(remainingM, lang),
                    ),
                    style: text.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    t.arriveAt(RouteCard.formatArrival(context, duration)),
                    style: text.titleSmall,
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: t.navOverview,
              iconSize: 30,
              onPressed: onToggleOverview,
              icon: const Icon(Icons.alt_route),
            ),
          ],
        ),
      ),
    );
  }
}
