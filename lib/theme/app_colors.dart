import 'package:flutter/material.dart';

/// I colori dell'app, presi dal design (canvas «Illustrazioni App Educativa»):
/// indaco profondo, giallo, crema, arancio, turchese e rosa.
///
/// Un tema solo, chiaro: il design non ha una versione scura. I colori del
/// canvas restano quelli di decoro e riempimento; i ruoli che finiscono come
/// testo (`easy`, `medium`, `hard`, `teal`, `pink`) sono toni più scuri della
/// stessa famiglia, perché il verde, l'arancio e il rosso del canvas su bianco
/// stanno sotto 4.5:1.
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

  /// Il giallo del design: bottoni secondari, badge, barre di avanzamento.
  /// Ci va sopra l'inchiostro ([textPrimary]), non il bianco.
  final Color yellow;

  /// Il bordo e l'ombra piena di ciò che è [yellow].
  final Color yellowDeep;

  /// Il fondo giallo chiaro delle barre di avanzamento.
  final Color yellowSoft;

  /// L'arancio del design, per i traguardi e i bottoni tondi.
  final Color orange;

  /// Il bordo e l'ombra piena di ciò che è [orange].
  final Color orangeDeep;

  /// L'ombra piena dei bottoni [accent]: il design li solleva con un gradino
  /// di colore pieno sotto, non con un'ombra sfumata.
  final Color accentDeep;

  /// L'ombra piena delle card, un oro che sta bene sul crema dello sfondo.
  final Color cardShadow;

  /// Le righe del quaderno nelle card a righe.
  final Color paperLine;

  /// Il fondo e il testo di un bottone disabilitato: un grigio caldo, che sul
  /// crema non sembra un errore.
  final Color disabled;
  final Color onDisabled;

  /// Sfondo della banda dell'header: l'indaco del design, con i testi bianchi
  /// di [onHeaderBand].
  final Color headerBand;

  /// Testo e anelli dentro [headerBand].
  final Color onHeaderBand;
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
    required this.yellow,
    required this.yellowDeep,
    required this.yellowSoft,
    required this.orange,
    required this.orangeDeep,
    required this.accentDeep,
    required this.cardShadow,
    required this.paperLine,
    required this.disabled,
    required this.onDisabled,
    required this.headerBand,
    required this.onHeaderBand,
    required this.iconPalette,
    required this.splashTop,
    required this.splashBottom,
    required this.onSplash,
  });

  static const AppPalette light = AppPalette(
    background: Color(0xFFFFF4D6),
    surface: Color(0xFFFFFFFF),
    border: Color(0xFFCFC7E6),
    textPrimary: Color(0xFF1F1250),
    textSecondary: Color(0xFF574E7D),
    accent: Color(0xFF2B1A6B),
    accentSoft: Color(0xFFECE7FA),
    easy: Color(0xFF2E7D32),
    medium: Color(0xFFB14D06),
    hard: Color(0xFFC0391B),
    teal: Color(0xFF1F8577),
    purple: Color(0xFF5048D6),
    pink: Color(0xFFC2406B),
    indigo: Color(0xFF463589),
    danger: Color(0xFF8B1B34),
    shadow: Color(0x1F2B1A6B),
    yellow: Color(0xFFF6B818),
    yellowDeep: Color(0xFFB98500),
    yellowSoft: Color(0xFFFBE7A8),
    orange: Color(0xFFEF7D1A),
    orangeDeep: Color(0xFFB65508),
    accentDeep: Color(0xFF160C3E),
    cardShadow: Color(0xFFE3C46E),
    paperLine: Color(0xFFCFDCF3),
    disabled: Color(0xFFE4DFD4),
    onDisabled: Color(0xFF6F6A86),
    headerBand: Color(0xFF2B1A6B),
    onHeaderBand: Color(0xFFFFFFFF),
    iconPalette: [
      Color(0xFF2B1A6B),
      Color(0xFFEF7D1A),
      Color(0xFF2FB3A2),
      Color(0xFFC2406B),
      Color(0xFF5048D6),
      Color(0xFFB98500),
      Color(0xFF2E7D32),
    ],
    splashTop: Color(0xFF2B1A6B),
    splashBottom: Color(0xFF463589),
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
    Color? yellow,
    Color? yellowDeep,
    Color? yellowSoft,
    Color? orange,
    Color? orangeDeep,
    Color? accentDeep,
    Color? cardShadow,
    Color? paperLine,
    Color? disabled,
    Color? onDisabled,
    Color? headerBand,
    Color? onHeaderBand,
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
      yellow: yellow ?? this.yellow,
      yellowDeep: yellowDeep ?? this.yellowDeep,
      yellowSoft: yellowSoft ?? this.yellowSoft,
      orange: orange ?? this.orange,
      orangeDeep: orangeDeep ?? this.orangeDeep,
      accentDeep: accentDeep ?? this.accentDeep,
      cardShadow: cardShadow ?? this.cardShadow,
      paperLine: paperLine ?? this.paperLine,
      disabled: disabled ?? this.disabled,
      onDisabled: onDisabled ?? this.onDisabled,
      headerBand: headerBand ?? this.headerBand,
      onHeaderBand: onHeaderBand ?? this.onHeaderBand,
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
      yellow: Color.lerp(yellow, other.yellow, t)!,
      yellowDeep: Color.lerp(yellowDeep, other.yellowDeep, t)!,
      yellowSoft: Color.lerp(yellowSoft, other.yellowSoft, t)!,
      orange: Color.lerp(orange, other.orange, t)!,
      orangeDeep: Color.lerp(orangeDeep, other.orangeDeep, t)!,
      accentDeep: Color.lerp(accentDeep, other.accentDeep, t)!,
      cardShadow: Color.lerp(cardShadow, other.cardShadow, t)!,
      paperLine: Color.lerp(paperLine, other.paperLine, t)!,
      disabled: Color.lerp(disabled, other.disabled, t)!,
      onDisabled: Color.lerp(onDisabled, other.onDisabled, t)!,
      headerBand: Color.lerp(headerBand, other.headerBand, t)!,
      onHeaderBand: Color.lerp(onHeaderBand, other.onHeaderBand, t)!,
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
