import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/multifunction_box/box_payload.dart';

const double _padLeft = 42;
const double _padRight = 10;
const double _padTop = 10;
const double _padBottom = 28;
const double _legendHeight = 30;
const double _tickFontSize = 10;

void _drawText(
  Canvas canvas,
  String text,
  Offset offset, {
  required TextStyle style,
}) {
  final tp = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
  )..layout();
  tp.paint(canvas, offset - Offset(0, tp.height / 2));
}

double _niceCeil(double value) {
  if (value <= 0) return 1.0;
  final expo = (math.log(value) / math.ln10).floor();
  final base = math.pow(10, expo).toDouble();
  for (final m in [1.0, 2.0, 2.5, 5.0, 10.0]) {
    if (base * m >= value) return base * m;
  }
  return base * 10;
}

List<double> _gridValues(double max) {
  final step = max / 4;
  return [for (var i = 0; i <= 4; i++) i * step];
}

String _formatTick(double v) {
  if (v == v.roundToDouble()) return v.toStringAsFixed(0);
  final s = v.toStringAsFixed(1);
  return s.replaceAll(RegExp(r'0$'), '');
}

void _drawLegend(
  Canvas canvas,
  Size size, {
  required List<String> labels,
  required List<Color> colors,
  required Color labelColor,
}) {
  if (labels.length < 2) return;
  var x = _padLeft;
  var row = 0;
  final y = 14.0;
  final style = TextStyle(fontSize: 11, color: labelColor);
  for (var i = 0; i < labels.length; i++) {
    final chipWidth = 10.0;
    final tp = TextPainter(
      text: TextSpan(text: labels[i], style: style),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: 120);
    final total = chipWidth + 6 + tp.width;
    if (x + total > size.width - _padRight) {
      row++;
      x = _padLeft;
    }
    final chipY = y + row * 18;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x, chipY - 5, chipWidth, 10),
        const Radius.circular(3),
      ),
      Paint()..color = colors[i % colors.length],
    );
    tp.paint(canvas, Offset(x + chipWidth + 6, chipY - tp.height / 2));
    x += total + 14;
  }
}

class BarChartPainter extends CustomPainter {
  final List<ChartSeries> series;
  final List<String> xLabels;
  final List<Color> colors;
  final String unit;
  final Color gridColor;
  final Color labelColor;
  final Color axisColor;

  BarChartPainter({
    required this.series,
    required this.colors,
    this.xLabels = const [],
    this.unit = '',
    this.gridColor = const Color(0xFFE5E5EA),
    this.labelColor = const Color(0xFF6E6E73),
    this.axisColor = const Color(0xFFC7C7CC),
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (series.isEmpty) return;
    final maxLabelCount = math.max(
      series.map((s) => s.values.length).fold(0, math.max),
      1,
    );
    final labels = xLabels.length == maxLabelCount
        ? xLabels
        : [for (var i = 0; i < maxLabelCount; i++) '${i + 1}'];
    final values = [for (final s in series) ...s.values];
    final maxValue = _niceCeil(values.fold<num>(0.0, math.max).toDouble());

    final groupCount = maxLabelCount;
    final groupWidth = (size.width - _padLeft - _padRight) / groupCount;
    final barWidth = groupWidth * 0.7 / series.length;
    final plotHeight = size.height - _padTop - _padBottom - _legendHeight;
    final plotBottom = size.height - _padBottom;

    _drawLegend(
      canvas,
      size,
      labels: [for (final s in series) s.label],
      colors: colors,
      labelColor: labelColor,
    );

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (final g in _gridValues(maxValue)) {
      final y = plotBottom - (g / maxValue) * plotHeight;
      canvas.drawLine(
        Offset(_padLeft, y),
        Offset(size.width - _padRight, y),
        gridPaint,
      );
      _drawText(
        canvas,
        g == maxValue && unit.isNotEmpty
            ? '${_formatTick(g)} $unit'
            : _formatTick(g),
        Offset(_padLeft - 6, y),
        style: TextStyle(fontSize: _tickFontSize, color: labelColor),
      );
    }

    for (var gi = 0; gi < maxLabelCount; gi++) {
      final x0 =
          _padLeft + gi * groupWidth + (groupWidth - groupWidth * 0.7) / 2;
      for (var si = 0; si < series.length; si++) {
        final value = gi < series[si].values.length
            ? series[si].values[gi].toDouble()
            : 0.0;
        final h = (value / maxValue) * plotHeight;
        if (h <= 0) continue;
        final rect = Rect.fromLTWH(
          x0 + si * barWidth,
          plotBottom - h,
          barWidth,
          h,
        );
        canvas.drawRRect(
          RRect.fromRectAndCorners(
            rect,
            topLeft: const Radius.circular(4),
            topRight: const Radius.circular(4),
          ),
          Paint()..color = colors[si % colors.length],
        );
      }
      if (maxLabelCount <= 6 || gi.isEven) {
        _drawText(
          canvas,
          labels[gi],
          Offset(_padLeft + gi * groupWidth + groupWidth / 2, plotBottom + 12),
          style: TextStyle(fontSize: _tickFontSize, color: labelColor),
        );
      }
    }

    canvas.drawLine(
      Offset(_padLeft, plotBottom),
      Offset(size.width - _padRight, plotBottom),
      Paint()
        ..color = axisColor
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant BarChartPainter oldDelegate) =>
      oldDelegate.series != series ||
      oldDelegate.xLabels != xLabels ||
      oldDelegate.colors != colors;
}

class LineChartPainter extends CustomPainter {
  final List<ChartSeries> series;
  final List<String> xLabels;
  final List<Color> colors;
  final String unit;
  final Color gridColor;
  final Color labelColor;
  final Color axisColor;

  LineChartPainter({
    required this.series,
    required this.colors,
    this.xLabels = const [],
    this.unit = '',
    this.gridColor = const Color(0xFFE5E5EA),
    this.labelColor = const Color(0xFF6E6E73),
    this.axisColor = const Color(0xFFC7C7CC),
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (series.isEmpty) return;
    final pointCount = math.max(
      series.map((s) => s.values.length).fold(0, math.max),
      1,
    );
    final labels = xLabels.length == pointCount
        ? xLabels
        : [for (var i = 0; i < pointCount; i++) '${i + 1}'];
    final values = [for (final s in series) ...s.values];
    final vMin = values.fold<num>(0.0, math.min).toDouble();
    var vMax = values.fold<num>(0.0, math.max).toDouble();
    if (vMax <= vMin) vMax = vMin + 1;
    final yMax = _niceCeil(vMax);
    final yMin = vMin < 0 ? -_niceCeil(-vMin) : 0.0;

    final plotHeight = size.height - _padTop - _padBottom - _legendHeight;
    final plotBottom = size.height - _padBottom;
    final plotWidth = size.width - _padLeft - _padRight;

    _drawLegend(
      canvas,
      size,
      labels: [for (final s in series) s.label],
      colors: colors,
      labelColor: labelColor,
    );

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (final g in _gridValues(math.max(yMax, yMin.abs()))) {
      final value = yMin < 0 ? g : yMin + g;
      if (value > yMax) continue;
      final y = plotBottom - ((value - yMin) / (yMax - yMin)) * plotHeight;
      canvas.drawLine(
        Offset(_padLeft, y),
        Offset(size.width - _padRight, y),
        gridPaint,
      );
      _drawText(
        canvas,
        value == yMax && unit.isNotEmpty
            ? '${_formatTick(value)} $unit'
            : _formatTick(value),
        Offset(_padLeft - 6, y),
        style: TextStyle(fontSize: _tickFontSize, color: labelColor),
      );
    }

    double xFor(int i) {
      if (pointCount == 1) return _padLeft + plotWidth / 2;
      return _padLeft + i * plotWidth / (pointCount - 1);
    }

    double yFor(double value) {
      final clamped = value.clamp(yMin, yMax);
      return plotBottom - ((clamped - yMin) / (yMax - yMin)) * plotHeight;
    }

    for (var si = 0; si < series.length; si++) {
      final color = colors[si % colors.length];
      final linePaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round;
      final path = Path();
      final pts = series[si].values;
      for (var i = 0; i < pts.length; i++) {
        final offset = Offset(xFor(i), yFor(pts[i].toDouble()));
        if (i == 0) {
          path.moveTo(offset.dx, offset.dy);
        } else {
          path.lineTo(offset.dx, offset.dy);
        }
      }
      canvas.drawPath(path, linePaint);
      for (var i = 0; i < pts.length; i++) {
        canvas.drawCircle(
          Offset(xFor(i), yFor(pts[i].toDouble())),
          3.2,
          Paint()..color = color,
        );
      }
    }

    for (var i = 0; i < pointCount; i++) {
      _drawText(
        canvas,
        labels[i],
        Offset(xFor(i), plotBottom + 12),
        style: TextStyle(fontSize: _tickFontSize, color: labelColor),
      );
    }

    canvas.drawLine(
      Offset(_padLeft, plotBottom),
      Offset(size.width - _padRight, plotBottom),
      Paint()
        ..color = axisColor
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant LineChartPainter oldDelegate) =>
      oldDelegate.series != series ||
      oldDelegate.xLabels != xLabels ||
      oldDelegate.colors != colors;
}

class PieChartPainter extends CustomPainter {
  final List<num> values;
  final List<String> labels;
  final List<Color> colors;
  final Color labelColor;
  final Color strokeColor;

  PieChartPainter({
    required this.values,
    required this.colors,
    this.labels = const [],
    this.labelColor = const Color(0xFF6E6E73),
    this.strokeColor = Colors.white,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final clampedValues = [for (final v in values) math.max(0, v.toDouble())];
    final total = clampedValues.fold<num>(0, (a, b) => a + b);
    if (total <= 0) return;

    final legendWidth = labels.isNotEmpty ? size.width * 0.40 : 0.0;
    final center = Offset(
      _padLeft + (size.width - _padLeft - legendWidth) / 2,
      size.height / 2,
    );
    final radius = math.min(
      (size.width - _padLeft - legendWidth) / 2 - 6,
      size.height / 2 - 6,
    );

    final gapPaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    var start = -math.pi / 2;
    for (var i = 0; i < clampedValues.length; i++) {
      final sweep = (clampedValues[i] / total) * 2 * math.pi;
      if (sweep <= 0) continue;
      final paint = Paint()
        ..color = colors[i % colors.length]
        ..style = PaintingStyle.fill;
      final rect = Rect.fromCircle(center: center, radius: radius);
      canvas.drawArc(rect, start, sweep, true, paint);
      canvas.drawArc(rect, start, sweep, true, gapPaint);
      start += sweep;
    }

    _drawLegend(
      canvas,
      size,
      labels: labels,
      colors: colors,
      labelColor: labelColor,
    );
  }

  @override
  bool shouldRepaint(covariant PieChartPainter oldDelegate) =>
      oldDelegate.values != values ||
      oldDelegate.colors != colors ||
      oldDelegate.labels != labels;
}
