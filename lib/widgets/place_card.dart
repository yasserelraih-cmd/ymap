import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';
import '../search/categories.dart';
import '../search/location_link.dart';
import '../search/place.dart';
import '../search/search_format.dart';

/// بطاقة المكان المختار: الاسم، العنوان، المسافة، والأزرار.
class PlaceCard extends StatelessWidget {
  const PlaceCard({
    super.key,
    required this.place,
    required this.onClose,
    required this.onMessage,
    this.fromLat,
    this.fromLon,
    this.scrollController,
  });

  final Place place;
  final VoidCallback onClose;
  final void Function(String) onMessage;
  final double? fromLat;
  final double? fromLon;
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final hasFrom = fromLat != null && fromLon != null;
    return ListView(
      controller: scrollController,
      padding: const EdgeInsetsDirectional.fromSTEB(16, 4, 8, 24),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PlaceIcon(icon: PlaceCategory.iconFor(place.osmKey, place.osmValue)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(place.name, style: text.titleLarge),
                  if (place.subtitle.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(place.subtitle, style: text.bodyMedium),
                    ),
                  if (hasFrom)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        formatDistance(t, fromLat!, fromLon!, place.lat, place.lon),
                        style: text.labelLarge?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            IconButton(
              tooltip: t.close,
              onPressed: onClose,
              icon: const Icon(Icons.close),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsetsDirectional.only(end: 8),
          child: Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => onMessage(t.directionsSoon),
                  icon: const Icon(Icons.directions),
                  label: Text(t.directions),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    // رابط Google Maps لأنه يفتح عند الجميع (واتساب وغيره).
                    await Clipboard.setData(ClipboardData(
                      text: '${place.name}\n'
                          '${LocationLink.googleMaps(place.lat, place.lon)}',
                    ));
                    onMessage(t.locationCopied);
                  },
                  icon: const Icon(Icons.copy),
                  label: Text(t.copyLocation),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsetsDirectional.only(end: 8),
          child: Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: () => _open(
                      LocationLink.googleMaps(place.lat, place.lon), t),
                  icon: const Icon(Icons.map_outlined),
                  label: Text(t.openGoogleMaps),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: () =>
                      _open(LocationLink.waze(place.lat, place.lon), t),
                  icon: const Icon(Icons.navigation_outlined),
                  label: Text(t.openWaze),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _open(Uri uri, AppLocalizations t) async {
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) onMessage(t.cantOpen);
  }
}
