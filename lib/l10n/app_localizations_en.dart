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
      'YMAP can\'t access your location. On iPhone: Settings → Privacy & Security → Location Services → Chrome (or Safari Websites) → While Using, turn on Precise Location, then reload.';

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

  @override
  String get calculatingRoute => 'Calculating route…';

  @override
  String get routeError =>
      'Couldn\'t calculate the route. Check your connection and try again.';

  @override
  String get needLocation =>
      'We need your location to calculate the route. Turn it on and try again.';

  @override
  String get fastest => 'Fastest';

  @override
  String arriveAt(String time) {
    return 'Arrive $time';
  }

  @override
  String get startNav => 'Start';

  @override
  String get startNavSoon => 'Turn-by-turn voice navigation comes in step 1.4';

  @override
  String get routeSteps => 'Route steps';

  @override
  String minutesShort(String m) {
    return '$m min';
  }

  @override
  String hoursMinutesShort(String h, String m) {
    return '$h h $m min';
  }

  @override
  String routeTo(String name) {
    return 'To $name';
  }

  @override
  String get tolls => 'Tolls';

  @override
  String get navThen => 'Then';

  @override
  String get navKmh => 'km/h';

  @override
  String get navEnd => 'End';

  @override
  String navRemaining(String time, String dist) {
    return '$time · $dist';
  }

  @override
  String get navRerouting => 'Rerouting…';

  @override
  String get navArrived => 'You have arrived';

  @override
  String get navPreview => 'Preview';

  @override
  String get navPreviewBadge => 'Drive preview';

  @override
  String get navMute => 'Mute';

  @override
  String get navUnmute => 'Unmute';

  @override
  String get navOverview => 'Route overview';

  @override
  String get navRecenter => 'Back to my location';

  @override
  String get navStartSpeech => 'Let\'s go.';

  @override
  String get navRerouteSpeech => 'You left the route, recalculating';

  @override
  String navCurrentStreet(String street) {
    return 'On $street';
  }

  @override
  String get savedTitle => 'Saved';

  @override
  String get setHome => 'Set as home';

  @override
  String get setWork => 'Set as work';

  @override
  String get homeSaved => 'Home saved';

  @override
  String get workSaved => 'Work saved';

  @override
  String get save => 'Save';

  @override
  String get savedLabel => 'Saved';

  @override
  String get myCar => 'My car';

  @override
  String get saveCar => 'Save my car\'s location';

  @override
  String get carSaved => 'Car location saved';

  @override
  String carSavedAt(String time) {
    return 'Parked here $time';
  }

  @override
  String get noSaved => 'No saved places yet. Tap «Save» on any place card.';

  @override
  String get pickHome => 'Search for your home';

  @override
  String get pickWork => 'Search for your work';

  @override
  String get delete => 'Delete';

  @override
  String get goToCar => 'Go to my car';

  @override
  String get favorites => 'Favorites';

  @override
  String get more => 'More';

  @override
  String get modeDrive => 'Drive';

  @override
  String get modeWalk => 'Walk';

  @override
  String get navView3D => '3D view';

  @override
  String get navViewHeading => 'Heading up';

  @override
  String get navViewNorth => 'North up';

  @override
  String get report => 'Report';

  @override
  String get cameraAlerts => 'Camera alerts';

  @override
  String get cameraAlertsHint => 'Turn off where camera alerts are not allowed';

  @override
  String get metersShort => 'm';

  @override
  String get reportTitle => 'Report something on the road';

  @override
  String get alertCamera => 'Camera';

  @override
  String get alertAccident => 'Accident';

  @override
  String get alertTraffic => 'Traffic';

  @override
  String get alertHazard => 'Road hazard';

  @override
  String get reportThanks => 'Thanks — report saved, we\'ll alert you there';

  @override
  String alertSpeech(String distance, String what) {
    return '$distance, $what';
  }

  @override
  String get speedCameraSpeech => 'speed camera';

  @override
  String get overSpeedSpeech => 'Careful, you are over the speed limit';

  @override
  String get consentTitle => 'Help us improve the map?';

  @override
  String get consentBody =>
      'We record your trip path to fix roads and lanes. The first and last 200 m are removed to protect your home and work, the path stays on your device, and you can delete it or stop recording in Settings.';

  @override
  String get consentYes => 'Allow';

  @override
  String get consentNo => 'No thanks';

  @override
  String get mapIssueTitle => 'Map is wrong here';

  @override
  String get mapIssueHint =>
      'e.g. road closed, roundabout changed, wrong shop name…';

  @override
  String get mapIssueThanks => 'Thanks, your note is saved';

  @override
  String get cancel => 'Cancel';

  @override
  String get send => 'Send';

  @override
  String get contribTitle => 'My map contributions';

  @override
  String get recordTracks => 'Record my trips';

  @override
  String get recordTracksHint =>
      'Without the first and last 200 m, kept on your device';

  @override
  String contribCounts(String tracks, String issues) {
    return '$tracks trips recorded · $issues notes';
  }

  @override
  String get exportData => 'Export (GeoJSON)';

  @override
  String get exported => 'Copied — paste it into a file or email';

  @override
  String get deleteAll => 'Delete all';

  @override
  String get voiceSearch => 'Voice search';

  @override
  String get voiceListening => 'Speak now…';

  @override
  String get voiceUnavailable =>
      'Microphone unavailable. Allow it in browser settings or use Safari.';

  @override
  String get voiceExample => 'Try: “take me to the nearest gas station”';

  @override
  String get share => 'Share';

  @override
  String get shareTrip => 'Share my trip';

  @override
  String shareTripText(String place, String eta, String link) {
    return 'I\'m on my way to $place, arriving around $eta.\nMy location now: $link';
  }

  @override
  String get openInGoogle => 'In Google Maps';

  @override
  String get copied => 'Copied';

  @override
  String get prayerTimes => 'Prayer times';

  @override
  String get prayerFajr => 'Fajr';

  @override
  String get prayerSunrise => 'Sunrise';

  @override
  String get prayerDhuhr => 'Dhuhr';

  @override
  String get prayerAsr => 'Asr';

  @override
  String get prayerMaghrib => 'Maghrib';

  @override
  String get prayerIsha => 'Isha';

  @override
  String prayerNext(String name, String left) {
    return '$name in $left';
  }

  @override
  String get methodUmmAlQura =>
      'Umm al-Qura method — may differ by a minute or two from your mosque';

  @override
  String get methodEgypt =>
      'Egyptian General Authority of Survey method — may differ slightly';

  @override
  String get nearestMosque => 'Nearest mosque';

  @override
  String stopAdded(String name) {
    return 'Stop added: $name';
  }

  @override
  String stopAddedSpeech(String name) {
    return 'Added $name on your way';
  }

  @override
  String get go => 'Go';

  @override
  String get voiceDialect => 'Voice guidance dialect (Arabic)';

  @override
  String get dialectSaudi => 'Saudi';

  @override
  String get dialectEgyptian => 'Egyptian';

  @override
  String get dialectStandard => 'Standard';

  @override
  String get testVoice => 'Test voice';

  @override
  String get metro => 'Riyadh Metro';

  @override
  String get metroShown =>
      'Riyadh Metro lines and stations (OpenStreetMap data)';
}
