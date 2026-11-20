import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ymap/app.dart';
import 'package:ymap/saved/saved_places.dart';
import 'package:ymap/screens/home_screen.dart';
import 'package:ymap/search/categories.dart';
import 'package:ymap/search/place.dart';
import 'package:ymap/search/search_service.dart';
import 'package:ymap/state/settings_controller.dart';
import 'package:ymap/widgets/place_card.dart';

const _home = Place(name: 'بيتي في النسيم', subtitle: 'الرياض', lat: 24.73, lon: 46.82);

class _FakeSearch implements SearchService {
  @override
  Future<List<Place>> search(String q,
          {required String languageCode,
          required double nearLat,
          required double nearLon}) async =>
      [_home];
  @override
  Future<List<Place>> nearby(PlaceCategory c,
          {required double nearLat, required double nearLon}) async =>
      const [];
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('حفظ البيت والمفضلة والسيارة يبقى بعد إعادة التحميل', () async {
    final a = SavedPlaces();
    await a.load();
    await a.setHome(_home);
    await a.toggleFavorite(_home);
    await a.saveCar(24.7, 46.7);

    final b = SavedPlaces();
    await b.load();
    expect(b.home!.name, 'بيتي في النسيم');
    expect(b.isFavorite(_home), isTrue);
    expect(b.car!.lat, 24.7);

    await b.toggleFavorite(_home);
    await b.clearCar();
    final c = SavedPlaces();
    await c.load();
    expect(c.isFavorite(_home), isFalse);
    expect(c.car, isNull);
  });

  testWidgets('زر «البيت» أول مرة يطلب اختياره ثم يحفظه ويعرضه', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final settings = SettingsController();
    await settings.load();
    await settings.setLanguage('ar');
    await tester.pumpWidget(YmapApp(
      settings: settings,
      searchService: _FakeSearch(),
      mapBuilder: (context, key, isTablet, onMessage) => const MapPlaceholder(),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('البيت'));
    await tester.pumpAndSettle();
    expect(find.text('ابحث عن مكان البيت'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'النسيم');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    await tester.tap(find.text('بيتي في النسيم'));
    await tester.pumpAndSettle();

    expect(find.byType(PlaceCard), findsOneWidget);
    expect(find.text('تم حفظ مكان البيت'), findsOneWidget);
    final saved = SavedPlaces();
    await saved.load();
    expect(saved.home?.name, 'بيتي في النسيم');
  });
}
