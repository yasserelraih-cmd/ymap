import 'package:material_ui/material_ui.dart';

import 'l10n/app_localizations.dart';
import 'screens/home_screen.dart';
import 'search/search_service.dart';
import 'state/settings_controller.dart';
import 'theme/ymap_theme.dart';

class YmapApp extends StatelessWidget {
  const YmapApp({
    super.key,
    required this.settings,
    this.mapBuilder,
    this.searchService,
  });

  final SettingsController settings;
  final MapBuilder? mapBuilder;
  final SearchService? searchService;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) => MaterialApp(
        title: 'YMAP',
        debugShowCheckedModeBanner: false,
        theme: YmapTheme.light(),
        darkTheme: YmapTheme.dark(),
        themeMode: settings.themeMode,
        locale: settings.locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          ...GlobalMaterialLocalizations.delegates,
        ],
        // أي لغة جهاز غير مدعومة ← العربية.
        localeResolutionCallback: (deviceLocale, supported) {
          for (final l in supported) {
            if (l.languageCode == deviceLocale?.languageCode) return l;
          }
          return const Locale('ar');
        },
        home: HomeScreen(
          settings: settings,
          mapBuilder: mapBuilder,
          searchService: searchService,
        ),
      ),
    );
  }
}
