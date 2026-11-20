import 'package:material_ui/material_ui.dart';

import '../contrib/contributions.dart';
import '../l10n/app_localizations.dart';
import '../navigation/speaker.dart';
import '../routing/instructions.dart';
import 'contrib_dialogs.dart';
import '../state/settings_controller.dart';


/// رقم الإصدار المعروض في الإعدادات.
const appVersion = '0.12.1';

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
                const SizedBox(height: 16),
                Text(t.voiceDialect, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(value: 'sa', label: Text(t.dialectSaudi)),
                    ButtonSegment(value: 'eg', label: Text(t.dialectEgyptian)),
                    ButtonSegment(value: 'msa', label: Text(t.dialectStandard)),
                  ],
                  selected: {settings.voiceDialect},
                  onSelectionChanged: (v) => settings.setVoiceDialect(v.first),
                ),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton.icon(
                    icon: const Icon(Icons.record_voice_over_outlined),
                    label: Text(t.testVoice),
                    onPressed: () async {
                      final lang = Localizations.localeOf(context).languageCode;
                      final d = VoiceDialect.fromCode(settings.voiceDialect);
                      final sample = lang != 'ar'
                          ? 'In 300 meters, turn right onto King Fahd Road'
                          : switch (d) {
                              VoiceDialect.saudi => 'بعد 300 متر، لف يمين على طريق الملك فهد',
                              VoiceDialect.egyptian => 'بعد 300 متر، خش يمين على شارع النيل',
                              VoiceDialect.standard => 'بعد 300 متر، انعطف يميناً إلى طريق الملك فهد',
                            };
                      await _sampleSpeaker.setLanguage(lang);
                      await _sampleSpeaker.say(sample);
                    },
                  ),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(t.cameraAlerts),
                  subtitle: Text(t.cameraAlertsHint),
                  value: settings.cameraAlerts,
                  onChanged: settings.setCameraAlerts,
                ),
                const Divider(height: 24),
                ContributionsTile(contributions: Contributions()),
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

final _sampleSpeaker = Speaker();
