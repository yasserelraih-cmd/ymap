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
      'لم تسمح لـYMAP بالوصول لموقعك. فعّله من إعدادات الجوال.';

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
}
