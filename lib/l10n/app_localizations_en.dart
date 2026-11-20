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
}
