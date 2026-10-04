import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

import '../../models/multifunction_box/box_payload.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_motion.dart';
import '../../theme/app_text.dart';
import '../../theme/chart_palette.dart';
import '../math_text.dart';
import 'graph_layout.dart';
import 'graph_painter.dart';

/// Il colore di un elemento del grafico: il nome scritto nel JSON, o il
/// successivo di una sequenza di colori ben distinti fra loro.
///
/// Sono i toni scuri della palette: su bianco tutti oltre 3:1, la soglia di
/// una linea. L'arancio è `orangeDeep`, perché `orange` su bianco non ci
/// arriva.
Color graphColor(AppPalette c, String? key, int index) {
  final cycle = [c.accent, c.orangeDeep, c.teal, c.pink, c.easy, c.purple];
  return switch (key?.toLowerCase()) {
    'accent' => c.accent,
    'orange' => c.orangeDeep,
    'teal' => c.teal,
    'pink' => c.pink,
    'green' => c.easy,
    'purple' => c.purple,
    'red' => c.hard,
    'indigo' => c.indigo,
    _ => cycle[index % cycle.length],
  };
}

/// Il grafico di un riquadro `graph`: non interattivo.
///
/// Nessun tap, zoom o tooltip: il lettore guarda e prosegue. L'unico movimento
/// è l'entrata, una volta sola al montaggio: curve e rette si tracciano, punti
/// ed etichette compaiono, le barre crescono ([AppMotion.slow]). Col movimento
/// ridotto il grafico è già lì.
class GraphView extends StatelessWidget {
  final GraphPayload payload;

  const GraphView({super.key, required this.payload});

  @override
  Widget build(BuildContext context) {
    if (payload.isEmpty) return const SizedBox.shrink();
    final c = AppColors.of(context);
    final palette =
        Theme.of(context).extension<ChartPalette>() ?? ChartPalette.of(c);
    final textScale = textScaleFactorOf(context);
    final bars = payload.plane == GraphPlane.bars;
    final colors = [
      if (bars)
        for (var i = 0; i < payload.series.length; i++)
          graphColor(c, payload.series[i].colorKey, i)
      else
        for (var i = 0; i < payload.items.length; i++)
          graphColor(c, payload.items[i].colorKey, i),
    ];
    final style = GraphStyle(
      palette: palette,
      colors: colors,
      surface: c.surface,
      textScale: textScale,
    );
    final legend = _legend(colors);

    return Semantics(
      container: true,
      image: true,
      label: _describe(),
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                if (bars) {
                  final layout = BarsLayout.of(
                    payload,
                    width,
                    textScale: textScale,
                  );
                  return _animated(
                    context,
                    Size(width, layout.height),
                    (progress) => BarsPainter(
                      payload: payload,
                      layout: layout,
                      style: style,
                      progress: progress,
                    ),
                    _barLabels(layout, c, textScale),
                  );
                }
                if (payload.plane == GraphPlane.numberLine) {
                  final layout = NumberLineLayout.of(
                    payload,
                    width,
                    textScale: textScale,
                  );
                  return _animated(
                    context,
                    Size(width, layout.height),
                    (progress) => NumberLinePainter(
                      payload: payload,
                      layout: layout,
                      style: style,
                      progress: progress,
                    ),
                    _numberLineLabels(layout, c, colors, textScale),
                  );
                }
                final layout = CartesianLayout.of(
                  payload,
                  width,
                  textScale: textScale,
                );
                return _animated(
                  context,
                  Size(width, layout.height),
                  (progress) => CartesianPainter(
                    payload: payload,
                    layout: layout,
                    style: style,
                    progress: progress,
                  ),
                  _cartesianLabels(layout, c, colors, textScale),
                );
              },
            ),
            if (legend.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(spacing: 16, runSpacing: 6, children: legend),
            ],
          ],
        ),
      ),
    );
  }

  /// Il disegno e le etichette, con l'entrata: il painter si rifà a ogni
  /// frame, le etichette (che non cambiano) compaiono in dissolvenza.
  Widget _animated(
    BuildContext context,
    Size size,
    CustomPainter Function(double progress) painter,
    List<Widget> labels,
  ) {
    return SizedBox.fromSize(
      size: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: AppMotion.reduced(context) ? 1 : 0, end: 1),
        duration: AppMotion.duration(context, AppMotion.slow),
        curve: AppMotion.standard,
        child: Stack(clipBehavior: Clip.none, children: labels),
        builder: (context, progress, child) => Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                key: const Key('graph-canvas'),
                painter: painter(progress),
              ),
            ),
            Positioned.fill(
              child: Opacity(opacity: progress, child: child),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _cartesianLabels(
    CartesianLayout layout,
    AppPalette c,
    List<Color> colors,
    double textScale,
  ) {
    final s = layout.scale;
    final ax = s.xToPx(s.axisX);
    final ay = s.yToPx(s.axisY);
    final out = <Widget>[
      // I nomi degli assi accanto alle frecce.
      Positioned(
        right: 0,
        top: ay + 6,
        child: _Tex(payload.xLabel, color: c.textSecondary, scale: textScale),
      ),
      Positioned(
        left: ax + 10,
        top: 0,
        child: _Tex(payload.yLabel, color: c.textSecondary, scale: textScale),
      ),
    ];
    for (var i = 0; i < payload.items.length; i++) {
      final item = payload.items[i];
      if (item.label.isEmpty) continue;
      final color = colors[i];
      if (item is GraphPoint) {
        if (!s.containsX(item.at.x) || !s.containsY(item.at.y)) continue;
        final px = s.xToPx(item.at.x);
        final py = s.yToPx(item.at.y);
        // A nord-est del punto; a ovest se è vicino al bordo destro, sotto se
        // è vicino al bordo alto.
        final west = px > layout.width * 0.7;
        final south = py < 28 * textScale;
        out.add(
          Positioned(
            left: west ? null : px + 8,
            right: west ? layout.width - px + 8 : null,
            top: south ? py + 6 : null,
            bottom: south ? null : layout.height - py + 6,
            child: _Tex(item.label, color: color, scale: textScale, plate: c),
          ),
        );
      } else if (item is GraphLine) {
        final ends = layout.clip(item);
        if (ends == null) continue;
        final end = ends.$2;
        final px = s.xToPx(end.x);
        final py = s.yToPx(end.y);
        out.add(
          item.x != null
              ? Positioned(
                  left: px + 6,
                  top: s.rect.top,
                  child: _Tex(
                    item.label,
                    color: color,
                    scale: textScale,
                    plate: c,
                  ),
                )
              : Positioned(
                  right: layout.width - px,
                  bottom: layout.height - py + 4,
                  child: _Tex(
                    item.label,
                    color: color,
                    scale: textScale,
                    plate: c,
                  ),
                ),
        );
      } else if (item is GraphSegment && !item.arrow) {
        // Accanto al punto medio, scostata in perpendicolare dalla parte di
        // sopra: a nord-est starebbe sul segmento che sale.
        final a = Offset(s.xToPx(item.from.x), s.yToPx(item.from.y));
        final b = Offset(s.xToPx(item.to.x), s.yToPx(item.to.y));
        final d = b - a;
        if (d.distance < 1) continue;
        var n = Offset(-d.dy, d.dx) / d.distance;
        if (n.dy > 0 || (n.dy == 0 && n.dx < 0)) n = -n;
        final at = (a + b) / 2 + n * 14 * textScale;
        out.add(
          Positioned(
            left: at.dx,
            top: at.dy,
            child: FractionalTranslation(
              translation: const Offset(-0.5, -0.5),
              child: _Tex(item.label, color: color, scale: textScale, plate: c),
            ),
          ),
        );
      } else {
        final at = _anchorOf(item, layout, i);
        if (at == null) continue;
        final (pos, centered) = at;
        if (!s.containsX(pos.x) || !s.containsY(pos.y)) continue;
        final px = s.xToPx(pos.x), py = s.yToPx(pos.y);
        final tex = _Tex(item.label, color: color, scale: textScale, plate: c);
        out.add(
          centered
              ? Positioned(
                  left: px,
                  top: py,
                  child: FractionalTranslation(
                    translation: const Offset(-0.5, -0.5),
                    child: tex,
                  ),
                )
              : Positioned(
                  left: px + 6,
                  bottom: layout.height - py + 4,
                  child: tex,
                ),
        );
      }
    }
    return out;
  }

  /// Dove sta l'etichetta di una figura, e se ci sta centrata: al centro di
  /// aree, regioni e poligoni; sopra la circonferenza; a nord-est della
  /// punta di un vettore. Funzioni e curve sono
  /// in legenda.
  static (GraphXY, bool)? _anchorOf(
    GraphItem item,
    CartesianLayout layout,
    int index,
  ) {
    switch (item) {
      case GraphCircle(:final center, :final radius):
        return (GraphXY(center.x, center.y + radius), false);
      case GraphSegment(:final to):
        return (to, false);
      case GraphPolygon(:final points):
        return (_mean(points), true);
      case GraphArea() || GraphRegion():
        final shapes = layout.fills[index];
        if (shapes.isEmpty) return null;
        final largest = shapes.reduce((a, b) => a.length >= b.length ? a : b);
        return (_mean(largest), true);
      default:
        return null;
    }
  }

  static GraphXY _mean(List<GraphXY> points) {
    var x = 0.0, y = 0.0;
    for (final p in points) {
      x += p.x;
      y += p.y;
    }
    return GraphXY(x / points.length, y / points.length);
  }

  /// Le etichette della retta numerica: ognuna sopra la sua riga, al centro
  /// della parte che si vede; il nome della retta sotto la freccia.
  List<Widget> _numberLineLabels(
    NumberLineLayout layout,
    AppPalette c,
    List<Color> colors,
    double textScale,
  ) {
    final s = layout.scale;
    final out = <Widget>[
      Positioned(
        right: 0,
        top: layout.axis + 6,
        child: _Tex(payload.xLabel, color: c.textSecondary, scale: textScale),
      ),
    ];
    for (var i = 0; i < payload.items.length; i++) {
      final item = payload.items[i];
      if (item.label.isEmpty) continue;
      final double x;
      switch (item) {
        case GraphInterval(:final from, :final to):
          final x0 = from == null ? s.rect.left : s.xToPx(from);
          final x1 = to == null ? s.rect.right : s.xToPx(to);
          x =
              (x0.clamp(s.rect.left, s.rect.right) +
                  x1.clamp(s.rect.left, s.rect.right)) /
              2;
        case GraphPoint(:final at):
          x = s.xToPx(at.x);
        default:
          continue;
      }
      out.add(
        Positioned(
          left: x,
          bottom: layout.height - layout.rowY(i) + 7,
          child: FractionalTranslation(
            translation: const Offset(-0.5, 0),
            child: _Tex(
              item.label,
              color: colors[i],
              scale: textScale,
              plate: c,
            ),
          ),
        ),
      );
    }
    return out;
  }

  List<Widget> _barLabels(BarsLayout layout, AppPalette c, double textScale) {
    return [
      if (payload.yLabel.isNotEmpty)
        Positioned(
          left: 0,
          top: 0,
          child: _Tex(payload.yLabel, color: c.textSecondary, scale: textScale),
        ),
      if (payload.xLabel.isNotEmpty)
        Positioned(
          right: 0,
          bottom: 0,
          child: _Tex(payload.xLabel, color: c.textSecondary, scale: textScale),
        ),
    ];
  }

  /// La legenda: funzioni e curve (o le serie delle barre, se sono più d'una)
  /// con il loro nome in LaTeX. Le altre figure hanno l'etichetta accanto.
  List<Widget> _legend(List<Color> colors) {
    if (payload.plane == GraphPlane.bars) {
      if (payload.series.length < 2) return const [];
      return [
        for (var i = 0; i < payload.series.length; i++)
          if (payload.series[i].label.isNotEmpty)
            _LegendItem(label: payload.series[i].label, color: colors[i]),
      ];
    }
    return [
      for (var i = 0; i < payload.items.length; i++)
        if ((payload.items[i] is GraphFunction ||
                payload.items[i] is GraphCurve) &&
            payload.items[i].label.isNotEmpty)
          _LegendItem(
            label: payload.items[i].label,
            color: colors[i],
            dashed: payload.items[i].style == GraphLineStyle.dashed,
          ),
    ];
  }

  /// Quello che lo screen reader legge al posto del disegno.
  String _describe() {
    final labels = payload.plane == GraphPlane.bars
        ? [for (final s in payload.series) s.label]
        : [for (final i in payload.items) i.label];
    final named = labels.where((l) => l.isNotEmpty).toList();
    return named.isEmpty
        ? payload.plane.label
        : '${payload.plane.label}: ${named.join(', ')}';
  }
}

/// Un'etichetta in LaTeX. Sul piano ha una piastrina chiara ([plate]), così
/// si legge anche sopra la griglia e le curve. Se il LaTeX non si legge,
/// resta il testo com'è scritto.
class _Tex extends StatelessWidget {
  final String tex;
  final Color color;
  final double scale;
  final AppPalette? plate;

  const _Tex(this.tex, {required this.color, required this.scale, this.plate});

  @override
  Widget build(BuildContext context) {
    final size = AppText.label * scale;
    final math = Math.tex(
      tex,
      textStyle: TextStyle(fontSize: size, color: color),
      options: MathOptions(fontSize: size, color: color),
      onErrorFallback: (_) => Text(
        tex,
        style: TextStyle(
          fontFamily: AppText.bodyFont,
          fontSize: size,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
    final p = plate;
    if (p == null) return math;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: p.surface.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
        child: math,
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final String label;
  final Color color;
  final bool dashed;

  const _LegendItem({
    required this.label,
    required this.color,
    this.dashed = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 18,
          height: 4,
          child: dashed
              // Due pezzi alti 4: un `ColoredBox` senza figlio in una `Row`
              // avrebbe altezza zero e il trattino sparirebbe.
              ? Row(
                  children: [
                    Expanded(child: Container(height: 4, color: color)),
                    const SizedBox(width: 3),
                    Expanded(child: Container(height: 4, color: color)),
                  ],
                )
              : DecoratedBox(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
        ),
        const SizedBox(width: 6),
        _Tex(label, color: c.textPrimary, scale: textScaleFactorOf(context)),
      ],
    );
  }
}
