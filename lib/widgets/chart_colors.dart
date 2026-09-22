import 'package:flutter/material.dart';

import '../models/multifunction_box/box_payload.dart';
import '../theme/app_colors.dart';

/// Risolve la chiave colore di una serie nella palette dell'app.
class ChartColor {
  const ChartColor._();

  static Color forKey(AppPalette palette, String? colorKey, int index) {
    final computed = switch (colorKey?.toLowerCase()) {
      'accent' => palette.accent,
      'teal' => palette.teal,
      'purple' => palette.purple,
      'pink' => palette.pink,
      'indigo' => palette.indigo,
      'easy' => palette.easy,
      'medium' => palette.medium,
      'hard' => palette.hard,
      _ => palette.iconPalette[index % palette.iconPalette.length],
    };
    return computed;
  }

  static List<Color> resolve(AppPalette palette, List<ChartSeries> series) {
    return [
      for (var i = 0; i < series.length; i++)
        forKey(palette, series[i].colorKey, i),
    ];
  }

  static Color forSegment(AppPalette palette, int index) {
    return palette.iconPalette[index % palette.iconPalette.length];
  }
}
