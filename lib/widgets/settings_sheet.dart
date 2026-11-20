import 'package:material_ui/material_ui.dart';

import '../l10n/app_localizations.dart';
import '../state/settings_controller.dart';


/// رقم الإصدار المعروض في الإعدادات.
const appVersion = '0.8.0';

/// نافذة الإعدادات: اللغة والمظهر (نهاري/ليلي/تلقائي).
Future<void> showSettingsSheet(
  BuildContext context,
  SettingsController settings,
) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    constraints: const BoxConstraints(maxWidth: 560),
    builder: (context) => ListenableBuilder(
      listenable: settings,
      builder: (context, _) {
        final t = AppLocalizations.of(context);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(20, 0, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(t.settings,
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 20),
                Text(t.language,
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  segments: [
                    ButtonSegment(value: 'system', label: Text(t.languageSystem)),
                    ButtonSegment(value: 'ar', label: Text(t.languageArabic)),
                    ButtonSegment(value: 'en', label: Text(t.languageEnglish)),
                  ],
                  selected: {settings.languageCode},
                  onSelectionChanged: (s) => settings.setLanguage(s.first),
                ),
                const SizedBox(height: 20),
                Text(t.appearance,
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                SegmentedButton<ThemeMode>(
                  segments: [
                    ButtonSegment(
                        value: ThemeMode.system,
                        icon: const Icon(Icons.brightness_auto),
                        label: Text(t.themeSystem)),
                    ButtonSegment(
                        value: ThemeMode.light,
                        icon: const Icon(Icons.light_mode_outlined),
                        label: Text(t.themeLight)),
                    ButtonSegment(
                        value: ThemeMode.dark,
                        icon: const Icon(Icons.dark_mode_outlined),
                        label: Text(t.themeDark)),
                  ],
                  selected: {settings.themeMode},
                  onSelectionChanged: (s) => settings.setThemeMode(s.first),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(t.cameraAlerts),
                  subtitle: Text(t.cameraAlertsHint),
                  value: settings.cameraAlerts,
                  onChanged: settings.setCameraAlerts,
                ),
                const SizedBox(height: 12),
                Text(
                  t.version(appVersion),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}
