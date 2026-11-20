import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'place.dart';

/// آخر الأماكن التي اخترتها من البحث (تُحفظ على جهازك فقط).
class RecentSearches {
  static const _key = 'recent_places';
  static const maxItems = 10;

  Future<List<Place>> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(_key) ?? const [];
      return [
        for (final s in raw) Place.fromJson(jsonDecode(s) as Map<String, dynamic>),
      ];
    } catch (_) {
      return const [];
    }
  }

  Future<void> add(Place place) async {
    final current = await load();
    final updated = [
      place,
      ...current.where((p) => p.key != place.key),
    ].take(maxItems).toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _key,
      [for (final p in updated) jsonEncode(p.toJson())],
    );
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
