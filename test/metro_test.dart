import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ymap/search/metro_stations.dart';

void main() {
  final g = jsonDecode(File('assets/data/riyadh_metro.geojson').readAsStringSync())
      as Map<String, dynamic>;

  test('ملف المترو فيه 6 خطوط وأكثر من 70 محطة', () {
    final lines = (g['features'] as List).where((f) => f['properties']['kind'] == 'line');
    expect(lines.length, 6);
    final m = MetroStations.fromGeoJson(g);
    expect(m.search('مترو', nearLat: 24.69, nearLon: 46.68).length, 8);
  });

  test('البحث باسم المحطة والأقرب', () {
    final m = MetroStations.fromGeoJson(g);
    final r = m.search('الحلة', nearLat: 24.69, nearLon: 46.68);
    expect(r, isNotEmpty);
    expect(r.first.name, contains('الحلة'));
    expect(r.first.subtitle, contains('البرتقالي'));
    expect(MetroStations.isGenericQuery('أقرب محطة مترو'), isTrue);
    expect(MetroStations.isGenericQuery('مطعم البيك'), isFalse);
  });
}
