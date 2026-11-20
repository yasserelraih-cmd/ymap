import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @appName.
  ///
  /// In ar, this message translates to:
  /// **'YMAP'**
  String get appName;

  /// No description provided for @searchHint.
  ///
  /// In ar, this message translates to:
  /// **'ابحث عن مكان أو عنوان'**
  String get searchHint;

  /// No description provided for @home.
  ///
  /// In ar, this message translates to:
  /// **'البيت'**
  String get home;

  /// No description provided for @work.
  ///
  /// In ar, this message translates to:
  /// **'العمل'**
  String get work;

  /// No description provided for @saved.
  ///
  /// In ar, this message translates to:
  /// **'المحفوظات'**
  String get saved;

  /// No description provided for @nearby.
  ///
  /// In ar, this message translates to:
  /// **'القريب'**
  String get nearby;

  /// No description provided for @settings.
  ///
  /// In ar, this message translates to:
  /// **'الإعدادات'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In ar, this message translates to:
  /// **'اللغة'**
  String get language;

  /// No description provided for @languageSystem.
  ///
  /// In ar, this message translates to:
  /// **'حسب الجهاز'**
  String get languageSystem;

  /// No description provided for @languageArabic.
  ///
  /// In ar, this message translates to:
  /// **'العربية'**
  String get languageArabic;

  /// No description provided for @languageEnglish.
  ///
  /// In ar, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @appearance.
  ///
  /// In ar, this message translates to:
  /// **'المظهر'**
  String get appearance;

  /// No description provided for @themeSystem.
  ///
  /// In ar, this message translates to:
  /// **'تلقائي'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In ar, this message translates to:
  /// **'نهاري'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In ar, this message translates to:
  /// **'ليلي'**
  String get themeDark;

  /// No description provided for @mapComingTitle.
  ///
  /// In ar, this message translates to:
  /// **'هنا ستظهر الخريطة'**
  String get mapComingTitle;

  /// No description provided for @mapComingBody.
  ///
  /// In ar, this message translates to:
  /// **'الخطوة 1.1: خريطة الرياض وموقعك عليها'**
  String get mapComingBody;

  /// No description provided for @myLocation.
  ///
  /// In ar, this message translates to:
  /// **'موقعي'**
  String get myLocation;

  /// No description provided for @layers.
  ///
  /// In ar, this message translates to:
  /// **'الطبقات'**
  String get layers;

  /// No description provided for @version.
  ///
  /// In ar, this message translates to:
  /// **'الإصدار {version}'**
  String version(String version);

  /// No description provided for @locationDenied.
  ///
  /// In ar, this message translates to:
  /// **'لم تسمح لـYMAP بالوصول لموقعك. فعّله من إعدادات الجوال.'**
  String get locationDenied;

  /// No description provided for @locationServiceOff.
  ///
  /// In ar, this message translates to:
  /// **'خدمة الموقع مغلقة في جوالك. شغّلها ثم حاول مرة أخرى.'**
  String get locationServiceOff;

  /// No description provided for @mapLoadError.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر تحميل الخريطة. تأكد من الاتصال بالإنترنت.'**
  String get mapLoadError;

  /// No description provided for @retry.
  ///
  /// In ar, this message translates to:
  /// **'إعادة المحاولة'**
  String get retry;

  /// No description provided for @attribution.
  ///
  /// In ar, this message translates to:
  /// **'© مساهمو OpenStreetMap · OpenFreeMap'**
  String get attribution;

  /// No description provided for @view3d.
  ///
  /// In ar, this message translates to:
  /// **'منظور ثلاثي الأبعاد'**
  String get view3d;

  /// No description provided for @view2d.
  ///
  /// In ar, this message translates to:
  /// **'منظور مسطّح'**
  String get view2d;

  /// No description provided for @nearbyTitle.
  ///
  /// In ar, this message translates to:
  /// **'حولك'**
  String get nearbyTitle;

  /// No description provided for @recentTitle.
  ///
  /// In ar, this message translates to:
  /// **'آخر عمليات البحث'**
  String get recentTitle;

  /// No description provided for @clearRecent.
  ///
  /// In ar, this message translates to:
  /// **'مسح'**
  String get clearRecent;

  /// No description provided for @noResults.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد نتائج. جرّب كتابة الاسم بطريقة أخرى.'**
  String get noResults;

  /// No description provided for @searchError.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر البحث. تأكد من الاتصال بالإنترنت.'**
  String get searchError;

  /// No description provided for @catRestaurant.
  ///
  /// In ar, this message translates to:
  /// **'مطاعم'**
  String get catRestaurant;

  /// No description provided for @catFuel.
  ///
  /// In ar, this message translates to:
  /// **'محطات وقود'**
  String get catFuel;

  /// No description provided for @catMosque.
  ///
  /// In ar, this message translates to:
  /// **'مساجد'**
  String get catMosque;

  /// No description provided for @catPharmacy.
  ///
  /// In ar, this message translates to:
  /// **'صيدليات'**
  String get catPharmacy;

  /// No description provided for @catHospital.
  ///
  /// In ar, this message translates to:
  /// **'مستشفيات'**
  String get catHospital;

  /// No description provided for @catBank.
  ///
  /// In ar, this message translates to:
  /// **'بنوك'**
  String get catBank;

  /// No description provided for @directions.
  ///
  /// In ar, this message translates to:
  /// **'المسار'**
  String get directions;

  /// No description provided for @copyLocation.
  ///
  /// In ar, this message translates to:
  /// **'نسخ الموقع'**
  String get copyLocation;

  /// No description provided for @locationCopied.
  ///
  /// In ar, this message translates to:
  /// **'تم نسخ رابط الموقع'**
  String get locationCopied;

  /// No description provided for @directionsSoon.
  ///
  /// In ar, this message translates to:
  /// **'الملاحة تأتي في الخطوة التالية (1.3)'**
  String get directionsSoon;

  /// No description provided for @close.
  ///
  /// In ar, this message translates to:
  /// **'إغلاق'**
  String get close;

  /// No description provided for @back.
  ///
  /// In ar, this message translates to:
  /// **'رجوع'**
  String get back;

  /// No description provided for @distanceKm.
  ///
  /// In ar, this message translates to:
  /// **'{km} كم'**
  String distanceKm(String km);

  /// No description provided for @distanceM.
  ///
  /// In ar, this message translates to:
  /// **'{m} م'**
  String distanceM(String m);

  /// No description provided for @pastedLocation.
  ///
  /// In ar, this message translates to:
  /// **'موقع من الرابط'**
  String get pastedLocation;

  /// No description provided for @shortLinkWeb.
  ///
  /// In ar, this message translates to:
  /// **'الروابط المختصرة تعمل في تطبيق الجوال. في المتصفح افتح الرابط في Google Maps ثم انسخ الرابط الكامل أو الإحداثيات والصقها هنا.'**
  String get shortLinkWeb;

  /// No description provided for @openingLink.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ فتح الرابط…'**
  String get openingLink;

  /// No description provided for @linkNotFound.
  ///
  /// In ar, this message translates to:
  /// **'لم أجد موقعاً في هذا الرابط.'**
  String get linkNotFound;

  /// No description provided for @paste.
  ///
  /// In ar, this message translates to:
  /// **'لصق'**
  String get paste;

  /// No description provided for @openGoogleMaps.
  ///
  /// In ar, this message translates to:
  /// **'Google Maps'**
  String get openGoogleMaps;

  /// No description provided for @openWaze.
  ///
  /// In ar, this message translates to:
  /// **'Waze'**
  String get openWaze;

  /// No description provided for @cantOpen.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر فتح التطبيق.'**
  String get cantOpen;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
