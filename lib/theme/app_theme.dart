import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTheme {
  static final ThemeData light = _build(Brightness.light, AppPalette.light);
  static final ThemeData dark = _build(Brightness.dark, AppPalette.dark);

  static ThemeData _build(Brightness brightness, AppPalette palette) {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: palette.accent,
        brightness: brightness,
        surface: palette.surface,
      ),
    );

    return base.copyWith(
      scaffoldBackgroundColor: palette.background,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: palette.background,
        foregroundColor: palette.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: palette.textPrimary,
          fontSize: 28,
          fontWeight: FontWeight.w700,
        ),
      ),
      textTheme: base.textTheme.apply(
        bodyColor: palette.textPrimary,
        displayColor: palette.textPrimary,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: palette.surface,
        indicatorColor: palette.accentSoft,
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? palette.accent
                : palette.textSecondary,
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: palette.textPrimary,
        contentTextStyle: const TextStyle(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dividerTheme: DividerThemeData(
        color: palette.border,
        thickness: 0.8,
        space: 1,
      ),
      tabBarTheme: TabBarThemeData(
        dividerColor: Colors.transparent,
        indicatorColor: palette.accent,
        labelColor: palette.textPrimary,
        unselectedLabelColor: palette.textSecondary,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        unselectedLabelStyle: const TextStyle(fontSize: 15),
      ),
      extensions: [palette],
    );
  }
}