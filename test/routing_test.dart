import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ymap/l10n/app_localizations.dart';
import 'package:ymap/map/ymap_map.dart';
import 'package:ymap/routing/instructions.dart';
import 'package:ymap/routing/route.dart';
import 'package:ymap/routing/routing_service.dart';
import 'package:ymap/search/place.dart';
import 'package:ymap/widgets/route_card.dart';

void main() {
  // رد حقيقي من Valhalla: من الملز إلى شمال الرياض (مع بديلين).
  final fixture = jsonDecode(
          File('test/fixtures/valhalla_route.json').readAsStringSync())
      as Map<String, dynamic>;

  test('فك ترميز خط المسار (دقة 6)', () {
    // "_izlhA~rlgdF_{geC~ywl@_kwzCn`{nI" = ثلاث نقاط معروفة من توثيق Valhalla/OSRM.
    final pts = decodePolyline6('_izlhA~rlgdF_{geC~ywl@_kwzCn`{nI');
    expect(pts.length, 3);
    expect(pts.first.lat, closeTo(38.5, 1e-6));
    expect(pts.first.lon, closeTo(-120.2, 1e-6));
    expect(pts.last.lat, closeTo(43.252, 1e-6));
  });

  test('إطار الكاميرا يبقى في الرياض ويرتفع فوق البطاقة السفلية', () {
    final cam = fitBounds(
      minLat: 24.69, minLon: 46.68, maxLat: 24.78, maxLon: 46.74,
      width: 390, height: 844,
      padding: const EdgeInsets.fromLTRB(40, 120, 40, 422),
    );
    // المركز جنوب منتصف المسار قليلاً (لأن البطاقة تغطي النصف السفلي).
    expect(cam.target.latitude, inInclusiveRange(24.60, 24.735));
    expect(cam.target.longitude, closeTo(46.71, 0.01));
    expect(cam.zoom, inInclusiveRange(10.0, 14.0));
  });

  test('قراءة المسار الرئيسي والبدائل من Valhalla', () {
    final routes = ValhallaRoutingService.parseValhalla(fixture);
    expect(routes.length, 3);
    final main = routes.first;
    expect(main.distanceKm, closeTo(20.616, 0.001));
    expect(main.points.length, greaterThan(50));
    // المسار يبدأ قرب نقطة الانطلاق (الملز) وينتهي قرب الوجهة.
    expect(main.points.first.lat, closeTo(24.6907, 0.01));
    expect(main.points.last.lat, closeTo(24.7743, 0.01));
    expect(main.maneuvers.first.type, inInclusiveRange(1, 3));
    expect(main.maneuvers.last.type, inInclusiveRange(4, 6));
  });

  group('تعليمات YMAP', () {
    const right = Maneuver(
      type: 10,
      streetNames: ['طريق الملك فهد', 'King Fahd Road'],
      lengthKm: 1.2,
      timeSec: 90,
      beginShapeIndex: 0,
    );

    test('عربي باسم الشارع العربي', () {
      expect(Instructions.text(right, 'ar'), 'انعطف يميناً إلى طريق الملك فهد');
    });

    test('إنجليزي باسم الشارع الإنجليزي', () {
      expect(Instructions.text(right, 'en'), 'Turn right onto King Fahd Road');
    });

    test('الدوار والوصول', () {
      const round = Maneuver(
          type: 26, streetNames: [], lengthKm: 0.2, timeSec: 20,
          beginShapeIndex: 0, roundaboutExit: 2);
      expect(Instructions.text(round, 'ar'), 'في الدوار خذ المخرج الثاني');
      const arrive = Maneuver(
          type: 5, streetNames: [], lengthKm: 0, timeSec: 0, beginShapeIndex: 0);
      expect(Instructions.text(arrive, 'ar'), 'وجهتك على اليمين');
    });

    test('لا يبقى إنجليزي في تعليمات المسار الحقيقي بالعربي', () {
      final routes = ValhallaRoutingService.parseValhalla(fixture);
      for (final m in routes.first.maneuvers) {
        final t = Instructions.text(m, 'ar');
        expect(RegExp(r'\b(Turn|Keep|onto|Take)\b').hasMatch(t), isFalse,
            reason: t);
      }
    });
  });

  testWidgets('بطاقة المسارات: الأسرع أولاً واختيار بديل', (tester) async {
    final routes = ValhallaRoutingService.parseValhalla(fixture);
    var selected = 0;
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('ar'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        ...GlobalMaterialLocalizations.delegates,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: StatefulBuilder(
          builder: (context, setState) => RouteCard(
            destination: const Place(
                name: 'الوجهة', subtitle: '', lat: 24.77, lon: 46.73),
            routes: routes,
            selected: selected,
            onSelect: (i) => setState(() => selected = i),
            onClose: () {},
            onStart: () {},
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('الأسرع'), findsOneWidget);
    expect(find.text('ابدأ'), findsOneWidget);
    expect(find.text('إلى الوجهة'), findsOneWidget);

    await tester.tap(find.textContaining('20.6').first);
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('16.8').first);
    await tester.pumpAndSettle();
    expect(selected, 1);
  });
}
