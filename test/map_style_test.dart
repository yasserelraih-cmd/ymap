import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ymap/map/map_style.dart';

Map<String, dynamic> _style({required bool withBuildings}) => {
      'version': 8,
      'sources': {},
      'layers': [
        {'id': 'bg', 'type': 'background'},
        if (withBuildings)
          {
            'id': 'building-3d',
            'type': 'fill-extrusion',
            'paint': {'fill-extrusion-height': 10, 'fill-extrusion-base': 0},
          },
        {
          'id': 'road-label',
          'type': 'symbol',
          'layout': {
            'text-field': ['coalesce', ['get', 'name_en'], ['get', 'name']],
          },
        },
        {
          'id': 'shield',
          'type': 'symbol',
          'layout': {
            'text-field': ['to-string', ['get', 'ref']],
          },
        },
      ],
    };

void main() {
  final client = MockClient((req) async {
    final dark = req.url.path.endsWith('/dark');
    return http.Response(jsonEncode(_style(withBuildings: !dark)), 200);
  });

  List<Map<String, dynamic>> layersOf(String json) =>
      ((jsonDecode(json) as Map)['layers'] as List).cast<Map<String, dynamic>>();

  test('العربية: أسماء name:ar أولاً، وأرقام الطرق كما هي', () async {
    final loader = MapStyleLoader(client: client);
    final layers = layersOf(await loader.load(dark: false, languageCode: 'ar'));
    final road = layers.firstWhere((l) => l['id'] == 'road-label');
    expect(road['layout']['text-field'][1], ['get', 'name:ar']);
    final shield = layers.firstWhere((l) => l['id'] == 'shield');
    expect(shield['layout']['text-field'], ['to-string', ['get', 'ref']]);
  });

  test('الإنجليزية: name:en أولاً', () async {
    final loader = MapStyleLoader(client: client);
    final layers = layersOf(await loader.load(dark: false, languageCode: 'en'));
    final road = layers.firstWhere((l) => l['id'] == 'road-label');
    expect(road['layout']['text-field'][1], ['get', 'name:en']);
  });

  test('الليلي: تُضاف المباني 3D قبل طبقات النصوص', () async {
    final loader = MapStyleLoader(client: client);
    final layers = layersOf(await loader.load(dark: true, languageCode: 'ar'));
    final ids = layers.map((l) => l['id']).toList();
    expect(ids, contains('building-3d'));
    expect(ids.indexOf('building-3d'), lessThan(ids.indexOf('road-label')));
  });
}
