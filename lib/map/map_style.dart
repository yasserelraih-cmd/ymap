import 'dart:convert';

import 'package:http/http.dart' as http;

/// يجهّز تصميم الخريطة (Style) من OpenFreeMap المجاني ويعدّله لـYMAP:
/// - أسماء الشوارع والأماكن بلغة التطبيق (عربي أو إنجليزي).
/// - تصميم نهاري أو ليلي.
/// - مبانٍ ثلاثية الأبعاد في الوضعين.
class MapStyleLoader {
  MapStyleLoader({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  final Map<String, Map<String, dynamic>> _baseCache = {};

  static const _dayUrl = 'https://tiles.openfreemap.org/styles/liberty';
  static const _nightUrl = 'https://tiles.openfreemap.org/styles/dark';

  /// يرجع تصميم الخريطة كنص JSON جاهز لـMapLibre.
  Future<String> load({required bool dark, required String languageCode}) async {
    final day = await _base(_dayUrl);
    final base = dark ? await _base(_nightUrl) : day;
    final style = jsonDecode(jsonEncode(base)) as Map<String, dynamic>;
    final layers = (style['layers'] as List).cast<Map<String, dynamic>>();

    for (final layer in layers) {
      final layout = layer['layout'];
      if (layout is Map<String, dynamic> && _usesName(layout['text-field'])) {
        layout['text-field'] = _nameExpression(languageCode);
        if (dark) {
          // نصوص أوضح في الوضع الليلي.
          final paint = (layer['paint'] as Map<String, dynamic>?) ?? {};
          paint['text-color'] = '#c9d8da';
          paint['text-halo-color'] = '#0f1a1c';
          paint['text-halo-width'] = 1.2;
          layer['paint'] = paint;
        }
      }
    }

    if (dark && !layers.any((l) => l['type'] == 'fill-extrusion')) {
      final building3d = (day['layers'] as List)
          .cast<Map<String, dynamic>>()
          .where((l) => l['id'] == 'building-3d')
          .map((l) => jsonDecode(jsonEncode(l)) as Map<String, dynamic>)
          .firstOrNull;
      if (building3d != null) {
        building3d['paint'] = {
          'fill-extrusion-color': '#24363a',
          'fill-extrusion-height': building3d['paint']?['fill-extrusion-height'],
          'fill-extrusion-base': building3d['paint']?['fill-extrusion-base'],
          'fill-extrusion-opacity': 0.85,
        };
        final firstSymbol = layers.indexWhere((l) => l['type'] == 'symbol');
        layers.insert(firstSymbol < 0 ? layers.length : firstSymbol, building3d);
      }
    }
    return jsonEncode(style);
  }

  Future<Map<String, dynamic>> _base(String url) async {
    final cached = _baseCache[url];
    if (cached != null) return cached;
    final res = await _client.get(Uri.parse(url));
    if (res.statusCode != 200) {
      throw MapStyleException('HTTP ${res.statusCode}');
    }
    final json = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    _baseCache[url] = json;
    return json;
  }

  static bool _usesName(Object? textField) =>
      textField != null && jsonEncode(textField).contains('name');

  /// العربية: name:ar ثم الاسم المحلي. الإنجليزية: name:en ثم اللاتيني ثم المحلي.
  static List<Object> _nameExpression(String languageCode) => languageCode == 'en'
      ? [
          'coalesce',
          ['get', 'name:en'],
          ['get', 'name_en'],
          ['get', 'name:latin'],
          ['get', 'name'],
        ]
      : [
          'coalesce',
          ['get', 'name:ar'],
          ['get', 'name'],
        ];
}

class MapStyleException implements Exception {
  MapStyleException(this.message);
  final String message;
  @override
  String toString() => 'MapStyleException: $message';
}
