import 'package:material_ui/material_ui.dart';

import '../l10n/app_localizations.dart';
import '../routing/instructions.dart';
import '../routing/route.dart';
import '../search/place.dart';

/// بطاقة المسارات: الخيارات (الأسرع أولاً) + خطوات المسار + زر «ابدأ».
class RouteCard extends StatelessWidget {
  const RouteCard({
    super.key,
    required this.destination,
    required this.routes,
    required this.selected,
    required this.onSelect,
    required this.onClose,
    required this.onStart,
    this.loading = false,
    this.scrollController,
  });

  final Place destination;
  final List<RouteResult> routes;
  final int selected;
  final ValueChanged<int> onSelect;
  final VoidCallback onClose;
  final VoidCallback onStart;
  final bool loading;
  final ScrollController? scrollController;

  static String formatDuration(AppLocalizations t, Duration d) {
    final minutes = (d.inSeconds / 60).ceil();
    if (minutes < 60) return t.minutesShort('$minutes');
    return t.hoursMinutesShort('${minutes ~/ 60}', '${minutes % 60}');
  }

  static String formatArrival(BuildContext context, Duration d) {
    final at = TimeOfDay.fromDateTime(DateTime.now().add(d));
    return MaterialLocalizations.of(context).formatTimeOfDay(at);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final lang = Localizations.localeOf(context).languageCode;

    return ListView(
      controller: scrollController,
      padding: const EdgeInsetsDirectional.fromSTEB(16, 4, 8, 24),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                t.routeTo(destination.name),
                style: text.titleMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              tooltip: t.close,
              onPressed: onClose,
              icon: const Icon(Icons.close),
            ),
          ],
        ),
        if (loading)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 12),
                Text(t.calculatingRoute),
              ],
            ),
          )
        else ...[
          SizedBox(
            height: 116,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsetsDirectional.only(end: 8),
              itemCount: routes.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final r = routes[i];
                final isSel = i == selected;
                return InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => onSelect(i),
                  child: Container(
                    width: 150,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSel ? scheme.primaryContainer : scheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSel ? scheme.primary : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          formatDuration(t, r.duration),
                          style: text.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isSel ? scheme.onPrimaryContainer : null,
                          ),
                        ),
                        Text(
                          '${r.distanceKm.toStringAsFixed(1)} ${lang == 'ar' ? 'كم' : 'km'}'
                          '${r.hasToll ? ' · ${t.tolls}' : ''}',
                          style: text.bodyMedium,
                        ),
                        const Spacer(),
                        Text(
                          i == 0 ? t.fastest : t.arriveAt(formatArrival(context, r.duration)),
                          style: text.labelMedium?.copyWith(
                            color: i == 0 ? scheme.primary : scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 8),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      textStyle: text.titleMedium,
                    ),
                    onPressed: onStart,
                    icon: const Icon(Icons.navigation),
                    label: Text(t.startNav),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(t.arriveAt(formatArrival(context, routes[selected].duration)),
                        style: text.titleSmall),
                    Text(
                      '${formatDuration(t, routes[selected].duration)} · '
                      '${routes[selected].distanceKm.toStringAsFixed(1)} ${lang == 'ar' ? 'كم' : 'km'}',
                      style: text.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(t.routeSteps, style: text.titleSmall),
          for (final m in routes[selected].maneuvers)
            ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              leading: Icon(Instructions.icon(m), color: scheme.primary),
              title: Text(Instructions.text(m, lang)),
              trailing: m.lengthKm > 0
                  ? Text(
                      m.lengthKm < 1
                          ? '${(m.lengthKm * 1000 / 10).round() * 10} ${lang == 'ar' ? 'م' : 'm'}'
                          : '${m.lengthKm.toStringAsFixed(1)} ${lang == 'ar' ? 'كم' : 'km'}',
                      style: text.labelMedium,
                    )
                  : null,
            ),
        ],
      ],
    );
  }
}
