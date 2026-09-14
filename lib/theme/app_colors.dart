import 'package:flutter/material.dart';

class AppPalette extends ThemeExtension<AppPalette> {
  final Color background;
  final Color surface;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color accent;
  final Color accentSoft;
  final Color easy;
  final Color medium;
  final Color hard;
  final Color teal;
  final Color purple;
  final Color pink;
  final Color indigo;
  final Color shadow;
  final List<Color> iconPalette;

  const AppPalette({
    required this.background,
    required this.surface,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.accent,
    required this.accentSoft,
    required this.easy,
    required this.medium,
    required this.hard,
    required this.teal,
    required this.purple,
    required this.pink,
    required this.indigo,
    required this.shadow,
    required this.iconPalette,
  });

  static const AppPalette light = AppPalette(
    background: Color(0xFFF9F9F9),
    surface: Color(0xFFFFFFFF),
    border: Color(0xFFE5E5EA),
    textPrimary: Color(0xFF1C1C1E),
    textSecondary: Color(0xFF6E6E73),
    accent: Color(0xFF007AFF),
    accentSoft: Color(0xFFEBF3FF),
    easy: Color(0xFF34C759),
    medium: Color(0xFFFF9500),
    hard: Color(0xFFFF3B30),
    teal: Color(0xFF00BFA5),
    purple: Color(0xFF9C27B0),
    pink: Color(0xFFEC407A),
    indigo: Color(0xFF5C6BC0),
    shadow: Color(0x14000000),
    iconPalette: [
      Color(0xFF007AFF),
      Color(0xFF9C27B0),
      Color(0xFF00BFA5),
      Color(0xFFEC407A),
      Color(0xFF5C6BC0),
      Color(0xFFFF9500),
      Color(0xFF34C759),
    ],
  );

  static const AppPalette dark = AppPalette(
    background: Color(0xFF0E0E11),
    surface: Color(0xFF1C1C22),
    border: Color(0xFF2C2C33),
    textPrimary: Color(0xFFF2F2F7),
    textSecondary: Color(0xFFA0A0AB),
    accent: Color(0xFF3B9BFF),
    accentSoft: Color(0xFF1B2A44),
    easy: Color(0xFF4CD964),
    medium: Color(0xFFFFB340),
    hard: Color(0xFFFF6961),
    teal: Color(0xFF2EC9B5),
    purple: Color(0xFFB388FF),
    pink: Color(0xFFFF7A9C),
    indigo: Color(0xFF8E9BFF),
    shadow: Color(0x33000000),
    iconPalette: [
      Color(0xFF3B9BFF),
      Color(0xFFB388FF),
      Color(0xFF2EC9B5),
      Color(0xFFFF7A9C),
      Color(0xFF8E9BFF),
      Color(0xFFFFB340),
      Color(0xFF4CD964),
    ],
  );

  @override
  AppPalette copyWith({
    Color? background,
    Color? surface,
    Color? border,
    Color? textPrimary,
    Color? textSecondary,
    Color? accent,
    Color? accentSoft,
    Color? easy,
    Color? medium,
    Color? hard,
    Color? teal,
    Color? purple,
    Color? pink,
    Color? indigo,
    Color? shadow,
    List<Color>? iconPalette,
  }) {
    return AppPalette(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      border: border ?? this.border,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      accent: accent ?? this.accent,
      accentSoft: accentSoft ?? this.accentSoft,
      easy: easy ?? this.easy,
      medium: medium ?? this.medium,
      hard: hard ?? this.hard,
      teal: teal ?? this.teal,
      purple: purple ?? this.purple,
      pink: pink ?? this.pink,
      indigo: indigo ?? this.indigo,
      shadow: shadow ?? this.shadow,
      iconPalette: iconPalette ?? this.iconPalette,
    );
  }

  @override
  AppPalette lerp(covariant ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      border: Color.lerp(border, other.border, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentSoft: Color.lerp(accentSoft, other.accentSoft, t)!,
      easy: Color.lerp(easy, other.easy, t)!,
      medium: Color.lerp(medium, other.medium, t)!,
      hard: Color.lerp(hard, other.hard, t)!,
      teal: Color.lerp(teal, other.teal, t)!,
      purple: Color.lerp(purple, other.purple, t)!,
      pink: Color.lerp(pink, other.pink, t)!,
      indigo: Color.lerp(indigo, other.indigo, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
      iconPalette: List.generate(
        iconPalette.length,
        (i) => Color.lerp(iconPalette[i], other.iconPalette[i], t)!,
        growable: false,
      ),
    );
  }
}

class AppColors {
  AppColors._();

  static AppPalette of(BuildContext context) =>
      Theme.of(context).extension<AppPalette>() ?? AppPalette.light;
}