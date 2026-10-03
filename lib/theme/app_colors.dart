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
  final Color danger;
  final Color shadow;

  /// Sfondo della pilla identitaria dell'header. È un colore di marca, quindi
  /// è lo stesso in chiaro e in scuro: dentro la pilla i testi sono bianchi in
  /// entrambi i temi e non letti dal tema.
  final Color headerBlue;

  /// Testo e anelli dentro [headerBlue]. Bianco in entrambi i temi, perché la
  /// pilla non cambia: i colori del tema non ci arriverebbero.
  final Color headerOnBlue;
  final List<Color> iconPalette;
  final Color splashTop;
  final Color splashBottom;
  final Color onSplash;

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
    required this.danger,
    required this.shadow,
    required this.headerBlue,
    required this.headerOnBlue,
    required this.iconPalette,
    required this.splashTop,
    required this.splashBottom,
    required this.onSplash,
  });

  static const AppPalette light = AppPalette(
    background: Color(0xFFFCF8FF),
    surface: Color(0xFFFFFFFF),
    border: Color(0xFFE6E1EC),
    textPrimary: Color(0xFF1C1C1E),
    textSecondary: Color(0xFF6E6E73),
    accent: Color(0xFF3525CD),
    accentSoft: Color(0xFFE7E4FF),
    easy: Color(0xFF34C759),
    medium: Color(0xFFFF9500),
    hard: Color(0xFFFF3B30),
    teal: Color(0xFF00BFA5),
    purple: Color(0xFF9C27B0),
    pink: Color(0xFFEC407A),
    indigo: Color(0xFF5C6BC0),
    danger: Color(0xFF8B1B34),
    shadow: Color(0x14000000),
    headerBlue: Color(0xFF3F46E8),
    headerOnBlue: Color(0xFFFFFFFF),
    iconPalette: [
      Color(0xFF007AFF),
      Color(0xFF9C27B0),
      Color(0xFF00BFA5),
      Color(0xFFEC407A),
      Color(0xFF5C6BC0),
      Color(0xFFFF9500),
      Color(0xFF34C759),
    ],
    splashTop: Color(0xFF007AFF),
    splashBottom: Color(0xFF5C6BC0),
    onSplash: Color(0xFFFFFFFF),
  );

  static const AppPalette dark = AppPalette(
    background: Color(0xFF0E0E11),
    surface: Color(0xFF1C1C22),
    border: Color(0xFF2C2C33),
    textPrimary: Color(0xFFF2F2F7),
    textSecondary: Color(0xFFA0A0AB),
    accent: Color(0xFFBFC2FF),
    accentSoft: Color(0xFF2A2480),
    easy: Color(0xFF4CD964),
    medium: Color(0xFFFFB340),
    hard: Color(0xFFFF6961),
    teal: Color(0xFF2EC9B5),
    purple: Color(0xFFB388FF),
    pink: Color(0xFFFF7A9C),
    indigo: Color(0xFF8E9BFF),
    danger: Color(0xFFFFB4AB),
    shadow: Color(0x33000000),
    headerBlue: Color(0xFF3F46E8),
    headerOnBlue: Color(0xFFFFFFFF),
    iconPalette: [
      Color(0xFF3B9BFF),
      Color(0xFFB388FF),
      Color(0xFF2EC9B5),
      Color(0xFFFF7A9C),
      Color(0xFF8E9BFF),
      Color(0xFFFFB340),
      Color(0xFF4CD964),
    ],
    splashTop: Color(0xFF007AFF),
    splashBottom: Color(0xFF5C6BC0),
    onSplash: Color(0xFFFFFFFF),
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
    Color? danger,
    Color? shadow,
    Color? headerBlue,
    Color? headerOnBlue,
    List<Color>? iconPalette,
    Color? splashTop,
    Color? splashBottom,
    Color? onSplash,
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
      danger: danger ?? this.danger,
      shadow: shadow ?? this.shadow,
      headerBlue: headerBlue ?? this.headerBlue,
      headerOnBlue: headerOnBlue ?? this.headerOnBlue,
      iconPalette: iconPalette ?? this.iconPalette,
      splashTop: splashTop ?? this.splashTop,
      splashBottom: splashBottom ?? this.splashBottom,
      onSplash: onSplash ?? this.onSplash,
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
      danger: Color.lerp(danger, other.danger, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
      headerBlue: Color.lerp(headerBlue, other.headerBlue, t)!,
      headerOnBlue: Color.lerp(headerOnBlue, other.headerOnBlue, t)!,
      iconPalette: List.generate(
        iconPalette.length,
        (i) => Color.lerp(iconPalette[i], other.iconPalette[i], t)!,
        growable: false,
      ),
      splashTop: Color.lerp(splashTop, other.splashTop, t)!,
      splashBottom: Color.lerp(splashBottom, other.splashBottom, t)!,
      onSplash: Color.lerp(onSplash, other.onSplash, t)!,
    );
  }
}

class AppColors {
  AppColors._();

  static AppPalette of(BuildContext context) =>
      Theme.of(context).extension<AppPalette>() ?? AppPalette.light;
}
