import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../models/multifunction_box/box_payload.dart';
import '../../theme/app_text.dart';
import '../../theme/chart_palette.dart';
import 'chart_scale.dart';

/// I colori di un grafico, presi dalla palette dell'app e non da costanti: il
/// grafico è dentro una card di lezione e in scuro gli assi di un grigio
/// chiaro sparirebbero.
class ChartStyle {
  final ChartPalette palette;
  final double textScale;

  const ChartStyle({required this.palette, this.textScale = 1});

  Color get grid => palette.grid;
  Color get axis => palette.axis;
  Color get label => palette.label;

  /// Le etichette seguono la scala del sistema, come in `MathText`: un
  /// `TextPainter` non eredita il `textScaler` da solo.
  double font(double base) => base * textScale;

  /// Per valore, non per identità: lo stile è ricostruito a ogni build e senza
  /// questo `shouldRepaint` ridisegnerebbe il grafico anche quando è identico.
  @override
  bool operator ==(Object other) =>
      other is ChartStyle &&
      other.palette == palette &&
      other.textScale == textScale;

  @override
  int get hashCode => Object.hash(palette, textScale);
}

/// Testo dei tick: [AppText.micro] come base, scalato dalla scala del sistema.
const double _tickBase = 11;

/// Quanti punti disegnati singolarmente su una linea: sopra questo numero il
/// pallino diventa rumore (i campionamenti di una funzione sono 160).
const int _maxDots = 40;

/// L'area disegnabile: il dominio (`scale`) e i suoi pixel (`rect`).
class ChartFrame {
  final ChartScale scale;
  final Rect rect;

  const ChartFrame(this.scale, this.rect);
}

ChartFrame? _frameOf(List<ChartPoint> all, Size size, ChartStyle style) {
  if (all.isEmpty) return null;
  var minX = all.first.x;
  var maxX = all.first.x;
  var minY = all.first.y;
  var maxY = all.first.y;
  for (final p in all) {
    minX = math.min(minX, p.x);
    maxX = math.max(maxX, p.x);
    minY = math.min(minY, p.y);
    maxY = math.max(maxY, p.y);
  }
  final nice = niceRange(minY, maxY);
  final left = 34.0 * style.textScale;
  final right = size.width - 8;
  final top = 8.0;
  final bottom = size.height - 22.0 * style.textScale;
  if (right <= left || bottom <= top) return null;
  return ChartFrame(
    ChartScale(
      minX: minX,
      maxX: maxX == minX ? minX + 1 : maxX,
      minY: nice.min,
      maxY: nice.max,
      rect: RectD(left, top, right - left, bottom - top),
    ),
    Rect.fromLTRB(left, top, right, bottom),
  );
}

void _drawGrid(
  Canvas canvas,
  ChartFrame frame,
  ChartStyle style, {
  bool strongZero = false,
}) {
  final ticks = niceTicks(frame.scale.minY, frame.scale.maxY);
  final paint = Paint()..strokeWidth = 1;
  for (final t in ticks) {
    final y = frame.scale.yToPx(t.value);
    final isZero = t.value.abs() < 1e-9;
    paint.color = strongZero && isZero
        ? style.axis
        : style.grid.withValues(alpha: isZero ? 0.9 : 1);
    paint.strokeWidth = strongZero && isZero ? 1.4 : 1;
    canvas.drawLine(
      Offset(frame.rect.left, y),
      Offset(frame.rect.right, y),
      paint,
    );
    final tp = TextPainter(
      text: TextSpan(
        text: t.label,
        style: TextStyle(fontSize: style.font(_tickBase), color: style.label),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(frame.rect.left - 6 - tp.width, y - tp.height / 2));
    tp.dispose();
  }
}

void _drawAxes(Canvas canvas, ChartFrame frame, ChartStyle style) {
  final paint = Paint()
    ..color = style.axis.withValues(alpha: 0.5)
    ..strokeWidth = 1;
  canvas.drawLine(
    Offset(frame.rect.left, frame.rect.bottom),
    Offset(frame.rect.right, frame.rect.bottom),
    paint,
  );
  canvas.drawLine(
    Offset(frame.rect.left, frame.rect.top),
    Offset(frame.rect.left, frame.rect.bottom),
    paint,
  );
}

void _drawAxisLabels(
  Canvas canvas,
  ChartFrame frame,
  ChartStyle style, {
  required String xLabel,
  required String yLabel,
}) {
  if (xLabel.isEmpty && yLabel.isEmpty) return;
  final base = TextStyle(
    fontSize: style.font(AppText.micro),
    color: style.label,
    fontWeight: FontWeight.w600,
  );
  if (xLabel.isNotEmpty) {
    final tp = TextPainter(
      text: TextSpan(text: xLabel, style: base),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset(
        frame.rect.center.dx - tp.width / 2,
        frame.rect.bottom + 12 * style.textScale,
      ),
    );
    tp.dispose();
  }
  if (yLabel.isEmpty) return;
  final yTp = TextPainter(
    text: TextSpan(text: yLabel, style: base),
    textDirection: TextDirection.ltr,
  )..layout();
  canvas.save();
  canvas.translate(11 * style.textScale, frame.rect.center.dy + yTp.width / 2);
  canvas.rotate(-math.pi / 2);
  yTp.paint(canvas, Offset(-yTp.width / 2, -yTp.height / 2));
  canvas.restore();
  yTp.dispose();
}

Path _smoothPath(List<Offset> points) {
  final path = Path()..moveTo(points.first.dx, points.first.dy);
  for (var i = 0; i < points.length - 1; i++) {
    final p0 = i == 0 ? points[i] : points[i - 1];
    final p1 = points[i];
    final p2 = points[i + 1];
    final p3 = i + 2 < points.length ? points[i + 2] : p2;
    final c1 = Offset(p1.dx + (p2.dx - p0.dx) / 6, p1.dy + (p2.dy - p0.dy) / 6);
    final c2 = Offset(p2.dx - (p3.dx - p1.dx) / 6, p2.dy - (p3.dy - p1.dy) / 6);
    path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, p2.dx, p2.dy);
  }
  return path;
}

Path _polyPath(List<Offset> points) {
  final path = Path()..moveTo(points.first.dx, points.first.dy);
  for (final p in points.skip(1)) {
    path.lineTo(p.dx, p.dy);
  }
  return path;
}

/// Ritaglia il path a [progress] della sua lunghezza: è l'entrata progressiva,
/// disegnata una volta sola e senza nessun gesture.
Path _truncate(Path path, double progress) {
  if (progress >= 1) return path;
  final total = path.computeMetrics().fold<double>(0, (a, m) => a + m.length);
  if (total <= 0) return Path();
  final want = total * progress.clamp(0.0, 1.0);
  final out = Path();
  var done = 0.0;
  for (final metric in path.computeMetrics()) {
    if (done >= want) break;
    final take = math.min(metric.length, want - done);
    out.addPath(metric.extractPath(0, take), Offset.zero);
    done += metric.length;
  }
  return out;
}

/// Barre e istogrammi: una casella per voce di `xLabels`, base a zero anche con
/// valori negativi.
class BarChartPainter extends CustomPainter {
  final ChartBoxPayload payload;
  final List<Color> colors;
  final ChartStyle style;
  final double progress;

  BarChartPainter({
    required this.payload,
    required this.colors,
    required this.style,
    this.progress = 1,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final series = payload.series
        .where((s) => s.values.any((v) => v != null))
        .toList();
    if (series.isEmpty) return;
    final frame = _frameOf(
      [
        for (final s in series)
          for (var i = 0; i < s.values.length; i++)
            if (s.values[i] != null)
              ChartPoint(i.toDouble(), s.values[i]!.toDouble()),
      ],
      size,
      style,
    );
    if (frame == null) return;

    _drawGrid(canvas, frame, style);
    _drawAxes(canvas, frame, style);
    _drawAxisLabels(
      canvas,
      frame,
      style,
      xLabel: payload.xLabel,
      yLabel: payload.yLabel,
    );

    final groups = barGroupCount(payload);
    final geom = barGeometry(
      plotWidth: frame.rect.width,
      groups: groups,
      series: series.length,
    );
    final labels = payload.xLabels;
    final labelStep = _labelStep(labels.length, frame.rect.width, style);
    final zeroY = frame.scale.yToPx(
      frame.scale.minY < 0 ? 0 : frame.scale.minY,
    );

    for (var g = 0; g < groups; g++) {
      final cellLeft = frame.rect.left + (frame.rect.width / groups) * g;
      final startX =
          cellLeft +
          ((frame.rect.width / groups) -
                  geom.width * series.length -
                  geom.gap * (series.length - 1)) /
              2;
      for (var s = 0; s < series.length; s++) {
        // Una casella senza altezza non disegna niente: niente barra di altezza
        // zero, che sembrerebbe un dato contato.
        final value = g < series[s].values.length ? series[s].values[g] : null;
        if (value == null) continue;
        final v = value.toDouble();
        final top = frame.scale.yToPx(v);
        final full = Rect.fromLTWH(
          startX + s * (geom.width + geom.gap),
          math.min(zeroY, top),
          geom.width,
          (zeroY - top).abs(),
        );
        if (full.height <= 0 || full.width <= 0) continue;
        final grown = Rect.fromLTWH(
          full.left,
          v >= 0 ? full.top : full.bottom - full.height * progress,
          full.width,
          full.height * progress,
        );
        canvas.drawRRect(
          RRect.fromRectAndCorners(
            grown,
            topLeft: const Radius.circular(4),
            topRight: const Radius.circular(4),
            bottomLeft: v >= 0 ? Radius.zero : const Radius.circular(4),
            bottomRight: v >= 0 ? Radius.zero : const Radius.circular(4),
          ),
          Paint()..color = colors[s % colors.length],
        );
      }
      if (g < labels.length && g % labelStep == 0) {
        _drawTickLabel(
          canvas,
          labels[g],
          Offset(cellLeft + frame.rect.width / groups / 2, frame.rect.bottom),
          style,
        );
      }
    }
    final unit = payload.unit;
    if (unit.isNotEmpty) {
      _drawTickLabel(
        canvas,
        unit,
        Offset(frame.rect.left - 4, frame.rect.top - 2),
        style,
        alignRight: true,
      );
    }
  }

  int _labelStep(int count, double width, ChartStyle style) {
    final room = width / math.max(1, count);
    final needed = 24.0 * style.textScale;
    return math.max(1, (needed / room).ceil());
  }

  void _drawTickLabel(
    Canvas canvas,
    String text,
    Offset at,
    ChartStyle style, {
    bool alignRight = false,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(fontSize: style.font(_tickBase), color: style.label),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    tp.paint(
      canvas,
      Offset(alignRight ? at.dx - tp.width : at.dx - tp.width / 2, at.dy + 6),
    );
    tp.dispose();
  }

  @override
  bool shouldRepaint(covariant BarChartPainter old) =>
      old.payload != payload ||
      !listEquals(old.colors, colors) ||
      old.style != style ||
      old.progress != progress;
}

/// Linee e curve: sfondo con gradiente sotto il tracciato, buchi rispettati,
/// pallini solo quando i punti sono pochi.
class LineChartPainter extends CustomPainter {
  final ChartBoxPayload payload;
  final List<Color> colors;
  final ChartStyle style;
  final double progress;
  final bool fill;

  /// I campioni di [segmentsOf], calcolati una volta da chi crea il painter:
  /// il painter si ricrea a ogni frame dell'entrata, e ricampionare la funzione
  /// ogni volta rifarebbe il parsing dell'espressione per ogni punto.
  final List<List<List<ChartPoint>>>? segments;

  LineChartPainter({
    required this.payload,
    required this.colors,
    required this.style,
    this.progress = 1,
    this.fill = true,
    this.segments,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final segments = this.segments ?? segmentsOf(payload);
    if (segments.isEmpty) return;
    final frame = _frameOf(
      [
        for (final serie in segments)
          for (final seg in serie) ...seg,
      ],
      size,
      style,
    );
    if (frame == null) return;

    _drawGrid(canvas, frame, style, strongZero: frame.scale.crossesZero);
    _drawAxes(canvas, frame, style);
    _drawAxisLabels(
      canvas,
      frame,
      style,
      xLabel: payload.xLabel,
      yLabel: payload.yLabel,
    );

    for (var s = 0; s < segments.length; s++) {
      final color = colors[s % colors.length];
      for (final segment in segments[s]) {
        if (segment.length < 2) continue;
        final offsets = [
          for (final p in segment)
            Offset(frame.scale.xToPx(p.x), frame.scale.yToPx(p.y)),
        ];
        final path = payload.smooth && segment.length > 2
            ? _smoothPath(offsets)
            : _polyPath(offsets);
        final shown = _truncate(path, progress);
        if (fill) {
          final area = Path.from(shown)
            ..lineTo(offsets.last.dx, frame.rect.bottom)
            ..lineTo(offsets.first.dx, frame.rect.bottom)
            ..close();
          canvas.drawPath(
            area,
            Paint()
              ..shader = LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  color.withValues(alpha: 0.22),
                  color.withValues(alpha: 0.02),
                ],
              ).createShader(area.getBounds()),
          );
        }
        canvas.drawPath(
          shown,
          Paint()
            ..color = color
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round,
        );
        if (segment.length <= _maxDots && progress >= 1) {
          final dot = Paint()..color = color;
          for (final p in segment) {
            canvas.drawCircle(
              Offset(frame.scale.xToPx(p.x), frame.scale.yToPx(p.y)),
              3,
              dot,
            );
          }
        }
      }
    }
    _drawXTicks(canvas, frame, style);
  }

  /// Punti e curve di ogni serie, coi buchi lasciati fuori: un segmento per
  /// tratto continuo, quindi il painter può spezzare la penna.
  static List<List<List<ChartPoint>>> segmentsOf(ChartBoxPayload payload) {
    final out = <List<List<ChartPoint>>>[];
    for (final s in payload.series) {
      if (s.points.isNotEmpty) {
        out.add([List<ChartPoint>.of(s.points)]);
      } else if (s.expression.isNotEmpty) {
        final minX = payload.xMin ?? -10;
        final maxX = payload.xMax ?? 10;
        out.add(
          sampledSegments(
            s.expression,
            minX,
            maxX,
            samples: payload.samples,
            clipMin: payload.yMin,
            clipMax: payload.yMax,
          ),
        );
      }
    }
    if (out.isEmpty) return const [];
    return out;
  }

  void _drawXTicks(Canvas canvas, ChartFrame frame, ChartStyle style) {
    if (payload.xLabels.isEmpty) return;
    final count = payload.xLabels.length;
    for (var i = 0; i < count; i++) {
      final x =
          frame.rect.left +
          (frame.rect.width / (count - 1 == 0 ? 1 : count - 1)) * i;
      final tp = TextPainter(
        text: TextSpan(
          text: payload.xLabels[i],
          style: TextStyle(fontSize: style.font(_tickBase), color: style.label),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      if (x - tp.width / 2 < frame.rect.left - 1 ||
          x + tp.width / 2 > frame.rect.right + 1) {
        tp.dispose();
        continue;
      }
      tp.paint(canvas, Offset(x - tp.width / 2, frame.rect.bottom + 5));
      tp.dispose();
    }
  }

  @override
  bool shouldRepaint(covariant LineChartPainter old) =>
      old.payload != payload ||
      !listEquals(old.colors, colors) ||
      old.style != style ||
      old.progress != progress;
}
