import 'package:material_ui/material_ui.dart';

/// ألوان هوية YMAP (مبدئية ويمكن تغييرها لاحقاً من هذا الملف فقط).
class YmapColors {
  static const primary = Color(0xFF0B7A75); // أخضر مزرق
  static const accent = Color(0xFFF2A541); // برتقالي للتنبيهات والمسار
  static const nightBackground = Color(0xFF0F1A1C);
}

class YmapTheme {
  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: YmapColors.primary,
      brightness: brightness,
      secondary: YmapColors.accent,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: brightness == Brightness.dark
          ? YmapColors.nightBackground
          : scheme.surface,
      // خط YMAP: IBM Plex Sans Arabic (عربي + إنجليزي، رخصة OFL مجانية).
      fontFamily: 'IBMPlexSansArabic',
      visualDensity: VisualDensity.standard,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
    );
  }
}
