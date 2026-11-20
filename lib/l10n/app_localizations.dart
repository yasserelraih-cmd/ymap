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
  /// **'لم يُسمح لـYMAP بموقعك. في الآيفون: الإعدادات ← الخصوصية والأمان ← خدمات الموقع ← اختر Chrome (أو «مواقع Safari») ← «أثناء الاستخدام» وفعّل «الموقع الدقيق»، ثم أعد فتح الصفحة.'**
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

  /// No description provided for @calculatingRoute.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ حساب المسار…'**
  String get calculatingRoute;

  /// No description provided for @routeError.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر حساب المسار. تأكد من الاتصال وحاول مرة أخرى.'**
  String get routeError;

  /// No description provided for @needLocation.
  ///
  /// In ar, this message translates to:
  /// **'نحتاج موقعك لحساب المسار. فعّل الموقع وحاول مرة أخرى.'**
  String get needLocation;

  /// No description provided for @fastest.
  ///
  /// In ar, this message translates to:
  /// **'الأسرع'**
  String get fastest;

  /// No description provided for @arriveAt.
  ///
  /// In ar, this message translates to:
  /// **'الوصول {time}'**
  String arriveAt(String time);

  /// No description provided for @startNav.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ'**
  String get startNav;

  /// No description provided for @startNavSoon.
  ///
  /// In ar, this message translates to:
  /// **'الملاحة الصوتية خطوة بخطوة تأتي في الخطوة 1.4'**
  String get startNavSoon;

  /// No description provided for @routeSteps.
  ///
  /// In ar, this message translates to:
  /// **'خطوات المسار'**
  String get routeSteps;

  /// No description provided for @minutesShort.
  ///
  /// In ar, this message translates to:
  /// **'{m} د'**
  String minutesShort(String m);

  /// No description provided for @hoursMinutesShort.
  ///
  /// In ar, this message translates to:
  /// **'{h} س {m} د'**
  String hoursMinutesShort(String h, String m);

  /// No description provided for @routeTo.
  ///
  /// In ar, this message translates to:
  /// **'إلى {name}'**
  String routeTo(String name);

  /// No description provided for @tolls.
  ///
  /// In ar, this message translates to:
  /// **'رسوم'**
  String get tolls;

  /// No description provided for @navThen.
  ///
  /// In ar, this message translates to:
  /// **'ثم'**
  String get navThen;

  /// No description provided for @navKmh.
  ///
  /// In ar, this message translates to:
  /// **'كم/س'**
  String get navKmh;

  /// No description provided for @navEnd.
  ///
  /// In ar, this message translates to:
  /// **'إنهاء'**
  String get navEnd;

  /// No description provided for @navRemaining.
  ///
  /// In ar, this message translates to:
  /// **'{time} · {dist}'**
  String navRemaining(String time, String dist);

  /// No description provided for @navRerouting.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ إعادة حساب المسار…'**
  String get navRerouting;

  /// No description provided for @navArrived.
  ///
  /// In ar, this message translates to:
  /// **'وصلت إلى وجهتك'**
  String get navArrived;

  /// No description provided for @navPreview.
  ///
  /// In ar, this message translates to:
  /// **'معاينة'**
  String get navPreview;

  /// No description provided for @navPreviewBadge.
  ///
  /// In ar, this message translates to:
  /// **'معاينة القيادة'**
  String get navPreviewBadge;

  /// No description provided for @navMute.
  ///
  /// In ar, this message translates to:
  /// **'كتم الصوت'**
  String get navMute;

  /// No description provided for @navUnmute.
  ///
  /// In ar, this message translates to:
  /// **'تشغيل الصوت'**
  String get navUnmute;

  /// No description provided for @navOverview.
  ///
  /// In ar, this message translates to:
  /// **'عرض المسار كاملاً'**
  String get navOverview;

  /// No description provided for @navRecenter.
  ///
  /// In ar, this message translates to:
  /// **'العودة لموقعي'**
  String get navRecenter;

  /// No description provided for @navStartSpeech.
  ///
  /// In ar, this message translates to:
  /// **'لنبدأ.'**
  String get navStartSpeech;

  /// No description provided for @navRerouteSpeech.
  ///
  /// In ar, this message translates to:
  /// **'خرجت عن المسار، جارٍ إعادة الحساب'**
  String get navRerouteSpeech;

  /// No description provided for @navCurrentStreet.
  ///
  /// In ar, this message translates to:
  /// **'على {street}'**
  String navCurrentStreet(String street);

  /// No description provided for @savedTitle.
  ///
  /// In ar, this message translates to:
  /// **'المحفوظات'**
  String get savedTitle;

  /// No description provided for @setHome.
  ///
  /// In ar, this message translates to:
  /// **'تعيين كالبيت'**
  String get setHome;

  /// No description provided for @setWork.
  ///
  /// In ar, this message translates to:
  /// **'تعيين كالعمل'**
  String get setWork;

  /// No description provided for @homeSaved.
  ///
  /// In ar, this message translates to:
  /// **'تم حفظ مكان البيت'**
  String get homeSaved;

  /// No description provided for @workSaved.
  ///
  /// In ar, this message translates to:
  /// **'تم حفظ مكان العمل'**
  String get workSaved;

  /// No description provided for @save.
  ///
  /// In ar, this message translates to:
  /// **'حفظ'**
  String get save;

  /// No description provided for @savedLabel.
  ///
  /// In ar, this message translates to:
  /// **'محفوظ'**
  String get savedLabel;

  /// No description provided for @myCar.
  ///
  /// In ar, this message translates to:
  /// **'سيارتي'**
  String get myCar;

  /// No description provided for @saveCar.
  ///
  /// In ar, this message translates to:
  /// **'احفظ مكان سيارتي'**
  String get saveCar;

  /// No description provided for @carSaved.
  ///
  /// In ar, this message translates to:
  /// **'حفظت مكان سيارتك'**
  String get carSaved;

  /// No description provided for @carSavedAt.
  ///
  /// In ar, this message translates to:
  /// **'ركنت هنا {time}'**
  String carSavedAt(String time);

  /// No description provided for @noSaved.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد أماكن محفوظة بعد. اضغط «حفظ» في بطاقة أي مكان.'**
  String get noSaved;

  /// No description provided for @pickHome.
  ///
  /// In ar, this message translates to:
  /// **'ابحث عن مكان البيت'**
  String get pickHome;

  /// No description provided for @pickWork.
  ///
  /// In ar, this message translates to:
  /// **'ابحث عن مكان العمل'**
  String get pickWork;

  /// No description provided for @delete.
  ///
  /// In ar, this message translates to:
  /// **'حذف'**
  String get delete;

  /// No description provided for @goToCar.
  ///
  /// In ar, this message translates to:
  /// **'اذهب لسيارتي'**
  String get goToCar;

  /// No description provided for @favorites.
  ///
  /// In ar, this message translates to:
  /// **'المفضلة'**
  String get favorites;

  /// No description provided for @more.
  ///
  /// In ar, this message translates to:
  /// **'المزيد'**
  String get more;

  /// No description provided for @modeDrive.
  ///
  /// In ar, this message translates to:
  /// **'سيارة'**
  String get modeDrive;

  /// No description provided for @modeWalk.
  ///
  /// In ar, this message translates to:
  /// **'مشي'**
  String get modeWalk;

  /// No description provided for @navView3D.
  ///
  /// In ar, this message translates to:
  /// **'عرض ثلاثي الأبعاد'**
  String get navView3D;

  /// No description provided for @navViewHeading.
  ///
  /// In ar, this message translates to:
  /// **'عرض باتجاه السير'**
  String get navViewHeading;

  /// No description provided for @navViewNorth.
  ///
  /// In ar, this message translates to:
  /// **'الشمال للأعلى'**
  String get navViewNorth;

  /// No description provided for @report.
  ///
  /// In ar, this message translates to:
  /// **'إبلاغ'**
  String get report;

  /// No description provided for @cameraAlerts.
  ///
  /// In ar, this message translates to:
  /// **'تنبيهات الكاميرات'**
  String get cameraAlerts;

  /// No description provided for @cameraAlertsHint.
  ///
  /// In ar, this message translates to:
  /// **'أوقفها إذا كانت ممنوعة في الدولة التي تقود فيها'**
  String get cameraAlertsHint;

  /// No description provided for @metersShort.
  ///
  /// In ar, this message translates to:
  /// **'م'**
  String get metersShort;

  /// No description provided for @reportTitle.
  ///
  /// In ar, this message translates to:
  /// **'إبلاغ عن شيء على الطريق'**
  String get reportTitle;

  /// No description provided for @alertCamera.
  ///
  /// In ar, this message translates to:
  /// **'كاميرا'**
  String get alertCamera;

  /// No description provided for @alertAccident.
  ///
  /// In ar, this message translates to:
  /// **'حادث'**
  String get alertAccident;

  /// No description provided for @alertTraffic.
  ///
  /// In ar, this message translates to:
  /// **'زحام'**
  String get alertTraffic;

  /// No description provided for @alertHazard.
  ///
  /// In ar, this message translates to:
  /// **'خطر على الطريق'**
  String get alertHazard;

  /// No description provided for @reportThanks.
  ///
  /// In ar, this message translates to:
  /// **'شكراً، سجّلنا البلاغ وسننبهك عنده'**
  String get reportThanks;

  /// No description provided for @alertSpeech.
  ///
  /// In ar, this message translates to:
  /// **'{distance}، {what}'**
  String alertSpeech(String distance, String what);

  /// No description provided for @speedCameraSpeech.
  ///
  /// In ar, this message translates to:
  /// **'كاميرا سرعة'**
  String get speedCameraSpeech;

  /// No description provided for @overSpeedSpeech.
  ///
  /// In ar, this message translates to:
  /// **'انتبه، تجاوزت السرعة المحددة'**
  String get overSpeedSpeech;

  /// No description provided for @consentTitle.
  ///
  /// In ar, this message translates to:
  /// **'ساعدنا نحسّن الخريطة؟'**
  String get consentTitle;

  /// No description provided for @consentBody.
  ///
  /// In ar, this message translates to:
  /// **'نسجّل مسار رحلتك لتصحيح الطرق والحارات. نحذف أول وآخر 200 متر لحماية مكان بيتك وعملك، والمسار يبقى على جهازك ويمكنك حذفه أو إيقاف التسجيل من الإعدادات.'**
  String get consentBody;

  /// No description provided for @consentYes.
  ///
  /// In ar, this message translates to:
  /// **'موافق'**
  String get consentYes;

  /// No description provided for @consentNo.
  ///
  /// In ar, this message translates to:
  /// **'لا، شكراً'**
  String get consentNo;

  /// No description provided for @mapIssueTitle.
  ///
  /// In ar, this message translates to:
  /// **'الخريطة هنا غير دقيقة'**
  String get mapIssueTitle;

  /// No description provided for @mapIssueHint.
  ///
  /// In ar, this message translates to:
  /// **'مثال: الطريق مقفل، الدوار تغيّر، اسم المحل خطأ…'**
  String get mapIssueHint;

  /// No description provided for @mapIssueThanks.
  ///
  /// In ar, this message translates to:
  /// **'شكراً، حفظنا ملاحظتك'**
  String get mapIssueThanks;

  /// No description provided for @cancel.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء'**
  String get cancel;

  /// No description provided for @send.
  ///
  /// In ar, this message translates to:
  /// **'إرسال'**
  String get send;

  /// No description provided for @contribTitle.
  ///
  /// In ar, this message translates to:
  /// **'مساهماتي في الخريطة'**
  String get contribTitle;

  /// No description provided for @recordTracks.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل مساراتي'**
  String get recordTracks;

  /// No description provided for @recordTracksHint.
  ///
  /// In ar, this message translates to:
  /// **'بدون أول وآخر 200 متر، وتبقى على جهازك'**
  String get recordTracksHint;

  /// No description provided for @contribCounts.
  ///
  /// In ar, this message translates to:
  /// **'{tracks} مسار مسجّل · {issues} ملاحظة'**
  String contribCounts(String tracks, String issues);

  /// No description provided for @exportData.
  ///
  /// In ar, this message translates to:
  /// **'تصدير (GeoJSON)'**
  String get exportData;

  /// No description provided for @exported.
  ///
  /// In ar, this message translates to:
  /// **'نسخت البيانات، الصقها في ملف أو بريد'**
  String get exported;

  /// No description provided for @deleteAll.
  ///
  /// In ar, this message translates to:
  /// **'حذف الكل'**
  String get deleteAll;

  /// No description provided for @voiceSearch.
  ///
  /// In ar, this message translates to:
  /// **'بحث بالصوت'**
  String get voiceSearch;

  /// No description provided for @voiceListening.
  ///
  /// In ar, this message translates to:
  /// **'تكلّم الآن…'**
  String get voiceListening;

  /// No description provided for @voiceUnavailable.
  ///
  /// In ar, this message translates to:
  /// **'الميكروفون غير متاح. اسمح به من إعدادات المتصفح أو استخدم Safari.'**
  String get voiceUnavailable;

  /// No description provided for @voiceExample.
  ///
  /// In ar, this message translates to:
  /// **'جرّب: «ودّني أقرب بنزينة» أو «أقرب مسجد على طريقي»'**
  String get voiceExample;

  /// No description provided for @share.
  ///
  /// In ar, this message translates to:
  /// **'مشاركة'**
  String get share;

  /// No description provided for @shareTrip.
  ///
  /// In ar, this message translates to:
  /// **'مشاركة رحلتي'**
  String get shareTrip;

  /// No description provided for @shareTripText.
  ///
  /// In ar, this message translates to:
  /// **'أنا في الطريق إلى {place}، أصل حوالي {eta}.\nموقعي الآن: {link}'**
  String shareTripText(String place, String eta, String link);

  /// No description provided for @openInGoogle.
  ///
  /// In ar, this message translates to:
  /// **'في Google Maps'**
  String get openInGoogle;

  /// No description provided for @copied.
  ///
  /// In ar, this message translates to:
  /// **'تم النسخ'**
  String get copied;

  /// No description provided for @prayerTimes.
  ///
  /// In ar, this message translates to:
  /// **'أوقات الصلاة'**
  String get prayerTimes;

  /// No description provided for @prayerFajr.
  ///
  /// In ar, this message translates to:
  /// **'الفجر'**
  String get prayerFajr;

  /// No description provided for @prayerSunrise.
  ///
  /// In ar, this message translates to:
  /// **'الشروق'**
  String get prayerSunrise;

  /// No description provided for @prayerDhuhr.
  ///
  /// In ar, this message translates to:
  /// **'الظهر'**
  String get prayerDhuhr;

  /// No description provided for @prayerAsr.
  ///
  /// In ar, this message translates to:
  /// **'العصر'**
  String get prayerAsr;

  /// No description provided for @prayerMaghrib.
  ///
  /// In ar, this message translates to:
  /// **'المغرب'**
  String get prayerMaghrib;

  /// No description provided for @prayerIsha.
  ///
  /// In ar, this message translates to:
  /// **'العشاء'**
  String get prayerIsha;

  /// No description provided for @prayerNext.
  ///
  /// In ar, this message translates to:
  /// **'{name} بعد {left}'**
  String prayerNext(String name, String left);

  /// No description provided for @methodUmmAlQura.
  ///
  /// In ar, this message translates to:
  /// **'حسب تقويم أم القرى — قد تختلف دقيقة أو دقيقتين عن مسجدك'**
  String get methodUmmAlQura;

  /// No description provided for @methodEgypt.
  ///
  /// In ar, this message translates to:
  /// **'حسب الهيئة المصرية العامة للمساحة — قد تختلف دقيقة أو دقيقتين'**
  String get methodEgypt;

  /// No description provided for @nearestMosque.
  ///
  /// In ar, this message translates to:
  /// **'أقرب مسجد'**
  String get nearestMosque;

  /// No description provided for @stopAdded.
  ///
  /// In ar, this message translates to:
  /// **'أضفنا محطة: {name}'**
  String stopAdded(String name);

  /// No description provided for @stopAddedSpeech.
  ///
  /// In ar, this message translates to:
  /// **'أضفت {name} على طريقك'**
  String stopAddedSpeech(String name);

  /// No description provided for @go.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ'**
  String get go;

  /// No description provided for @voiceDialect.
  ///
  /// In ar, this message translates to:
  /// **'لهجة التوجيه الصوتي'**
  String get voiceDialect;

  /// No description provided for @dialectSaudi.
  ///
  /// In ar, this message translates to:
  /// **'سعودي'**
  String get dialectSaudi;

  /// No description provided for @dialectEgyptian.
  ///
  /// In ar, this message translates to:
  /// **'مصري'**
  String get dialectEgyptian;

  /// No description provided for @dialectStandard.
  ///
  /// In ar, this message translates to:
  /// **'فصحى'**
  String get dialectStandard;

  /// No description provided for @testVoice.
  ///
  /// In ar, this message translates to:
  /// **'جرّب الصوت'**
  String get testVoice;
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
