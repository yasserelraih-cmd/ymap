import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import 'categories.dart';
import 'place.dart';
import 'search_service.dart';

/// محطات مترو الرياض محلياً (بدون إنترنت) من ملف البيانات المرفق.
class MetroStations {
  MetroStations._(this._all);

  final List<Place> _all;
  static MetroStations? _cache;

  static const lineNamesAr = {
    '1': 'الأزرق',
    '2': 'الأحمر',
    '3': 'البرتقالي',
    '4': 'الأصفر',
    '5': 'الأخضر',
    '6': 'البنفسجي',
  };
  static const lineNamesEn = {
    '1': 'Blue',
    '2': 'Red',
    '3': 'Orange',
    '4': 'Yellow',
    '5': 'Green',
    '6': 'Purple',
  };

  static Future<MetroStations> load({String lang = 'ar'}) async {
    final c = _cache;
    if (c != null) return c;
    try {
      final raw = await rootBundle.loadString('assets/data/riyadh_metro.geojson');
      return _cache = MetroStations.fromGeoJson(jsonDecode(raw) as Map<String, dynamic>, lang: lang);
    } catch (_) {
      return MetroStations._(const []);
    }
  }

  static MetroStations fromGeoJson(Map<String, dynamic> g, {String lang = 'ar'}) {
    final out = <Place>[];
    for (final f in (g['features'] as List)) {
      final p = f['properties'] as Map<String, dynamic>;
      if (p['kind'] != 'stop' || p['construction'] == true) continue;
      final c = f['geometry']['coordinates'] as List;
      final lines = [for (final l in (p['lines'] as List? ?? const [])) '$l'];
      final ar = lang == 'ar';
      final names = ar ? lineNamesAr : lineNamesEn;
      final lineText = lines.map((l) => names[l] ?? l).join(ar ? ' و' : ' & ');
      out.add(Place(
        name: ar ? 'محطة ${p['name_ar']}' : '${p['name_en'] ?? p['name_ar']} Station',
        subtitle: ar ? 'مترو الرياض – المسار $lineText' : 'Riyadh Metro – $lineText Line',
        lat: (c[1] as num).toDouble(),
        lon: (c[0] as num).toDouble(),
        osmKey: 'railway',
        osmValue: 'station',
      ));
    }
    return MetroStations._(out);
  }

  static final _metroWords = RegExp(r'(مترو|محطه|محطة|metro|station|subway)', caseSensitive: false);

  /// هل يسأل عن المترو عموماً («مترو»، «أقرب محطة مترو»)؟
  static bool isGenericQuery(String q) {
    final n = normalizeArabic(q).replaceAll(RegExp(r'(اقرب|قريب|nearest)'), '').trim();
    // «محطة» وحدها تعني بنزينة غالباً؛ نشترط ذكر المترو.
    if (!RegExp(r'(مترو|metro|subway)', caseSensitive: false).hasMatch(n)) return false;
    return n.replaceAll(_metroWords, '').trim().isEmpty;
  }

  /// يبحث بالاسم أو يرجع الأقرب إن كان السؤال عاماً عن المترو.
  List<Place> search(String q, {required double nearLat, required double nearLon}) {
    if (_all.isEmpty) return const [];
    if (isGenericQuery(q)) {
      final sorted = [..._all]..sort((a, b) => distanceKm(nearLat, nearLon, a.lat, a.lon)
          .compareTo(distanceKm(nearLat, nearLon, b.lat, b.lon)));
      return sorted.take(8).toList();
    }
    final n = normalizeArabic(q.replaceAll(_metroWords, '')).trim();
    if (n.length < 2) return const [];
    return _all
        .where((p) => normalizeArabic(p.name).contains(n) || p.name.toLowerCase().contains(n.toLowerCase()))
        .take(5)
        .toList();
  }
}
