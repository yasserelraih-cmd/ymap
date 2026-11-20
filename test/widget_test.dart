import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ymap/app.dart';
import 'package:ymap/screens/home_screen.dart';
import 'package:ymap/state/settings_controller.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<SettingsController> pumpApp(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final settings = SettingsController();
    await settings.load();
    await settings.setLanguage('ar');
    await tester.pumpWidget(YmapApp(
      settings: settings,
      mapBuilder: (context, key, isTablet, onMessage) => const MapPlaceholder(),
    ));
    await tester.pumpAndSettle();
    return settings;
  }

  testWidgets('الجوال: يفتح بالعربية واتجاه من اليمين لليسار',
      (tester) async {
    await pumpApp(tester, const Size(390, 844));
    expect(find.text('ابحث عن مكان أو عنوان'), findsOneWidget);
    expect(find.byType(DraggableScrollableSheet), findsOneWidget);
    final dir = Directionality.of(tester.element(find.byType(TextField)));
    expect(dir, TextDirection.rtl);
  });

  testWidgets('الآيباد: لوحة جانبية بدل البطاقة السفلية', (tester) async {
    await pumpApp(tester, const Size(1024, 1366));
    expect(find.byType(DraggableScrollableSheet), findsNothing);
    expect(find.byType(Card), findsOneWidget);
  });

  testWidgets('التبديل للإنجليزية والوضع الليلي', (tester) async {
    final settings = await pumpApp(tester, const Size(390, 844));
    await settings.setLanguage('en');
    await settings.setThemeMode(ThemeMode.dark);
    await tester.pumpAndSettle();
    expect(find.text('Search for a place or address'), findsOneWidget);
    final dir = Directionality.of(tester.element(find.byType(TextField)));
    expect(dir, TextDirection.ltr);
    final ctx = tester.element(find.byType(TextField));
    expect(Theme.of(ctx).brightness, Brightness.dark);
  });
}
