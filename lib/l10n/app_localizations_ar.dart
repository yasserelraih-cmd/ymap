// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appName => 'YMAP';

  @override
  String get searchHint => 'ابحث عن مكان أو عنوان';

  @override
  String get home => 'البيت';

  @override
  String get work => 'العمل';

  @override
  String get saved => 'المحفوظات';

  @override
  String get nearby => 'القريب';

  @override
  String get settings => 'الإعدادات';

  @override
  String get language => 'اللغة';

  @override
  String get languageSystem => 'حسب الجهاز';

  @override
  String get languageArabic => 'العربية';

  @override
  String get languageEnglish => 'English';

  @override
  String get appearance => 'المظهر';

  @override
  String get themeSystem => 'تلقائي';

  @override
  String get themeLight => 'نهاري';

  @override
  String get themeDark => 'ليلي';

  @override
  String get mapComingTitle => 'هنا ستظهر الخريطة';

  @override
  String get mapComingBody => 'الخطوة 1.1: خريطة الرياض وموقعك عليها';

  @override
  String get myLocation => 'موقعي';

  @override
  String get layers => 'الطبقات';

  @override
  String version(String version) {
    return 'الإصدار $version';
  }

  @override
  String get locationDenied =>
      'لم يُسمح لـYMAP بموقعك. في الآيفون: الإعدادات ← الخصوصية والأمان ← خدمات الموقع ← اختر Chrome (أو «مواقع Safari») ← «أثناء الاستخدام» وفعّل «الموقع الدقيق»، ثم أعد فتح الصفحة.';

  @override
  String get locationServiceOff =>
      'خدمة الموقع مغلقة في جوالك. شغّلها ثم حاول مرة أخرى.';

  @override
  String get mapLoadError => 'تعذّر تحميل الخريطة. تأكد من الاتصال بالإنترنت.';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get attribution => '© مساهمو OpenStreetMap · OpenFreeMap';

  @override
  String get view3d => 'منظور ثلاثي الأبعاد';

  @override
  String get view2d => 'منظور مسطّح';

  @override
  String get nearbyTitle => 'حولك';

  @override
  String get recentTitle => 'آخر عمليات البحث';

  @override
  String get clearRecent => 'مسح';

  @override
  String get noResults => 'لا توجد نتائج. جرّب كتابة الاسم بطريقة أخرى.';

  @override
  String get searchError => 'تعذّر البحث. تأكد من الاتصال بالإنترنت.';

  @override
  String get catRestaurant => 'مطاعم';

  @override
  String get catFuel => 'محطات وقود';

  @override
  String get catMosque => 'مساجد';

  @override
  String get catPharmacy => 'صيدليات';

  @override
  String get catHospital => 'مستشفيات';

  @override
  String get catBank => 'بنوك';

  @override
  String get directions => 'المسار';

  @override
  String get copyLocation => 'نسخ الموقع';

  @override
  String get locationCopied => 'تم نسخ رابط الموقع';

  @override
  String get directionsSoon => 'الملاحة تأتي في الخطوة التالية (1.3)';

  @override
  String get close => 'إغلاق';

  @override
  String get back => 'رجوع';

  @override
  String distanceKm(String km) {
    return '$km كم';
  }

  @override
  String distanceM(String m) {
    return '$m م';
  }

  @override
  String get pastedLocation => 'موقع من الرابط';

  @override
  String get shortLinkWeb =>
      'الروابط المختصرة تعمل في تطبيق الجوال. في المتصفح افتح الرابط في Google Maps ثم انسخ الرابط الكامل أو الإحداثيات والصقها هنا.';

  @override
  String get openingLink => 'جارٍ فتح الرابط…';

  @override
  String get linkNotFound => 'لم أجد موقعاً في هذا الرابط.';

  @override
  String get paste => 'لصق';

  @override
  String get openGoogleMaps => 'Google Maps';

  @override
  String get openWaze => 'Waze';

  @override
  String get cantOpen => 'تعذّر فتح التطبيق.';

  @override
  String get calculatingRoute => 'جارٍ حساب المسار…';

  @override
  String get routeError => 'تعذّر حساب المسار. تأكد من الاتصال وحاول مرة أخرى.';

  @override
  String get needLocation =>
      'نحتاج موقعك لحساب المسار. فعّل الموقع وحاول مرة أخرى.';

  @override
  String get fastest => 'الأسرع';

  @override
  String arriveAt(String time) {
    return 'الوصول $time';
  }

  @override
  String get startNav => 'ابدأ';

  @override
  String get startNavSoon => 'الملاحة الصوتية خطوة بخطوة تأتي في الخطوة 1.4';

  @override
  String get routeSteps => 'خطوات المسار';

  @override
  String minutesShort(String m) {
    return '$m د';
  }

  @override
  String hoursMinutesShort(String h, String m) {
    return '$h س $m د';
  }

  @override
  String routeTo(String name) {
    return 'إلى $name';
  }

  @override
  String get tolls => 'رسوم';

  @override
  String get navThen => 'ثم';

  @override
  String get navKmh => 'كم/س';

  @override
  String get navEnd => 'إنهاء';

  @override
  String navRemaining(String time, String dist) {
    return '$time · $dist';
  }

  @override
  String get navRerouting => 'جارٍ إعادة حساب المسار…';

  @override
  String get navArrived => 'وصلت إلى وجهتك';

  @override
  String get navPreview => 'معاينة';

  @override
  String get navPreviewBadge => 'معاينة القيادة';

  @override
  String get navMute => 'كتم الصوت';

  @override
  String get navUnmute => 'تشغيل الصوت';

  @override
  String get navOverview => 'عرض المسار كاملاً';

  @override
  String get navRecenter => 'العودة لموقعي';

  @override
  String get navStartSpeech => 'لنبدأ.';

  @override
  String get navRerouteSpeech => 'خرجت عن المسار، جارٍ إعادة الحساب';

  @override
  String navCurrentStreet(String street) {
    return 'على $street';
  }

  @override
  String get savedTitle => 'المحفوظات';

  @override
  String get setHome => 'تعيين كالبيت';

  @override
  String get setWork => 'تعيين كالعمل';

  @override
  String get homeSaved => 'تم حفظ مكان البيت';

  @override
  String get workSaved => 'تم حفظ مكان العمل';

  @override
  String get save => 'حفظ';

  @override
  String get savedLabel => 'محفوظ';

  @override
  String get myCar => 'سيارتي';

  @override
  String get saveCar => 'احفظ مكان سيارتي';

  @override
  String get carSaved => 'حفظت مكان سيارتك';

  @override
  String carSavedAt(String time) {
    return 'ركنت هنا $time';
  }

  @override
  String get noSaved =>
      'لا توجد أماكن محفوظة بعد. اضغط «حفظ» في بطاقة أي مكان.';

  @override
  String get pickHome => 'ابحث عن مكان البيت';

  @override
  String get pickWork => 'ابحث عن مكان العمل';

  @override
  String get delete => 'حذف';

  @override
  String get goToCar => 'اذهب لسيارتي';

  @override
  String get favorites => 'المفضلة';

  @override
  String get more => 'المزيد';

  @override
  String get modeDrive => 'سيارة';

  @override
  String get modeWalk => 'مشي';

  @override
  String get navView3D => 'عرض ثلاثي الأبعاد';

  @override
  String get navViewHeading => 'عرض باتجاه السير';

  @override
  String get navViewNorth => 'الشمال للأعلى';

  @override
  String get report => 'إبلاغ';

  @override
  String get cameraAlerts => 'تنبيهات الكاميرات';

  @override
  String get cameraAlertsHint =>
      'أوقفها إذا كانت ممنوعة في الدولة التي تقود فيها';

  @override
  String get metersShort => 'م';

  @override
  String get reportTitle => 'إبلاغ عن شيء على الطريق';

  @override
  String get alertCamera => 'كاميرا';

  @override
  String get alertAccident => 'حادث';

  @override
  String get alertTraffic => 'زحام';

  @override
  String get alertHazard => 'خطر على الطريق';

  @override
  String get reportThanks => 'شكراً، سجّلنا البلاغ وسننبهك عنده';

  @override
  String alertSpeech(String distance, String what) {
    return '$distance، $what';
  }

  @override
  String get speedCameraSpeech => 'كاميرا سرعة';

  @override
  String get overSpeedSpeech => 'انتبه، تجاوزت السرعة المحددة';

  @override
  String get consentTitle => 'ساعدنا نحسّن الخريطة؟';

  @override
  String get consentBody =>
      'نسجّل مسار رحلتك لتصحيح الطرق والحارات. نحذف أول وآخر 200 متر لحماية مكان بيتك وعملك، والمسار يبقى على جهازك ويمكنك حذفه أو إيقاف التسجيل من الإعدادات.';

  @override
  String get consentYes => 'موافق';

  @override
  String get consentNo => 'لا، شكراً';

  @override
  String get mapIssueTitle => 'الخريطة هنا غير دقيقة';

  @override
  String get mapIssueHint => 'مثال: الطريق مقفل، الدوار تغيّر، اسم المحل خطأ…';

  @override
  String get mapIssueThanks => 'شكراً، حفظنا ملاحظتك';

  @override
  String get cancel => 'إلغاء';

  @override
  String get send => 'إرسال';

  @override
  String get contribTitle => 'مساهماتي في الخريطة';

  @override
  String get recordTracks => 'تسجيل مساراتي';

  @override
  String get recordTracksHint => 'بدون أول وآخر 200 متر، وتبقى على جهازك';

  @override
  String contribCounts(String tracks, String issues) {
    return '$tracks مسار مسجّل · $issues ملاحظة';
  }

  @override
  String get exportData => 'تصدير (GeoJSON)';

  @override
  String get exported => 'نسخت البيانات، الصقها في ملف أو بريد';

  @override
  String get deleteAll => 'حذف الكل';

  @override
  String get voiceSearch => 'بحث بالصوت';

  @override
  String get voiceListening => 'تكلّم الآن…';

  @override
  String get voiceUnavailable =>
      'الميكروفون غير متاح. اسمح به من إعدادات المتصفح أو استخدم Safari.';

  @override
  String get voiceExample =>
      'جرّب: «ودّني أقرب بنزينة» أو «أقرب مسجد على طريقي»';

  @override
  String get share => 'مشاركة';

  @override
  String get shareTrip => 'مشاركة رحلتي';

  @override
  String shareTripText(String place, String eta, String link) {
    return 'أنا في الطريق إلى $place، أصل حوالي $eta.\nموقعي الآن: $link';
  }

  @override
  String get openInGoogle => 'في Google Maps';

  @override
  String get copied => 'تم النسخ';

  @override
  String get prayerTimes => 'أوقات الصلاة';

  @override
  String get prayerFajr => 'الفجر';

  @override
  String get prayerSunrise => 'الشروق';

  @override
  String get prayerDhuhr => 'الظهر';

  @override
  String get prayerAsr => 'العصر';

  @override
  String get prayerMaghrib => 'المغرب';

  @override
  String get prayerIsha => 'العشاء';

  @override
  String prayerNext(String name, String left) {
    return '$name بعد $left';
  }

  @override
  String get methodUmmAlQura =>
      'حسب تقويم أم القرى — قد تختلف دقيقة أو دقيقتين عن مسجدك';

  @override
  String get methodEgypt =>
      'حسب الهيئة المصرية العامة للمساحة — قد تختلف دقيقة أو دقيقتين';

  @override
  String get nearestMosque => 'أقرب مسجد';

  @override
  String stopAdded(String name) {
    return 'أضفنا محطة: $name';
  }

  @override
  String stopAddedSpeech(String name) {
    return 'أضفت $name على طريقك';
  }

  @override
  String get go => 'ابدأ';

  @override
  String get voiceDialect => 'لهجة التوجيه الصوتي';

  @override
  String get dialectSaudi => 'سعودي';

  @override
  String get dialectEgyptian => 'مصري';

  @override
  String get dialectStandard => 'فصحى';

  @override
  String get testVoice => 'جرّب الصوت';
}
