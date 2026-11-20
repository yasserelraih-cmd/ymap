import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ymap/routing/routing_service.dart';

void main() {
  test('وضع المشي يرسل pedestrian وتبقى السيارة auto', () async {
    final fixture = File('test/fixtures/valhalla_route.json').readAsStringSync();
    final costings = <String>[];
    final client = MockClient((req) async {
      final body = jsonDecode(req.url.queryParameters['json']!) as Map;
      costings.add(body['costing'] as String);
      return http.Response(fixture, 200,
          headers: {'content-type': 'application/json; charset=utf-8'});
    });
    final svc = ValhallaRoutingService(client: client);
    await svc.route(fromLat: 24.69, fromLon: 46.68, toLat: 24.77, toLon: 46.73);
    await svc.route(
        fromLat: 24.69, fromLon: 46.68, toLat: 24.77, toLon: 46.73,
        mode: TravelMode.walk);
    expect(costings, ['auto', 'pedestrian']);
  });
}
