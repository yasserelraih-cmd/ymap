// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'YMAP';

  @override
  String get searchHint => 'Search for a place or address';

  @override
  String get home => 'Home';

  @override
  String get work => 'Work';

  @override
  String get saved => 'Saved';

  @override
  String get nearby => 'Nearby';

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get languageSystem => 'Device default';

  @override
  String get languageArabic => 'العربية';

  @override
  String get languageEnglish => 'English';

  @override
  String get appearance => 'Appearance';

  @override
  String get themeSystem => 'Automatic';

  @override
  String get themeLight => 'Day';

  @override
  String get themeDark => 'Night';

  @override
  String get mapComingTitle => 'The map will appear here';

  @override
  String get mapComingBody => 'Step 1.1: Riyadh map with your location';

  @override
  String get myLocation => 'My location';

  @override
  String get layers => 'Layers';

  @override
  String version(String version) {
    return 'Version $version';
  }

  @override
  String get locationDenied =>
      'YMAP can\'t access your location. Allow it in your phone settings.';

  @override
  String get locationServiceOff =>
      'Location services are off. Turn them on and try again.';

  @override
  String get mapLoadError =>
      'Couldn\'t load the map. Check your internet connection.';

  @override
  String get retry => 'Retry';

  @override
  String get attribution => '© OpenStreetMap contributors · OpenFreeMap';

  @override
  String get view3d => '3D view';

  @override
  String get view2d => 'Flat view';

  @override
  String get nearbyTitle => 'Nearby';

  @override
  String get recentTitle => 'Recent searches';

  @override
  String get clearRecent => 'Clear';

  @override
  String get noResults => 'No results. Try writing the name another way.';

  @override
  String get searchError => 'Search failed. Check your internet connection.';

  @override
  String get catRestaurant => 'Restaurants';

  @override
  String get catFuel => 'Fuel';

  @override
  String get catMosque => 'Mosques';

  @override
  String get catPharmacy => 'Pharmacies';

  @override
  String get catHospital => 'Hospitals';

  @override
  String get catBank => 'Banks';

  @override
  String get directions => 'Directions';

  @override
  String get copyLocation => 'Copy location';

  @override
  String get locationCopied => 'Location link copied';

  @override
  String get directionsSoon => 'Navigation comes in the next step (1.3)';

  @override
  String get close => 'Close';

  @override
  String get back => 'Back';

  @override
  String distanceKm(String km) {
    return '$km km';
  }

  @override
  String distanceM(String m) {
    return '$m m';
  }

  @override
  String get pastedLocation => 'Location from link';

  @override
  String get shortLinkWeb =>
      'Short links work in the phone app. In the browser, open the link in Google Maps, then copy the full link or the coordinates and paste them here.';

  @override
  String get openingLink => 'Opening link…';

  @override
  String get linkNotFound => 'No location found in this link.';

  @override
  String get paste => 'Paste';

  @override
  String get openGoogleMaps => 'Google Maps';

  @override
  String get openWaze => 'Waze';

  @override
  String get cantOpen => 'Couldn\'t open the app.';
}
