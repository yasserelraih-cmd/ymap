import 'package:material_ui/material_ui.dart';

/// تصنيفات البحث السريع حول موقعك.
enum PlaceCategory {
  restaurant(Icons.restaurant, 'مطعم', 'amenity:restaurant'),
  fuel(Icons.local_gas_station, 'محطة', 'amenity:fuel'),
  mosque(Icons.mosque, 'مسجد', 'amenity:place_of_worship'),
  pharmacy(Icons.local_pharmacy, 'صيدلية', 'amenity:pharmacy'),
  hospital(Icons.local_hospital, 'مستشفى', 'amenity:hospital'),
  bank(Icons.account_balance, 'بنك', 'amenity:bank');

  const PlaceCategory(this.icon, this.query, this.osmTag);

  final IconData icon;

  /// الكلمة التي نرسلها لمحرك البحث مع فلتر التصنيف.
  final String query;

  /// فلتر OpenStreetMap (المفتاح:القيمة).
  final String osmTag;

  /// كلمات يكتبها الناس وتعني هذا التصنيف (بعد التطبيع).
  static const _synonyms = <PlaceCategory, List<String>>{
    PlaceCategory.restaurant: ['مطعم', 'مطاعم', 'اكل', 'restaurant', 'restaurants', 'food'],
    PlaceCategory.fuel: [
      'بنزين', 'بنزينه', 'بنزينات', 'محطه', 'محطه وقود', 'محطات', 'وقود',
      'fuel', 'gas', 'gas station', 'petrol',
    ],
    PlaceCategory.mosque: ['مسجد', 'مساجد', 'جامع', 'مصلي', 'mosque', 'masjid'],
    PlaceCategory.pharmacy: ['صيدليه', 'صيدليات', 'pharmacy'],
    PlaceCategory.hospital: ['مستشفي', 'مستشفيات', 'طوارئ', 'hospital'],
    PlaceCategory.bank: ['بنك', 'بنوك', 'مصرف', 'bank'],
  };

  /// إذا كان النص اسماً عاماً لتصنيف (مثل «بنزين») يرجع التصنيف.
  static PlaceCategory? detect(String text) {
    final n = normalizeArabic(text);
    for (final entry in _synonyms.entries) {
      if (entry.value.contains(n)) return entry.key;
    }
    return null;
  }

  /// اسم أيقونة مناسبة لنوع المكان في النتائج.
  static IconData iconFor(String? osmKey, String? osmValue) {
    for (final c in PlaceCategory.values) {
      if (c.osmTag == '$osmKey:$osmValue') return c.icon;
    }
    return switch (osmKey) {
      'link' => Icons.link,
      'car' => Icons.directions_car,
      'railway' => Icons.subway,
      'highway' => Icons.signpost_outlined,
      'place' => Icons.location_city,
      'shop' => Icons.storefront,
      'tourism' => Icons.hotel,
      _ => Icons.place_outlined,
    };
  }
}

/// تطبيع النص العربي للمقارنة: إزالة التشكيل والتطويل،
/// توحيد الألف والتاء المربوطة والياء، وتصغير الحروف اللاتينية.
String normalizeArabic(String input) {
  var s = input.trim().toLowerCase();
  s = s.replaceAll(RegExp('[ً-ٰٟـ]'), '');
  s = s.replaceAll(RegExp('[أإآٱ]'), 'ا');
  s = s.replaceAll('ة', 'ه');
  s = s.replaceAll('ى', 'ي');
  s = s.replaceAll(RegExp(r'^ال(?=\S{3,})'), '');
  s = s.replaceAll(RegExp(r'\s+'), ' ');
  return s;
}
