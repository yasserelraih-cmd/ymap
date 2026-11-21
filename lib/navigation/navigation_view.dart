import 'package:material_ui/material_ui.dart';

import '../alerts/road_alert.dart';
import '../l10n/app_localizations.dart';
import '../routing/instructions.dart';
import '../routing/route.dart';
import '../widgets/route_card.dart';
import 'navigation_engine.dart';

/// ألوان شاشة القيادة (هوية YMAP، بإلهام من تجربة AMap).
class NavColors {
  static const banner = Color(0xFF14202B);
  static const bannerEnd = Color(0xFF0B5A56);
  static const bannerText = Colors.white;
  static const accent = Color(0xFF0B7A75);
  static const route = Color(0xFF1F8FFF);
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
    this.onShare,
    this.onVoice,
    this.onParking,
  });

  /// «مواقف قريبة» عند الاقتراب من الوجهة.
  final VoidCallback? onParking;

  /// مشاركة الرحلة ووقت الوصول.
  final VoidCallback? onShare;

  /// أمر صوتي («أقرب بنزينة على طريقي»).
  final VoidCallback? onVoice;

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
    final lang = Localizations.localeOf(context).languageCode;
    final pad = MediaQuery.paddingOf(context);
    final s = state;
    final t = AppLocalizations.of(context);
    return Stack(
      children: [
        // الشريط العلوي: الالتفافة القادمة + «ثم».
        PositionedDirectional(
          start: 10,
          end: 10,
          top: pad.top + 6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _Banner(route: route, state: s, lang: lang, rerouting: rerouting),
              if (upcomingAlert != null && upcomingAlertM != null)
                Padding(
                  padding: const EdgeInsetsDirectional.only(top: 8, start: 4),
                  child: _AlertChip(type: upcomingAlert!, meters: upcomingAlertM!),
                ),
              if (onParking != null &&
                  s != null &&
                  !s.arrived &&
                  s.remainingM < 800)
                Padding(
                  padding: const EdgeInsetsDirectional.only(top: 8, start: 4),
                  child: ActionChip(
                    avatar: const Icon(Icons.local_parking, size: 18),
                    label: Text(t.nearbyParking),
                    onPressed: onParking,
                  ),
                ),
              if (simulation)
                Padding(
                  padding: const EdgeInsetsDirectional.only(top: 8, start: 4),
                  child: Chip(
                    visualDensity: VisualDensity.compact,
                    avatar: const Icon(Icons.play_circle_outline, size: 18),
                    label: Text(t.navPreviewBadge),
                  ),
                ),
            ],
          ),
        ),
        // زر الصوت (وزر الرجوع للمتابعة عند النظرة العامة).
        PositionedDirectional(
          start: 12,
          bottom: pad.bottom + 108,
          child: Column(
            children: [
              _RoundButton(
                tooltip: muted ? t.navUnmute : t.navMute,
                icon: muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                onTap: onToggleMute,
              ),
              if (overview) ...[
                const SizedBox(height: 10),
                _RoundButton(
                  tooltip: t.navRecenter,
                  icon: Icons.navigation_rounded,
                  onTap: onToggleOverview,
                ),
              ],
            ],
          ),
        ),
        // شريط تقدم الرحلة عمودياً على الحافة (السيارة تصعد نحو الوجهة).
        PositionedDirectional(
          end: 6,
          top: pad.top + 120,
          bottom: pad.bottom + 110,
          child: _TripBar(
            progress: (() {
              final total = route.distanceKm * 1000;
              final rem = s?.remainingM ?? total;
              return total <= 0 ? 0.0 : (1 - rem / total).clamp(0.0, 1.0);
            })(),
          ),
        ),
        // السرعة وحدّها تحت الشريط العلوي.
        PositionedDirectional(
          start: 12,
          top: pad.top + 112,
          child: Column(
            children: [
              _SpeedBubble(
                speedKmh: speedMps * 3.6,
                unit: t.navKmh,
                over: speedLimitKmh != null && speedMps * 3.6 > speedLimitKmh! + 5,
              ),
              if (speedLimitKmh != null) ...[
                const SizedBox(height: 8),
                _LimitSign(limit: speedLimitKmh!),
              ],
            ],
          ),
        ),
        // البطاقة السفلية.
        PositionedDirectional(
          start: 10,
          end: 10,
          bottom: pad.bottom + 10,
          child: _BottomCard(
            state: s,
            route: route,
            onEnd: onEnd,
            onMore: () => _showMore(context),
          ),
        ),
      ],
    );
  }

  /// بقية الأدوات في قائمة واحدة بدل أزرار كثيرة فوق الخريطة.
  void _showMore(BuildContext context) {
    final t = AppLocalizations.of(context);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheet) {
        Widget item(IconData icon, String label, VoidCallback? onTap) => onTap == null
            ? const SizedBox.shrink()
            : SizedBox(
                width: 100,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    Navigator.of(sheet).pop();
                    onTap();
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: NavColors.accent.withValues(alpha: 0.12),
                          child: Icon(icon, color: NavColors.accent),
                        ),
                        const SizedBox(height: 6),
                        Text(label, textAlign: TextAlign.center, maxLines: 2),
                      ],
                    ),
                  ),
                ),
              );
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Wrap(
              alignment: WrapAlignment.center,
              children: [
                item(Icons.alt_route, overview ? t.navRecenter : t.navOverview,
                    onToggleOverview),
                item(
                  switch (viewMode) {
                    NavViewMode.threeD => Icons.view_in_ar,
                    NavViewMode.headingUp => Icons.explore,
                    NavViewMode.northUp => Icons.north,
                  },
                  switch (viewMode) {
                    NavViewMode.threeD => t.navView3D,
                    NavViewMode.headingUp => t.navViewHeading,
                    NavViewMode.northUp => t.navViewNorth,
                  },
                  onCycleView,
                ),
                item(Icons.mic, t.voiceSearch, onVoice),
                item(Icons.share, t.shareTrip, onShare),
                item(Icons.campaign, t.report, onReport),
              ],
            ),
          ),
        );
      },
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

    // سطر واحد: السهم، المسافة، الشارع، ثم «ثم» والالتفاف التالي.
    return _shell(
      child: Row(
        children: [
          Icon(Instructions.icon(m), color: Colors.white, size: 52),
          const SizedBox(width: 8),
          Text.rich(
            TextSpan(children: [
              TextSpan(
                text: parts.first,
                style: text.displaySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  height: 1.0,
                ),
              ),
              TextSpan(
                text: ' ${parts.length > 1 ? parts[1] : ''}',
                style: text.titleLarge?.copyWith(color: Colors.white60),
              ),
            ]),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              street ?? Instructions.text(m, lang),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: text.titleLarge?.copyWith(
                  color: Colors.white, fontWeight: FontWeight.w600, height: 1.15),
            ),
          ),
          if (then != null) ...[
            const SizedBox(width: 8),
            Text(t.navThen, style: text.titleMedium?.copyWith(color: Colors.white60)),
            Icon(Instructions.icon(then), color: Colors.white70, size: 26),
          ],
        ],
      ),
    );
  }

  Widget _shell({required Widget child}) => Container(
        padding: const EdgeInsetsDirectional.fromSTEB(14, 14, 16, 14),
        decoration: BoxDecoration(
          color: NavColors.banner,
          borderRadius: BorderRadius.circular(22),
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
      width: 64,
      height: 64,
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
    required this.onMore,
  });

  final NavState? state;
  final RouteResult route;
  final VoidCallback onEnd;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final lang = Localizations.localeOf(context).languageCode;
    final remainingSec = state?.remainingSec ?? route.durationSec;
    final remainingM = state?.remainingM ?? route.distanceKm * 1000;
    final total = route.distanceKm * 1000;
    final progress = total <= 0 ? 0.0 : (1 - remainingM / total).clamp(0.0, 1.0);
    final duration = Duration(seconds: remainingSec.round());
    return Material(
      elevation: 10,
      borderRadius: BorderRadius.circular(26),
      clipBehavior: Clip.antiAlias,
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LinearProgressIndicator(
            value: progress,
            minHeight: 4,
            color: NavColors.route,
            backgroundColor: NavColors.route.withValues(alpha: 0.12),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 10, 8, 12),
            child: Row(
              children: [
                IconButton.filledTonal(
                  tooltip: t.navEnd,
                  iconSize: 26,
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFFFDE8E8),
                    foregroundColor: const Color(0xFFD13438),
                  ),
                  onPressed: onEnd,
                  icon: const Icon(Icons.close_rounded),
                ),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        RouteCard.formatDuration(t, duration),
                        style: text.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: NavColors.accent,
                        ),
                      ),
                      Text(
                        '${_Banner.distanceText(remainingM, lang)}  ·  '
                        '${t.arriveAt(RouteCard.formatArrival(context, duration))}',
                        style: text.bodyMedium,
                      ),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  tooltip: t.more,
                  iconSize: 26,
                  onPressed: onMore,
                  icon: const Icon(Icons.more_horiz_rounded),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// شريط تقدم الرحلة العمودي.
class _TripBar extends StatelessWidget {
  const _TripBar({required this.progress});
  final double progress;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22,
      child: LayoutBuilder(builder: (context, c) {
        final h = c.maxHeight;
        return Stack(
          alignment: Alignment.topCenter,
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              left: 7,
              right: 7,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: NavColors.route.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
              ),
            ),
            // المقطوع (من الأسفل) رمادي
            Positioned(
              left: 7,
              right: 7,
              bottom: 0,
              height: h * progress,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFFB8C3D1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
              ),
            ),
            Positioned(
              bottom: h * progress - 11,
              child: Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(blurRadius: 4, color: Colors.black26)],
                ),
                child: const Icon(Icons.navigation, size: 15, color: NavColors.route),
              ),
            ),
            const Positioned(
              top: -12,
              child: Icon(Icons.flag_circle, size: 24, color: Color(0xFFD13438)),
            ),
          ],
        );
      }),
    );
  }
}
