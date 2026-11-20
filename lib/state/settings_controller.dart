import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// إعدادات التطبيق: اللغة والمظهر، وتُحفظ على الجهاز.
class SettingsController extends ChangeNotifier {
  static const _kLanguage = 'language'; // 'ar' أو 'en' أو 'system'
  static const _kTheme = 'theme'; // 'light' أو 'dark' أو 'system'

  Locale? _locale; // null = حسب لغة الجهاز
  ThemeMode _themeMode = ThemeMode.system;

  Locale? get locale => _locale;
  ThemeMode get themeMode => _themeMode;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final lang = prefs.getString(_kLanguage) ?? 'system';
    _locale = lang == 'system' ? null : Locale(lang);
    _themeMode = switch (prefs.getString(_kTheme)) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    notifyListeners();
  }

  Future<void> setLanguage(String code) async {
    _locale = code == 'system' ? null : Locale(code);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLanguage, code);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kTheme, mode.name);
  }

  String get languageCode => _locale?.languageCode ?? 'system';
}
