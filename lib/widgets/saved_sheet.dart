import 'package:material_ui/material_ui.dart';

import '../l10n/app_localizations.dart';
import '../saved/saved_places.dart';
import '../search/categories.dart';
import '../search/place.dart';

/// قائمة المحفوظات: البيت، العمل، سيارتي، والمفضلة.
/// ترجع المكان الذي اخترته.
Future<Place?> showSavedSheet(BuildContext context, SavedPlaces saved) {
  return showModalBottomSheet<Place>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    constraints: const BoxConstraints(maxWidth: 560),
    builder: (context) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      builder: (context, controller) => ListenableBuilder(
        listenable: saved,
        builder: (context, _) {
          final t = AppLocalizations.of(context);
          final car = saved.car;
          final carPlace = car == null
              ? null
              : Place(
                  name: t.myCar,
                  subtitle: t.carSavedAt(TimeOfDay.fromDateTime(car.savedAt)
                      .format(context)),
                  lat: car.lat,
                  lon: car.lon,
                  osmKey: 'car',
                );
          final empty = saved.home == null &&
              saved.work == null &&
              car == null &&
              saved.favorites.isEmpty;
          return ListView(
            controller: controller,
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(20, 0, 20, 8),
                child: Text(t.savedTitle,
                    style: Theme.of(context).textTheme.titleLarge),
              ),
              if (empty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(t.noSaved, textAlign: TextAlign.center),
                ),
              if (saved.home != null)
                _tile(context, Icons.home, t.home, saved.home!,
                    onDelete: saved.clearHome),
              if (saved.work != null)
                _tile(context, Icons.work, t.work, saved.work!,
                    onDelete: saved.clearWork),
              if (carPlace != null)
                _tile(context, Icons.directions_car, t.myCar, carPlace,
                    subtitle: carPlace.subtitle, onDelete: saved.clearCar),
              if (saved.favorites.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(20, 16, 20, 4),
                  child: Text(t.favorites,
                      style: Theme.of(context).textTheme.titleSmall),
                ),
                for (final p in saved.favorites)
                  _tile(context,
                      PlaceCategory.iconFor(p.osmKey, p.osmValue), p.name, p,
                      onDelete: () => saved.toggleFavorite(p)),
              ],
            ],
          );
        },
      ),
    ),
  );
}

Widget _tile(
  BuildContext context,
  IconData icon,
  String title,
  Place place, {
  String? subtitle,
  required Future<void> Function() onDelete,
}) {
  final t = AppLocalizations.of(context);
  final scheme = Theme.of(context).colorScheme;
  return ListTile(
    leading: CircleAvatar(
      backgroundColor: scheme.primaryContainer,
      child: Icon(icon, color: scheme.onPrimaryContainer),
    ),
    title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
    subtitle: Text(
      subtitle ?? (title == place.name ? place.subtitle : place.name),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    ),
    trailing: IconButton(
      tooltip: t.delete,
      icon: const Icon(Icons.delete_outline),
      onPressed: onDelete,
    ),
    onTap: () => Navigator.of(context).pop(place),
  );
}
