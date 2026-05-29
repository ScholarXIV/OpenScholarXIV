import "package:flutter/material.dart";
import "package:theme_provider/theme_provider.dart";

const Color fallbackSeedColor = Color(0xFF006A6A);

ColorScheme appLightColorScheme(ColorScheme? dynamicScheme) {
  return dynamicScheme ?? ColorScheme.fromSeed(seedColor: fallbackSeedColor);
}

ColorScheme appDarkColorScheme(ColorScheme? dynamicScheme) {
  return dynamicScheme ??
      ColorScheme.fromSeed(
        seedColor: fallbackSeedColor,
        brightness: Brightness.dark,
      );
}

Color subtleSurfaceColor(ColorScheme colorScheme) {
  final isDark = colorScheme.brightness == Brightness.dark;
  return Color.alphaBlend(
    (isDark ? Colors.white : Colors.black).withAlpha(isDark ? 18 : 10),
    colorScheme.surface,
  );
}

String pairedBrightnessThemeId(String themeId) {
  if (themeId.endsWith("_light")) {
    return themeId.replaceFirst(RegExp(r"_light$"), "_dark");
  }
  if (themeId.endsWith("_dark")) {
    return themeId.replaceFirst(RegExp(r"_dark$"), "_light");
  }
  if (themeId == "light_theme") {
    return "dark_theme";
  }
  if (themeId == "dark_theme") {
    return "light_theme";
  }
  return "light_theme";
}

List<AppTheme> buildAppThemes(
  ColorScheme? lightDynamic,
  ColorScheme? darkDynamic,
) {
  return [
    AppTheme(
      id: "light_theme",
      description: "Material Light",
      data: buildAppTheme(appLightColorScheme(lightDynamic)),
    ),
    AppTheme(
      id: "dark_theme",
      description: "Material Dark",
      data: buildAppTheme(appDarkColorScheme(darkDynamic)),
    ),
    _seedTheme(
      id: "scholar_light",
      description: "Scholar Light",
      seedColor: fallbackSeedColor,
    ),
    _seedTheme(
      id: "scholar_dark",
      description: "Scholar Dark",
      seedColor: fallbackSeedColor,
      brightness: Brightness.dark,
    ),
    _seedTheme(
      id: "indigo_light",
      description: "Indigo Light",
      seedColor: const Color(0xFF4F46E5),
    ),
    _seedTheme(
      id: "indigo_dark",
      description: "Indigo Dark",
      seedColor: const Color(0xFF4F46E5),
      brightness: Brightness.dark,
    ),
    _seedTheme(
      id: "rose_light",
      description: "Rose Light",
      seedColor: const Color(0xFFE11D48),
    ),
    _seedTheme(
      id: "rose_dark",
      description: "Rose Dark",
      seedColor: const Color(0xFFE11D48),
      brightness: Brightness.dark,
    ),
  ];
}

AppTheme _seedTheme({
  required String id,
  required String description,
  required Color seedColor,
  Brightness brightness = Brightness.light,
}) {
  return AppTheme(
    id: id,
    description: description,
    data: buildAppTheme(
      ColorScheme.fromSeed(seedColor: seedColor, brightness: brightness),
    ),
  );
}

ThemeData buildAppTheme(ColorScheme colorScheme) {
  final baseTheme = ThemeData(useMaterial3: true, colorScheme: colorScheme);

  return baseTheme.copyWith(
    primaryColor: colorScheme.primary,
    scaffoldBackgroundColor: colorScheme.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
      surfaceTintColor: colorScheme.surfaceTint,
      elevation: 0,
      iconTheme: IconThemeData(color: colorScheme.onSurface),
      titleTextStyle: baseTheme.textTheme.titleLarge?.copyWith(
        color: colorScheme.onSurface,
        fontWeight: FontWeight.w600,
        fontSize: 20.0,
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: colorScheme.surface,
      modalBackgroundColor: colorScheme.surface,
      surfaceTintColor: colorScheme.surfaceTint,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: colorScheme.primaryContainer,
      foregroundColor: colorScheme.onPrimaryContainer,
    ),
    iconTheme: IconThemeData(color: colorScheme.onSurface),
    textTheme: baseTheme.textTheme.apply(
      bodyColor: colorScheme.onSurface,
      displayColor: colorScheme.onSurface,
    ),
  );
}
