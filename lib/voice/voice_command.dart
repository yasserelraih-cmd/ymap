import '../search/categories.dart';

/// أمر صوتي مفهوم مثل: «ودّني أقرب بنزينة على طريقي».
class VoiceCommand {
  const VoiceCommand({
    required this.query,
    this.category,
    this.navigate = false,
    this.nearest = false,
    this.alongRoute = false,
  });

  /// النص الباقي بعد حذف كلمات الأمر (مثل «العليا مول»).
  final String query;

  /// تصنيف عام إن وُجد (بنزينة، مسجد، صيدلية…).
  final PlaceCategory? category;

  /// يريد الذهاب مباشرة (ودّني، خذني، روح…).
  final bool navigate;

  /// «أقرب».
  final bool nearest;

  /// «على طريقي / في طريقي».
  final bool alongRoute;

  static final _navVerbs = [
    'ودني', 'وديني', 'وصلني', 'وصليني', 'خذني', 'خدني', 'روح', 'روحني',
    'اذهب', 'اذهب الي', 'ابغي اروح', 'ابي اروح', 'عايز اروح', 'عاوز اروح',
    'دلني علي', 'دلني', 'نوديني', 'take me to', 'navigate to',
    'go to', 'drive to', 'directions to',
  ];
  static final _fillers = [
    'الي', 'لـ', 'علي', 'عند', 'فين', 'وين', 'لو سمحت', 'من فضلك', 'يا',
    'to', 'the', 'please',
  ];
  static final _nearestWords = ['اقرب', 'قريب', 'قريبه', 'جنبي', 'nearest', 'closest', 'near me', 'nearby'];
  static final _routeWords = [
    'علي طريقي', 'في طريقي', 'علي الطريق', 'في الطريق', 'بطريقي',
    'on my way', 'on my route', 'along the way',
  ];

  static VoiceCommand parse(String spoken) {
    var s = ' ${normalizeArabic(spoken)} ';
    // التطبيع يحذف «ال» من أول كلمة فقط؛ نوحّد الباقي للمطابقة.
    bool take(List<String> words) {
      var found = false;
      for (final w in words) {
        final n = ' ${normalizeArabic(w)} ';
        if (s.contains(n)) {
          s = s.replaceAll(n, ' ');
          found = true;
        }
      }
      return found;
    }

    final alongRoute = take(_routeWords);
    final navigate = take(_navVerbs);
    final nearest = take(_nearestWords);
    // «ل» ملتصقة: «لصيدلية» → «صيدلية»
    s = s.replaceAllMapped(RegExp(r' ل(?=\S{3,})'), (_) => ' ');
    take(_fillers);
    final rest = s.trim().replaceAll(RegExp(r'\s+'), ' ');

    PlaceCategory? category = PlaceCategory.detect(rest);
    if (category == null) {
      // جرّب كلمة كلمة: «بنزينة قريبة» أو «مسجد الراجحي» يبقى بحثاً عادياً.
      final words = rest.split(' ');
      if (words.length == 1) {
        category = PlaceCategory.detect(words.first.replaceFirst(RegExp(r'^ال'), ''));
      }
    }
    return VoiceCommand(
      query: rest,
      category: category,
      navigate: navigate || alongRoute,
      nearest: nearest || alongRoute,
      alongRoute: alongRoute,
    );
  }
}
