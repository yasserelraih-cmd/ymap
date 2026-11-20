import 'package:material_ui/material_ui.dart';

import '../l10n/app_localizations.dart';
import 'categories.dart';
import 'search_service.dart';

/// اسم التصنيف بلغة التطبيق.
String categoryLabel(AppLocalizations t, PlaceCategory c) => switch (c) {
      PlaceCategory.restaurant => t.catRestaurant,
      PlaceCategory.fuel => t.catFuel,
      PlaceCategory.mosque => t.catMosque,
      PlaceCategory.pharmacy => t.catPharmacy,
      PlaceCategory.hospital => t.catHospital,
      PlaceCategory.bank => t.catBank,
      PlaceCategory.parking => t.catParking,
    };

/// «350 م» أو «2.4 كم».
String formatDistance(
  AppLocalizations t,
  double fromLat,
  double fromLon,
  double toLat,
  double toLon,
) {
  final km = distanceKm(fromLat, fromLon, toLat, toLon);
  if (km < 1) {
    final m = (km * 1000 / 10).round() * 10;
    return t.distanceM('$m');
  }
  return t.distanceKm(km < 10 ? km.toStringAsFixed(1) : km.round().toString());
}

/// أيقونة دائرية صغيرة لنوع المكان.
class PlaceIcon extends StatelessWidget {
  const PlaceIcon({super.key, required this.icon});
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return CircleAvatar(
      radius: 20,
      backgroundColor: scheme.primaryContainer,
      child: Icon(icon, size: 20, color: scheme.onPrimaryContainer),
    );
  }
}
