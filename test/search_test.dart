import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ymap/app.dart';
import 'package:ymap/screens/home_screen.dart';
import 'package:ymap/search/categories.dart';
import 'package:ymap/search/location_link.dart';
import 'package:ymap/search/place.dart';
import 'package:ymap/search/search_service.dart';
import 'package:ymap/state/settings_controller.dart';
import 'package:ymap/widgets/place_card.dart';

Map<String, dynamic> _feature(String name, double lat, double lon,
        {String key = 'place', String value = 'suburb'}) =>
    {
      'type': 'Feature',
      'geometry': {
        'type': 'Point',
        'coordinates': [lon, lat],
      },
      'properties': {
        'name': name,
        'city': 'الرياض',
        'country': 'السعودية',
        'osm_key': key,
        'osm_value': value,
      },
    };

class FakeSearch implements SearchService {
  final queries = <String>[];

  @override
  Future<List<Place>> search(String query,
      {required String languageCode,
      required double nearLat,
      required double nearLon}) async {
    queries.add(query);
    return [Place.fromPhoton(_feature('العليا', 24.69, 46.68))!];
  }

  @override
  Future<List<Place>> nearby(PlaceCategory category,
          {required double nearLat, required double nearLon}) async =>
      [Place.fromPhoton(_feature('محطة ساسكو', 24.70, 46.69,
          key: 'amenity', value: 'fuel'))!];
}

void main() {
  group('تطبيع العربي والتصنيفات', () {
    test('توحيد الألف والتاء المربوطة والتشكيل', () {
      expect(normalizeArabic('  الصَّيْدَلِيَّة '), 'صيدليه');
      expect(normalizeArabic('أبها'), 'ابها');
      expect(normalizeArabic('مستشفى'), 'مستشفي');
    });

    test('كلمات عامة تتحول لبحث تصنيف حولك', () {
      expect(PlaceCategory.detect('بنزين'), PlaceCategory.fuel);
      expect(PlaceCategory.detect('بنزينة'), PlaceCategory.fuel);
      expect(PlaceCategory.detect('جامع'), PlaceCategory.mosque);
      expect(PlaceCategory.detect('Pharmacy'), PlaceCategory.pharmacy);
      expect(PlaceCategory.detect('العليا'), isNull);
    });
  });

  group('روابط المواقع والإحداثيات', () {
    test('رابط Google لمكان (‎!3d!4d أدق من @)', () {
      final p = LocationLink.parse(
          'https://www.google.com/maps/place/Kingdom+Centre/@24.7100,46.6700,17z/data=!3m1!4b1!4m6!3m5!1s0x0:0x0!8m2!3d24.711667!4d46.674444');
      expect(p!.name, 'Kingdom Centre');
      expect(p.lat, closeTo(24.711667, 1e-6));
      expect(p.lon, closeTo(46.674444, 1e-6));
    });

    test('روابط q= و query= و Apple ll= و geo:', () {
      expect(LocationLink.parse('https://maps.google.com/?q=24.6907,46.6851')!.lat,
          closeTo(24.6907, 1e-6));
      expect(LocationLink.parse(
              'https://www.google.com/maps/search/?api=1&query=24.5,46.5')!.lon,
          closeTo(46.5, 1e-6));
      expect(LocationLink.parse('https://maps.apple.com/?ll=24.1,46.2&q=Home')!.lat,
          closeTo(24.1, 1e-6));
      expect(LocationLink.parse('geo:24.3,46.4')!.lon, closeTo(46.4, 1e-6));
    });

    test('إحداثيات مكتوبة بأرقام عربية أو غربية', () {
      expect(LocationLink.parse('24.6907, 46.6851')!.lon, closeTo(46.6851, 1e-6));
      expect(LocationLink.parse('٢٤٫٦٩٠٧، ٤٦٫٦٨٥١')!.lat, closeTo(24.6907, 1e-6));
    });

    test('الرابط المختصر يُعرف، والنص العادي ليس موقعاً', () {
      expect(LocationLink.isShortLink('https://maps.app.goo.gl/AbCdEf123'), isTrue);
      expect(LocationLink.parse('مطعم البيك'), isNull);
      expect(LocationLink.parse('العليا'), isNull);
    });
  });

  group('Photon', () {
    test('قراءة النتائج وحذف المكرر', () async {
      late Uri seen;
      final client = MockClient((req) async {
        seen = req.url;
        return http.Response(
            jsonEncode({
              'features': [
                _feature('العليا', 24.69, 46.68),
                _feature('العليا', 24.69, 46.68), // مكرر
                _feature('شارع العليا', 24.70, 46.67,
                    key: 'highway', value: 'primary'),
              ],
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'});
      });
      final service = PhotonSearchService(client: client);
      final results = await service.search('العليا',
          languageCode: 'ar', nearLat: 24.7, nearLon: 46.7);
      expect(results.map((p) => p.name), ['العليا', 'شارع العليا']);
      expect(results.first.subtitle, 'الرياض، السعودية');
      expect(seen.queryParameters['q'], 'العليا');
      expect(seen.queryParameters.containsKey('lang'), isFalse);
    });

    test('بحث «بنزين» يرسل فلتر محطات الوقود ويرتب بالأقرب', () async {
      late Uri seen;
      final client = MockClient((req) async {
        seen = req.url;
        return http.Response(
            jsonEncode({
              'features': [
                _feature('بعيدة', 24.80, 46.80, key: 'amenity', value: 'fuel'),
                _feature('قريبة', 24.701, 46.701, key: 'amenity', value: 'fuel'),
                _feature('في جدة', 21.5, 39.2, key: 'amenity', value: 'fuel'),
              ],
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'});
      });
      final service = PhotonSearchService(client: client);
      final results = await service.search('بنزين',
          languageCode: 'ar', nearLat: 24.7, nearLon: 46.7);
      expect(seen.queryParameters['osm_tag'], 'amenity:fuel');
      expect(results.map((p) => p.name), ['قريبة', 'بعيدة']);
    });
  });

  testWidgets('البحث من الشاشة الرئيسية حتى بطاقة المكان', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final settings = SettingsController();
    await settings.load();
    await settings.setLanguage('ar');
    final fake = FakeSearch();
    await tester.pumpWidget(YmapApp(
      settings: settings,
      searchService: fake,
      mapBuilder: (context, key, isTablet, onMessage) => const MapPlaceholder(),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();
    expect(find.text('حولك'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'العليا');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(fake.queries, ['العليا']);

    await tester.tap(find.text('العليا').last);
    await tester.pumpAndSettle();
    expect(find.byType(PlaceCard), findsOneWidget);
    expect(find.text('المسار'), findsOneWidget);
  });
}
