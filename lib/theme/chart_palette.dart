import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Palette dei grafici: griglia, assi e colore delle etichette.
///
/// Sono una cosa sola dei grafici, quindi stanno qui e non in `AppPalette`,
/// dove vivono i colori che il resto dell'app usa. È una `ThemeExtension` come
/// `AppPalette`: `AppTheme` la registra e cambia con il tema, quindi in scuro
/// gli assi non restano il grigio chiaro di una costante.
@immutable
class ChartPalette extends ThemeExtension<ChartPalette> {
  final Color grid;
  final Color axis;
  final Color label;

  const ChartPalette({
    required this.grid,
    required this.axis,
    required this.label,
  });

  factory ChartPalette.of(AppPalette palette) => ChartPalette(
    // La griglia è un filetto: il bordo della card, un po' più discreto in
    // scuro perché lì il contrasto è già forte.
    grid: palette.border.withValues(
      alpha: palette == AppPalette.dark ? 0.55 : 0.9,
    ),
    axis: palette.textSecondary,
    label: palette.textSecondary,
  );

  @override
  ChartPalette copyWith({Color? grid, Color? axis, Color? label}) =>
      ChartPalette(
        grid: grid ?? this.grid,
        axis: axis ?? this.axis,
        label: label ?? this.label,
      );

  @override
  ChartPalette lerp(ChartPalette? other, double t) {
    if (other == null) return this;
    return ChartPalette(
      grid: Color.lerp(grid, other.grid, t)!,
      axis: Color.lerp(axis, other.axis, t)!,
      label: Color.lerp(label, other.label, t)!,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ChartPalette &&
      other.grid == grid &&
      other.axis == axis &&
      other.label == label;

  @override
  int get hashCode => Object.hash(grid, axis, label);
}
