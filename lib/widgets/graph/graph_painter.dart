import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../models/multifunction_box/box_payload.dart';
import '../../theme/app_text.dart';
import '../../theme/chart_palette.dart';
import 'graph_layout.dart';
import 'graph_scale.dart';

/// I colori e la scala del testo di un grafico, confrontati per valore: lo
/// stile si rifà a ogni build e senza `==` il painter ridisegnerebbe sempre.
@immutable
class GraphStyle {
  final ChartPalette palette;

  /// Il colore di ogni elemento (o serie), nello stesso ordine del payload.
  final List<Color> colors;

  /// Il fondo della card, per l'anello bianco dei punti.
  final Color surface;
  final double textScale;

  const GraphStyle({
    required this.palette,
    required this.colors,
    required this.surface,
    this.textScale = 1,
  });

  @override
  bool operator ==(Object other) =>
      other is GraphStyle &&
      other.palette == palette &&
      listEquals(other.colors, colors) &&
      other.surface == surface &&
      other.textScale == textScale;

  @override
  int get hashCode =>
      Object.hash(palette, Object.hashAll(colors), surface, textScale);
}

/// L'opacità di aree, regioni e figure piene: si vede la griglia attraverso.
const double _kFillAlpha = 0.16;

/// La lunghezza della punta di un vettore, in pixel.
const double _kArrowLength = 11;

/// Testo dei numeri sugli assi: `micro`, scalato col testo del sistema.
const double _kTickFont = AppText.micro;

/// Il segno meno tipografico: `-2` sull'asse si legge `−2`.
String _minus(String label) => label.replaceFirst('-', '−');

void _text(
  Canvas canvas,
  String text,
  Offset at,
  GraphStyle style, {
  Alignment anchor = Alignment.topCenter,
  Color? color,
  FontStyle? fontStyle,
}) {
  TextPainter painter(Paint? halo) => TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
        fontFamily: AppText.bodyFont,
        fontSize: _kTickFont * style.textScale,
        fontWeight: FontWeight.w500,
        fontStyle: fontStyle,
        color: halo == null ? (color ?? style.palette.label) : null,
        foreground: halo,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  // Un alone del colore della card sotto il numero: si legge anche sopra la
  // griglia e le curve.
  final under = painter(
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeJoin = StrokeJoin.round
      ..color = style.surface,
  );
  final tp = painter(null);
  // [anchor] dice quale punto del testo sta su [at]: topCenter = il testo
  // sta sotto, centrato.
  final at0 = Offset(
    at.dx - tp.width * (anchor.x + 1) / 2,
    at.dy - tp.height * (anchor.y + 1) / 2,
  );
  under.paint(canvas, at0);
  tp.paint(canvas, at0);
  under.dispose();
  tp.dispose();
}

/// Un tratto continuo o tratteggiato, tagliato a [progress] della lunghezza.
void _stroke(
  Canvas canvas,
  Path path,
  Paint paint, {
  bool dashed = false,
  double progress = 1,
}) {
  if (progress >= 1 && !dashed) {
    canvas.drawPath(path, paint);
    return;
  }
  final metrics = path.computeMetrics().toList();
  final total = metrics.fold<double>(0, (a, m) => a + m.length);
  var budget = total * progress.clamp(0.0, 1.0);
  for (final metric in metrics) {
    if (budget <= 0) break;
    final length = math.min(metric.length, budget);
    budget -= metric.length;
    if (!dashed) {
      canvas.drawPath(metric.extractPath(0, length), paint);
      continue;
    }
    const dash = 7.0, gap = 5.0;
    for (var d = 0.0; d < length; d += dash + gap) {
      canvas.drawPath(metric.extractPath(d, math.min(d + dash, length)), paint);
    }
  }
}

/// Il piano cartesiano: griglia, assi per l'origine con le frecce, numeri,
/// riempimenti (aree, regioni, poligoni), bordi delle regioni, rette,
/// funzioni, curve, circonferenze, segmenti, vettori e punti. Le etichette in LaTeX non sono qui: sono widget
/// sopra il disegno (`GraphView`).
class CartesianPainter extends CustomPainter {
  final GraphPayload payload;
  final CartesianLayout layout;
  final GraphStyle style;
  final double progress;

  const CartesianPainter({
    required this.payload,
    required this.layout,
    required this.style,
    this.progress = 1,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final s = layout.scale;
    final rect = Rect.fromLTRB(
      s.rect.left,
      s.rect.top,
      s.rect.right,
      s.rect.bottom,
    );
    final p = style.palette;
    final ax = s.xToPx(s.axisX);
    final ay = s.yToPx(s.axisY);

    // Griglia.
    final grid = Paint()
      ..color = p.grid
      ..strokeWidth = 1;
    for (final t in layout.xTicks) {
      final x = s.xToPx(t.value);
      canvas.drawLine(Offset(x, rect.top), Offset(x, rect.bottom), grid);
    }
    for (final t in layout.yTicks) {
      final y = s.yToPx(t.value);
      canvas.drawLine(Offset(rect.left, y), Offset(rect.right, y), grid);
    }

    // Riempimenti, poi bordi delle regioni, poi rette, poi i tracciati, poi
    // i punti: ciò che si legge per primo sta sopra.
    canvas.save();
    canvas.clipRect(rect.inflate(1));
    for (var i = 0; i < payload.items.length; i++) {
      if (i >= layout.fills.length) break;
      final paint = Paint()
        ..color = style.colors[i].withValues(alpha: _kFillAlpha * progress);
      for (final shape in layout.fills[i]) {
        if (shape.length < 3) continue;
        canvas.drawPath(_path(shape)..close(), paint);
      }
    }
    for (var i = 0; i < payload.items.length; i++) {
      if (i >= layout.edges.length) break;
      for (final edge in layout.edges[i]) {
        final path = Path();
        for (final segment in edge.segments) {
          if (segment.length > 1) path.addPath(_path(segment), Offset.zero);
        }
        _stroke(
          canvas,
          path,
          Paint()
            ..color = style.colors[i]
            ..strokeWidth = 2
            ..style = PaintingStyle.stroke,
          dashed: edge.dashed,
          progress: progress,
        );
      }
    }
    for (var i = 0; i < payload.items.length; i++) {
      final item = payload.items[i];
      final color = style.colors[i];
      if (item is GraphLine) {
        final ends = layout.clip(item);
        if (ends == null) continue;
        _stroke(
          canvas,
          Path()
            ..moveTo(s.xToPx(ends.$1.x), s.yToPx(ends.$1.y))
            ..lineTo(s.xToPx(ends.$2.x), s.yToPx(ends.$2.y)),
          Paint()
            ..color = color
            ..strokeWidth = 2
            ..style = PaintingStyle.stroke,
          dashed: item.style == GraphLineStyle.dashed,
          progress: progress,
        );
      }
    }
    for (var i = 0; i < payload.items.length; i++) {
      final item = payload.items[i];
      Path path;
      switch (item) {
        case GraphFunction() || GraphCurve() || GraphCircle():
          path = Path();
          for (final segment in layout.samples[i]) {
            if (segment.length > 1) path.addPath(_path(segment), Offset.zero);
          }
        case GraphPolygon(:final points):
          path = _path(points)..close();
        case GraphSegment(:final from, :final to, :final arrow):
          path = _path([from, to]);
          // Il gambo del vettore si ferma alla base della punta: il cappuccio
          // tondo sporgerebbe oltre.
          if (arrow) {
            final m = path.computeMetrics().firstOrNull;
            if (m != null && m.length > _kArrowLength) {
              path = m.extractPath(0, m.length - _kArrowLength + 1);
            }
          }
        default:
          continue;
      }
      _stroke(
        canvas,
        path,
        Paint()
          ..color = style.colors[i]
          ..strokeWidth = item is GraphFunction || item is GraphCurve
              ? 2.6
              : 2.2
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
        dashed: item.style == GraphLineStyle.dashed,
        progress: progress,
      );
      if (item is GraphSegment && item.arrow) {
        _arrowHead(canvas, item, style.colors[i]);
      }
    }
    canvas.restore();

    // Assi per l'origine (o sul bordo se lo zero è fuori), con le frecce.
    final axis = Paint()
      ..color = p.axis
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(rect.left, ay), Offset(rect.right + 10, ay), axis);
    canvas.drawLine(Offset(ax, rect.bottom), Offset(ax, rect.top - 10), axis);
    final head = Paint()..color = p.axis;
    canvas.drawPath(
      Path()
        ..moveTo(rect.right + 14, ay)
        ..lineTo(rect.right + 5, ay - 4.5)
        ..lineTo(rect.right + 5, ay + 4.5)
        ..close(),
      head,
    );
    canvas.drawPath(
      Path()
        ..moveTo(ax, rect.top - 14)
        ..lineTo(ax - 4.5, rect.top - 5)
        ..lineTo(ax + 4.5, rect.top - 5)
        ..close(),
      head,
    );

    // Tacche e numeri: lo zero non si scrive, all'origine c'è «O».
    for (var i = 0; i < layout.xTicks.length; i++) {
      final t = layout.xTicks[i];
      if (t.value.abs() < 1e-9 && layout.showsOrigin) continue;
      if (!_labelled(layout.xTicks, t.value, layout.xLabelEvery)) continue;
      final x = s.xToPx(t.value);
      // Accanto all'asse y il numero si accavallerebbe con i suoi e con «O».
      if ((x - ax).abs() < 12 * style.textScale) continue;
      canvas.drawLine(Offset(x, ay - 3), Offset(x, ay + 3), axis);
      _text(canvas, _minus(t.label), Offset(x, ay + 5), style);
    }
    for (final t in layout.yTicks) {
      if (t.value.abs() < 1e-9 && layout.showsOrigin) continue;
      if (!_labelled(layout.yTicks, t.value, layout.yLabelEvery)) continue;
      final y = s.yToPx(t.value);
      if ((y - ay).abs() < 12 * style.textScale) continue;
      canvas.drawLine(Offset(ax - 3, y), Offset(ax + 3, y), axis);
      _text(
        canvas,
        _minus(t.label),
        Offset(ax - 6, y),
        style,
        anchor: Alignment.centerRight,
      );
    }
    if (layout.showsOrigin) {
      _text(
        canvas,
        'O',
        Offset(ax - 5, ay + 4),
        style,
        anchor: Alignment.topRight,
        fontStyle: FontStyle.italic,
      );
    }

    // Gli estremi dei segmenti: due punti pieni, più piccoli dei punti.
    for (var i = 0; i < payload.items.length; i++) {
      final item = payload.items[i];
      if (item is! GraphSegment || item.arrow) continue;
      for (final end in [item.from, item.to]) {
        if (!s.containsX(end.x) || !s.containsY(end.y)) continue;
        final c = Offset(s.xToPx(end.x), s.yToPx(end.y));
        final r = 3.4 * progress;
        canvas.drawCircle(c, r + 1.6, Paint()..color = style.surface);
        canvas.drawCircle(c, r, Paint()..color = style.colors[i]);
      }
    }

    // Punti, con le proiezioni tratteggiate sugli assi.
    for (var i = 0; i < payload.items.length; i++) {
      final item = payload.items[i];
      if (item is! GraphPoint) continue;
      if (!s.containsX(item.at.x) || !s.containsY(item.at.y)) continue;
      final c = Offset(s.xToPx(item.at.x), s.yToPx(item.at.y));
      final color = style.colors[i];
      if (item.guides) {
        final guide = Paint()
          ..color = color.withValues(alpha: 0.6 * progress)
          ..strokeWidth = 1.4
          ..style = PaintingStyle.stroke;
        _stroke(
          canvas,
          Path()
            ..moveTo(c.dx, ay)
            ..lineTo(c.dx, c.dy)
            ..lineTo(ax, c.dy),
          guide,
          dashed: true,
        );
      }
      final r = 4.5 * progress;
      canvas.drawCircle(c, r + 2, Paint()..color = style.surface);
      canvas.drawCircle(c, r, Paint()..color = color);
    }
  }

  Path _path(List<GraphXY> points) {
    final s = layout.scale;
    final path = Path()
      ..moveTo(s.xToPx(points.first.x), s.yToPx(points.first.y));
    for (final pt in points.skip(1)) {
      path.lineTo(s.xToPx(pt.x), s.yToPx(pt.y));
    }
    return path;
  }

  /// La punta di un vettore: un triangolo pieno sulla punta, orientato come
  /// il segmento. Compare con l'ultimo tratto dell'entrata.
  void _arrowHead(Canvas canvas, GraphSegment v, Color color) {
    if (progress < 1) return;
    final s = layout.scale;
    final tip = Offset(s.xToPx(v.to.x), s.yToPx(v.to.y));
    final tail = Offset(s.xToPx(v.from.x), s.yToPx(v.from.y));
    final d = tip - tail;
    if (d.distance < 1) return;
    final u = d / d.distance;
    final n = Offset(-u.dy, u.dx);
    const half = 5.0;
    final base = tip - u * _kArrowLength;
    canvas.drawPath(
      Path()
        ..moveTo(tip.dx, tip.dy)
        ..lineTo((base + n * half).dx, (base + n * half).dy)
        ..lineTo((base - n * half).dx, (base - n * half).dy)
        ..close(),
      Paint()..color = color,
    );
  }

  /// `true` se il tick [value] porta il numero: uno ogni [every], contando
  /// dallo zero, così con un passo 1 si leggono 0, 2, 4 e non 1, 3, 5.
  static bool _labelled(List<GraphTick> ticks, double value, int every) {
    if (every <= 1 || ticks.length < 2) return true;
    final step = ticks[1].value - ticks[0].value;
    return (value / step).round() % every == 0;
  }

  @override
  bool shouldRepaint(CartesianPainter old) =>
      old.payload != payload ||
      old.layout != layout ||
      old.style != style ||
      old.progress != progress;
}

/// Le barre: una casella per categoria, la base sullo zero, la griglia
/// orizzontale coi numeri a sinistra e le categorie sotto.
class BarsPainter extends CustomPainter {
  final GraphPayload payload;
  final BarsLayout layout;
  final GraphStyle style;
  final double progress;

  const BarsPainter({
    required this.payload,
    required this.layout,
    required this.style,
    this.progress = 1,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final s = layout.scale;
    final p = style.palette;
    final left = s.rect.left, right = s.rect.right;
    final grid = Paint()
      ..color = p.grid
      ..strokeWidth = 1;
    for (final t in layout.yTicks) {
      final y = s.yToPx(t.value);
      canvas.drawLine(Offset(left, y), Offset(right, y), grid);
      _text(
        canvas,
        _minus(t.label),
        Offset(left - 6, y),
        style,
        anchor: Alignment.centerRight,
      );
    }
    final zero = s.yToPx(s.containsY(0) ? 0 : s.minY);
    final series = payload.series;
    final geom = barGeometry(
      plotWidth: s.rect.width,
      groups: layout.groups,
      series: series.length,
    );
    final cell = s.rect.width / layout.groups;
    for (var g = 0; g < layout.groups; g++) {
      final cellLeft = left + cell * g;
      final groupWidth =
          geom.width * series.length + geom.gap * (series.length - 1);
      final start = cellLeft + (cell - groupWidth) / 2;
      for (var k = 0; k < series.length; k++) {
        final values = series[k].values;
        final v = g < values.length ? values[g] : null;
        // Una casella senza valore non disegna niente: una barra di altezza
        // zero sembrerebbe un dato.
        if (v == null) continue;
        final top = s.yToPx(v);
        final height = (zero - top).abs() * progress;
        if (height <= 0) continue;
        final up = v >= 0;
        final bar = Rect.fromLTWH(
          start + k * (geom.width + geom.gap),
          up ? zero - height : zero,
          geom.width,
          height,
        );
        const r = Radius.circular(5);
        canvas.drawRRect(
          RRect.fromRectAndCorners(
            bar,
            topLeft: up ? r : Radius.zero,
            topRight: up ? r : Radius.zero,
            bottomLeft: up ? Radius.zero : r,
            bottomRight: up ? Radius.zero : r,
          ),
          Paint()..color = style.colors[k],
        );
      }
      if (g < payload.categories.length && g % layout.labelEvery == 0) {
        _text(
          canvas,
          _minus(payload.categories[g]),
          Offset(cellLeft + cell / 2, s.rect.bottom + 6),
          style,
        );
      }
    }
    final axis = Paint()
      ..color = p.axis
      ..strokeWidth = 1.6;
    canvas.drawLine(Offset(left, zero), Offset(right, zero), axis);
    canvas.drawLine(
      Offset(left, s.rect.top - 6),
      Offset(left, s.rect.bottom),
      axis,
    );
  }

  @override
  bool shouldRepaint(BarsPainter old) =>
      old.payload != payload ||
      old.layout != layout ||
      old.style != style ||
      old.progress != progress;
}

/// La retta numerica: la retta con la freccia e i numeri sotto, e sopra una
/// riga per intervallo. Un intervallo è una barra con gli estremi a pallino,
/// pieno se incluso e vuoto se escluso; verso l'infinito la barra arriva al
/// bordo. Dagli estremi scende una guida tratteggiata alla retta. I punti
/// stanno sulla retta.
class NumberLinePainter extends CustomPainter {
  final GraphPayload payload;
  final NumberLineLayout layout;
  final GraphStyle style;
  final double progress;

  const NumberLinePainter({
    required this.payload,
    required this.layout,
    required this.style,
    this.progress = 1,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final s = layout.scale;
    final p = style.palette;
    final ay = layout.axis;
    final left = s.rect.left, right = s.rect.right;

    // Le guide, sotto tutto.
    for (var i = 0; i < payload.items.length; i++) {
      final item = payload.items[i];
      final xs = switch (item) {
        GraphInterval(:final from, :final to) => [?from, ?to],
        _ => const <double>[],
      };
      final guide = Paint()
        ..color = style.colors[i].withValues(alpha: 0.45 * progress)
        ..strokeWidth = 1.2
        ..style = PaintingStyle.stroke;
      for (final x in xs) {
        if (!s.containsX(x)) continue;
        final px = s.xToPx(x);
        _stroke(
          canvas,
          Path()
            ..moveTo(px, layout.rowY(i))
            ..lineTo(px, ay),
          guide,
          dashed: true,
        );
      }
    }

    // La retta, con la freccia e i numeri.
    final axis = Paint()
      ..color = p.axis
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(left - 6, ay), Offset(right + 10, ay), axis);
    canvas.drawPath(
      Path()
        ..moveTo(right + 14, ay)
        ..lineTo(right + 5, ay - 4.5)
        ..lineTo(right + 5, ay + 4.5)
        ..close(),
      Paint()..color = p.axis,
    );
    for (final t in layout.ticks) {
      final x = s.xToPx(t.value);
      canvas.drawLine(Offset(x, ay - 4), Offset(x, ay + 4), axis);
      _text(canvas, _minus(t.label), Offset(x, ay + 6), style);
    }

    // Gli elementi, ognuno sulla sua riga.
    for (var i = 0; i < payload.items.length; i++) {
      final item = payload.items[i];
      final color = style.colors[i];
      final y = layout.rowY(i);
      switch (item) {
        case GraphInterval():
          final from = item.from, to = item.to;
          final x0 = from == null ? left - 6 : s.xToPx(from);
          final x1 = to == null ? right + 6 : s.xToPx(to);
          _stroke(
            canvas,
            Path()
              ..moveTo(x0, y)
              ..lineTo(x1, y),
            Paint()
              ..color = color
              ..strokeWidth = 4
              ..strokeCap = StrokeCap.round
              ..style = PaintingStyle.stroke,
            progress: progress,
          );
          if (from != null) _end(canvas, Offset(x0, y), color, item.fromOpen);
          if (to != null) _end(canvas, Offset(x1, y), color, item.toOpen);
        case GraphPoint(:final at):
          if (!s.containsX(at.x)) continue;
          _end(canvas, Offset(s.xToPx(at.x), y), color, false);
        default:
          break;
      }
    }
  }

  /// Un estremo: pieno se incluso, vuoto (il fondo della card con il bordo
  /// del colore) se escluso.
  void _end(Canvas canvas, Offset c, Color color, bool open) {
    final r = 5.5 * progress;
    if (r <= 0) return;
    if (open) {
      canvas.drawCircle(c, r, Paint()..color = style.surface);
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..color = color
          ..strokeWidth = 2.4
          ..style = PaintingStyle.stroke,
      );
    } else {
      canvas.drawCircle(c, r + 1.6, Paint()..color = style.surface);
      canvas.drawCircle(c, r, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(NumberLinePainter old) =>
      old.payload != payload ||
      old.layout != layout ||
      old.style != style ||
      old.progress != progress;
}
