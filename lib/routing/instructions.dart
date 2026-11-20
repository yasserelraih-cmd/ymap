import 'package:material_ui/material_ui.dart';

import 'route.dart';

/// نصوص تعليمات YMAP الخاصة (عربي وإنجليزي) وأيقونة كل التفافة.
/// لا نستخدم نصوص الخادم لأن عربيتها ناقصة ومخلوطة بالإنجليزية.
/// لهجة التوجيه الصوتي.
enum VoiceDialect {
  saudi,
  egyptian,
  standard;

  static VoiceDialect fromCode(String? c) => switch (c) {
        'eg' => egyptian,
        'msa' => standard,
        _ => saudi,
      };

  String get code => switch (this) {
        saudi => 'sa',
        egyptian => 'eg',
        standard => 'msa',
      };

  String get start => switch (this) {
        saudi => 'يلا نمشي.',
        egyptian => 'يلا بينا.',
        standard => 'لنبدأ.',
      };

  String get arrived => switch (this) {
        saudi => 'وصلت، الحمد لله على السلامة',
        egyptian => 'وصلت، حمد الله على السلامة',
        standard => 'وصلت إلى وجهتك',
      };

  String get reroute => switch (this) {
        saudi => 'طلعت عن الطريق، أحسب لك طريق ثاني',
        egyptian => 'خرجت عن الطريق، بحسبلك طريق تاني',
        standard => 'خرجت عن المسار، جارٍ إعادة الحساب',
      };
}

class Instructions {
  /// الجملة المنطوقة بالعربي حسب اللهجة (قصيرة وطبيعية).
  /// الإنجليزية والفصحى تستخدمان [text].
  static String spoken(Maneuver m, String lang, VoiceDialect d) {
    if (lang != 'ar' || d == VoiceDialect.standard) return text(m, lang);
    final s = street(m, lang);
    final sa = d == VoiceDialect.saudi;
    String on(String base) => s == null ? base : '$base على $s';
    String ord(int n) => sa
        ? _ordinalAr(n)
        : switch (n) {
            1 => 'الأول',
            2 => 'التاني',
            3 => 'التالت',
            4 => 'الرابع',
            5 => 'الخامس',
            _ => 'رقم $n',
          };
    switch (m.type) {
      case 1:
      case 2:
      case 3:
        return on(sa ? 'امشِ' : 'اطلع');
      case 4:
        return d.arrived;
      case 5:
        return sa ? 'وجهتك على يمينك' : 'المكان على إيدك اليمين';
      case 6:
        return sa ? 'وجهتك على يسارك' : 'المكان على إيدك الشمال';
      case 9:
        return on(sa ? 'ميّل يمين' : 'خليك يمين شوية');
      case 10:
        return on(sa ? 'لف يمين' : 'خش يمين');
      case 11:
        return on(sa ? 'لف يمين على طول' : 'لف يمين خالص');
      case 12:
      case 13:
        return sa ? 'سو يوتيرن' : 'لف وارجع';
      case 14:
        return on(sa ? 'لف يسار على طول' : 'لف شمال خالص');
      case 15:
        return on(sa ? 'لف يسار' : 'خش شمال');
      case 16:
        return on(sa ? 'ميّل يسار' : 'خليك شمال شوية');
      case 17:
        return on(sa ? 'خذ المدخل اللي قدامك' : 'خد المطلع اللي قدامك');
      case 18:
      case 20:
        return on(sa ? 'اطلع من المخرج اللي على يمينك' : 'اطلع من المخرج اللي على اليمين');
      case 19:
      case 21:
        return on(sa ? 'اطلع من المخرج اللي على يسارك' : 'اطلع من المخرج اللي على الشمال');
      case 23:
        return on(sa ? 'خلك يمين' : 'خليك يمين');
      case 24:
        return on(sa ? 'خلك يسار' : 'خليك شمال');
      case 25:
      case 37:
      case 38:
        return on(sa ? 'ادخل الطريق' : 'ادخل على الطريق');
      case 26:
        final n = m.roundaboutExit;
        if (n != null && n > 0) {
          return sa ? 'في الدوار خذ المخرج ${ord(n)}' : 'في الدوران خد المخرج ${ord(n)}';
        }
        return sa ? 'ادخل الدوار' : 'ادخل الدوران';
      case 27:
        return on(sa ? 'اطلع من الدوار' : 'اطلع من الدوران');
      default:
        return on(sa ? 'كمّل سيدا' : 'كمّل على طول');
    }
  }

  static final _arabic = RegExp('[؀-ۿ]');

  /// اسم الشارع بلغة التطبيق (Valhalla يرسل الاسم العربي والإنجليزي معاً).
  static String? street(Maneuver m, String lang) {
    if (m.streetNames.isEmpty) return null;
    final ar = m.streetNames.where(_arabic.hasMatch);
    final en = m.streetNames.where((s) => !_arabic.hasMatch(s));
    if (lang == 'ar') return ar.isNotEmpty ? ar.first : m.streetNames.first;
    return en.isNotEmpty ? en.first : m.streetNames.first;
  }

  static String text(Maneuver m, String lang) {
    final s = street(m, lang);
    final ar = lang == 'ar';
    String to(String base) =>
        s == null ? base : (ar ? '$base إلى $s' : '$base onto $s');
    String on(String base) =>
        s == null ? base : (ar ? '$base على $s' : '$base on $s');

    switch (m.type) {
      case 1:
      case 2:
      case 3:
        return on(ar ? 'انطلق' : 'Head out');
      case 4:
        return ar ? 'وصلت إلى وجهتك' : 'You have arrived';
      case 5:
        return ar ? 'وجهتك على اليمين' : 'Your destination is on the right';
      case 6:
        return ar ? 'وجهتك على اليسار' : 'Your destination is on the left';
      case 9:
        return to(ar ? 'انعطف قليلاً لليمين' : 'Bear right');
      case 10:
        return to(ar ? 'انعطف يميناً' : 'Turn right');
      case 11:
        return to(ar ? 'انعطف يميناً بحدة' : 'Turn sharp right');
      case 12:
      case 13:
        return to(ar ? 'ارجع بالدوران للخلف' : 'Make a U-turn');
      case 14:
        return to(ar ? 'انعطف يساراً بحدة' : 'Turn sharp left');
      case 15:
        return to(ar ? 'انعطف يساراً' : 'Turn left');
      case 16:
        return to(ar ? 'انعطف قليلاً لليسار' : 'Bear left');
      case 17:
        return to(ar ? 'خذ المنحدر للأمام' : 'Take the ramp straight ahead');
      case 18:
        return to(ar ? 'خذ المنحدر على اليمين' : 'Take the ramp on the right');
      case 19:
        return to(ar ? 'خذ المنحدر على اليسار' : 'Take the ramp on the left');
      case 20:
        return to(ar ? 'اخرج من المخرج على اليمين' : 'Take the exit on the right');
      case 21:
        return to(ar ? 'اخرج من المخرج على اليسار' : 'Take the exit on the left');
      case 23:
        return to(ar ? 'التزم اليمين' : 'Keep right');
      case 24:
        return to(ar ? 'التزم اليسار' : 'Keep left');
      case 25:
      case 37:
      case 38:
        return to(ar ? 'اندمج في الطريق' : 'Merge');
      case 26:
        final n = m.roundaboutExit;
        if (n != null && n > 0) {
          return ar
              ? 'في الدوار خذ المخرج ${_ordinalAr(n)}'
              : 'At the roundabout, take exit $n';
        }
        return ar ? 'ادخل الدوار' : 'Enter the roundabout';
      case 27:
        return to(ar ? 'اخرج من الدوار' : 'Exit the roundabout');
      default:
        return on(ar ? 'استمر' : 'Continue');
    }
  }

  static IconData icon(Maneuver m) => switch (m.type) {
        1 || 2 || 3 => Icons.trip_origin,
        4 || 5 || 6 => Icons.flag,
        9 => Icons.turn_slight_right,
        10 => Icons.turn_right,
        11 => Icons.turn_sharp_right,
        12 => Icons.u_turn_right,
        13 => Icons.u_turn_left,
        14 => Icons.turn_sharp_left,
        15 => Icons.turn_left,
        16 => Icons.turn_slight_left,
        18 || 20 || 23 => Icons.fork_right,
        19 || 21 || 24 => Icons.fork_left,
        25 || 37 || 38 => Icons.merge,
        26 || 27 => Icons.roundabout_right,
        _ => Icons.straight,
      };

  static String _ordinalAr(int n) => switch (n) {
        1 => 'الأول',
        2 => 'الثاني',
        3 => 'الثالث',
        4 => 'الرابع',
        5 => 'الخامس',
        _ => 'رقم $n',
      };
}
