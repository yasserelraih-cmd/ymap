import 'dart:convert';

/// مكان واحد من نتائج البحث.
class Place {
  const Place({
    required this.name,
    required this.subtitle,
    required this.lat,
    required this.lon,
    this.osmKey,
    this.osmValue,
  });

  final String name;
  final String subtitle;
  final double lat;
  final double lon;
  final String? osmKey;
  final String? osmValue;

  /// يبني المكان من نتيجة Photon (GeoJSON Feature).
  static Place? fromPhoton(Map<String, dynamic> feature) {
    final props = (feature['properties'] as Map?)?.cast<String, dynamic>() ?? {};
    final coords = (feature['geometry'] as Map?)?['coordinates'] as List?;
    if (coords == null || coords.length < 2) return null;
    final street = props['street'] as String?;
    final district = props['district'] as String? ?? props['locality'] as String?;
    final city = props['city'] as String? ?? props['county'] as String?;
    final name = (props['name'] as String?) ?? street ?? district ?? city;
    if (name == null || name.trim().isEmpty) return null;
    final parts = <String>[
      if (street != null && street != name) street,
      if (district != null && district != name) district,
      if (city != null && city != name) city,
      if (props['country'] is String && props['country'] != name)
        props['country'] as String,
    ];
    return Place(
      name: name.trim(),
      subtitle: parts.join('، '),
      lat: (coords[1] as num).toDouble(),
      lon: (coords[0] as num).toDouble(),
      osmKey: props['osm_key'] as String?,
      osmValue: props['osm_value'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'subtitle': subtitle,
        'lat': lat,
        'lon': lon,
        'osmKey': osmKey,
        'osmValue': osmValue,
      };

  static Place fromJson(Map<String, dynamic> j) => Place(
        name: j['name'] as String,
        subtitle: j['subtitle'] as String? ?? '',
        lat: (j['lat'] as num).toDouble(),
        lon: (j['lon'] as num).toDouble(),
        osmKey: j['osmKey'] as String?,
        osmValue: j['osmValue'] as String?,
      );

  /// مفتاح لمنع التكرار في النتائج والسجل.
  String get key => '$name|${lat.toStringAsFixed(4)}|${lon.toStringAsFixed(4)}';

  @override
  String toString() => jsonEncode(toJson());
}
