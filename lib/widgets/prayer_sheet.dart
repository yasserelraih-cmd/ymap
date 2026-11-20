import 'package:material_ui/material_ui.dart';

import '../l10n/app_localizations.dart';
import '../prayer/prayer_times.dart';

String prayerName(AppLocalizations t, Prayer p) => switch (p) {
      Prayer.fajr => t.prayerFajr,
      Prayer.sunrise => t.prayerSunrise,
      Prayer.dhuhr => t.prayerDhuhr,
      Prayer.asr => t.prayerAsr,
      Prayer.maghrib => t.prayerMaghrib,
      Prayer.isha => t.prayerIsha,
    };

/// الصلاة القادمة لموقعك، مع الغد بعد العشاء.
(Prayer, DateTime) nextPrayer(double lat, double lon, DateTime now) {
  final today = PrayerCalculator.compute(date: now, lat: lat, lon: lon);
  final next = today.nextAfter(now);
  if (next != null) return next;
  final tomorrow = PrayerCalculator.compute(
      date: now.add(const Duration(days: 1)), lat: lat, lon: lon);
  return (Prayer.fajr, tomorrow.times[Prayer.fajr]!);
}

/// أوقات صلاة اليوم. يرجع true إذا ضغطت «أقرب مسجد».
Future<bool?> showPrayerSheet(BuildContext context, double lat, double lon) {
  return showModalBottomSheet<bool>(
    context: context,
    showDragHandle: true,
    constraints: const BoxConstraints(maxWidth: 560),
    builder: (context) {
      final t = AppLocalizations.of(context);
      final now = DateTime.now();
      final day = PrayerCalculator.compute(date: now, lat: lat, lon: lon);
      final (nextP, nextT) = nextPrayer(lat, lon, now);
      final left = nextT.difference(now);
      final method = PrayerMethod.forLocation(lat, lon);
      final scheme = Theme.of(context).colorScheme;
      String fmt(DateTime d) => TimeOfDay.fromDateTime(d).format(context);
      return SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(t.prayerTimes, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(
                t.prayerNext(prayerName(t, nextP),
                    '${left.inHours}:${(left.inMinutes % 60).toString().padLeft(2, '0')}'),
                style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              for (final p in Prayer.values)
                Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: p == nextP ? scheme.primaryContainer : null,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(prayerName(t, p),
                            style: TextStyle(
                              color: p == Prayer.sunrise ? scheme.onSurfaceVariant : null,
                              fontWeight: p == nextP ? FontWeight.bold : null,
                            )),
                      ),
                      Text(fmt(day.times[p]!),
                          style: TextStyle(
                              fontWeight: p == nextP ? FontWeight.bold : null)),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
              Text(
                method == PrayerMethod.egypt ? t.methodEgypt : t.methodUmmAlQura,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () => Navigator.of(context).pop(true),
                icon: const Icon(Icons.mosque),
                label: Text(t.nearestMosque),
              ),
            ],
          ),
        ),
      );
    },
  );
}
