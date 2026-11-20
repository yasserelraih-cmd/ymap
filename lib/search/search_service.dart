import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import 'categories.dart';
import 'place.dart';

/// واجهة البحث (لتسهيل الاختبار واستبدال المحرك لاحقاً بخادم YMAP الخاص).
abstract class SearchService {
  Future<List<Place>> search(
    String query, {
    required String languageCode,
    required double nearLat,
    required double nearLon,
  });

  Future<List<Place>> nearby(
    PlaceCategory category, {
    required double nearLat,
    required double nearLon,
  });
}

/// البحث عبر Photon العام (مبني على OpenStreetMap).
/// مناسب للتجربة الشخصية؛ قبل النشر العام نستضيف محرك بحث خاصاً بـYMAP.
class PhotonSearchService implements SearchService {
  PhotonSearchService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static const _endpoint = 'https://photon.komoot.io/api/';

  /// أبعد مسافة نعرضها في بحث «حولك» بالتصنيفات.
  static const nearbyRadiusKm = 30.0;

  @override
  Future<List<Place>> search(
    String query, {
    required String languageCode,
    required double nearLat,
    required double nearLon,
  }) async {
    final q = query.trim();
    if (q.isEmpty) return const [];
    final category = PlaceCategory.detect(q);
    if (category != null) {
      return nearby(category, nearLat: nearLat, nearLon: nearLon);
    }
    final places = await _get({
      'q': q,
      'lat': '$nearLat',
      'lon': '$nearLon',
      'limit': '15',
      // Photon يدعم default/en/de/fr/it: «default» يعطي الأسماء المحلية (عربية).
      if (languageCode == 'en') 'lang': 'en',
    });
    return _dedupe(places);
  }

  @override
  Future<List<Place>> nearby(
    PlaceCategory category, {
    required double nearLat,
    required double nearLon,
  }) async {
    final places = await _get({
      'q': category.query,
      'osm_tag': category.osmTag,
      'lat': '$nearLat',
      'lon': '$nearLon',
      'zoom': '14',
      'location_bias_scale': '0.1',
      'limit': '30',
    });
    final near = _dedupe(places)
        .where((p) => distanceKm(nearLat, nearLon, p.lat, p.lon) <= nearbyRadiusKm)
        .toList()
      ..sort((a, b) => distanceKm(nearLat, nearLon, a.lat, a.lon)
          .compareTo(distanceKm(nearLat, nearLon, b.lat, b.lon)));
    return near.take(20).toList();
  }

  Future<List<Place>> _get(Map<String, String> params) async {
    final uri = Uri.parse(_endpoint).replace(queryParameters: params);
    final res = await _client.get(uri).timeout(const Duration(seconds: 12));
    if (res.statusCode != 200) {
      throw SearchException('HTTP ${res.statusCode}');
    }
    final json = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    final features = (json['features'] as List?) ?? const [];
    return features
        .whereType<Map<String, dynamic>>()
        .map(Place.fromPhoton)
        .whereType<Place>()
        .toList();
  }

  static List<Place> _dedupe(List<Place> places) {
    final seen = <String>{};
    return [
      for (final p in places)
        if (seen.add('${p.name}|${p.lat.toStringAsFixed(3)}|${p.lon.toStringAsFixed(3)}')) p,
    ];
  }
}

double distanceKm(double lat1, double lon1, double lat2, double lon2) =>
    Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000;

class SearchException implements Exception {
  SearchException(this.message);
  final String message;
  @override
  String toString() => 'SearchException: $message';
}
