import 'package:flutter/material.dart';

import '../../models/multifunction_box/box_payload.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../../theme/chart_palette.dart';
import '../math_text.dart';
import 'chart_painters.dart';

/// Il grafico di un riquadro `chart`: non interattivo.
///
/// Nessun tap, nessuno slider, nessuna legenda cliccabile: il lettore guarda
/// la curva o le barre e prosegue. L'unico movimento è l'entrata, che traccia il
/// tracciato una volta sola quando la card compare.
class ChartView extends StatelessWidget {
  static const _duration = Duration(milliseconds: 400);

  final ChartBoxPayload payload;

  const ChartView({super.key, required this.payload});

  @override
  Widget build(BuildContext context) {
    final palette =
        Theme.of(context).extension<ChartPalette>() ??
        // Come `AppColors.of`: senza tema registrato l'app non è un contesto
        // valido, ma un albero di test sì, e un grafico sparito fa fallire il
        // test senza dire perché.
        ChartPalette.of(AppColors.of(context));
    if (payload.isEmpty) return const SizedBox.shrink();

    final colors = _seriesColors(context);
    final textScale = textScaleFactorOf(context);
    final labels = _legendLabels(payload);
    // Fuori dal builder animato: i campioni non cambiano fra un frame e l'altro.
    final segments = payload.kind == ChartKind.bar
        ? null
        : LineChartPainter.segmentsOf(payload);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: 1.6,
          child: RepaintBoundary(
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: 1),
              duration: _duration,
              curve: Curves.easeOutCubic,
              builder: (context, progress, _) {
                final style = ChartStyle(
                  palette: palette,
                  textScale: textScale,
                );
                return Semantics(
                  label:
                      '${payload.kind.label}${labels.length > 1 ? ': ${labels.join(', ')}' : ''}',
                  child: CustomPaint(
                    key: const Key('chart-canvas'),
                    painter: _painterFor(
                      payload,
                      colors,
                      style,
                      progress,
                      segments,
                    ),
                    size: Size.infinite,
                  ),
                );
              },
            ),
          ),
        ),
        if (labels.length > 1) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 14,
            runSpacing: 6,
            children: [
              for (var i = 0; i < labels.length; i++)
                _LegendItem(label: labels[i], color: colors[i % colors.length]),
            ],
          ),
        ],
      ],
    );
  }

  CustomPainter _painterFor(
    ChartBoxPayload payload,
    List<Color> colors,
    ChartStyle style,
    double progress,
    List<List<List<ChartPoint>>>? segments,
  ) {
    return switch (payload.kind) {
      ChartKind.bar => BarChartPainter(
        payload: payload,
        colors: colors,
        style: style,
        progress: progress,
      ),
      ChartKind.line || ChartKind.function => LineChartPainter(
        payload: payload,
        colors: colors,
        style: style,
        progress: progress,
        segments: segments,
      ),
    };
  }

  /// Le etichette distinte delle serie: due serie con lo stesso nome non
  /// meritano due voci in legenda.
  static List<String> _legendLabels(ChartBoxPayload payload) {
    final out = <String>[];
    for (final s in payload.series) {
      final label = s.label.trim();
      if (label.isEmpty || out.contains(label)) continue;
      out.add(label);
    }
    return out;
  }

  List<Color> _seriesColors(BuildContext context) {
    final c = AppColors.of(context);
    return [
      for (var i = 0; i < payload.series.length; i++)
        switch (payload.series[i].colorKey?.toLowerCase()) {
          'accent' => c.accent,
          'teal' => c.teal,
          'purple' => c.purple,
          'pink' => c.pink,
          'indigo' => c.indigo,
          'easy' => c.easy,
          'medium' => c.medium,
          'hard' => c.hard,
          _ => c.iconPalette[i % c.iconPalette.length],
        },
    ];
  }
}

class _LegendItem extends StatelessWidget {
  final String label;
  final Color color;

  const _LegendItem({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: AppText.labelSmall,
            fontWeight: FontWeight.w600,
            color: c.textSecondary,
          ),
        ),
      ],
    );
  }
}
