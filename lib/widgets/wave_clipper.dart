import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Il bordo inferiore ondulato della testata del design («Creazione
/// profilo»): lo stesso tracciato della tavola (390×232), scalato sulla misura
/// del riquadro. [topRadius] arrotonda gli angoli in alto, per un riquadro
/// che sta dentro la pagina invece che appoggiato al bordo dello schermo.
///
/// Con [phase] (un valore 0..1 che si ripete) i punti del bordo oscillano a
/// onda e il tracciato torna uguale a ogni giro: è lui il `reclip`, quindi a
/// ogni frame si rifà solo il tracciato, non il contenuto che ritaglia.
class WaveBottomClipper extends CustomClipper<Path> {
  final double topRadius;
  final Animation<double>? phase;

  /// Quanto si muove il bordo, in unità della tavola (232 di altezza).
  static const double _amplitude = 7;

  WaveBottomClipper({this.topRadius = 0, this.phase}) : super(reclip: phase);

  @override
  Path getClip(Size size) {
    double x(double v) => v / 390 * size.width;
    double y(double v) => v / 232 * size.height;
    final r = topRadius;
    final t = (phase?.value ?? 0) * 2 * math.pi;
    // Ogni punto ha il suo sfasamento, così il bordo ondeggia invece di
    // salire e scendere tutto insieme. Le due punte in basso non escono dal
    // riquadro.
    double sway(double v, double offset) =>
        y(v + _amplitude * math.sin(t + offset));
    double dip(double offset) =>
        y(232 - _amplitude * (1 + math.sin(t + offset)));
    return Path()
      ..moveTo(0, r)
      ..quadraticBezierTo(0, 0, r, 0)
      ..lineTo(size.width - r, 0)
      ..quadraticBezierTo(size.width, 0, size.width, r)
      ..lineTo(size.width, sway(170, 0))
      ..cubicTo(
        x(340),
        sway(200, 0.8),
        x(330),
        sway(150, 1.6),
        x(285),
        sway(180, 2.4),
      )
      ..cubicTo(x(245), sway(206, 3.2), x(230), dip(4), x(195), dip(4))
      ..cubicTo(x(160), dip(4), x(145), sway(206, 4.8), x(105), sway(180, 5.6))
      ..cubicTo(x(60), sway(150, 0.4), x(50), sway(200, 1.2), 0, sway(170, 0))
      ..close();
  }

  @override
  bool shouldReclip(WaveBottomClipper oldClipper) =>
      oldClipper.topRadius != topRadius || oldClipper.phase != phase;
}
