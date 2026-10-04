import 'package:flutter/widgets.dart';

/// Il bordo inferiore ondulato della testata del design («Creazione
/// profilo»): lo stesso tracciato della tavola (390×232), scalato sulla misura
/// del riquadro. [topRadius] arrotonda gli angoli in alto, per un riquadro
/// che sta dentro la pagina invece che appoggiato al bordo dello schermo.
class WaveBottomClipper extends CustomClipper<Path> {
  final double topRadius;

  const WaveBottomClipper({this.topRadius = 0});

  @override
  Path getClip(Size size) {
    double x(double v) => v / 390 * size.width;
    double y(double v) => v / 232 * size.height;
    final r = topRadius;
    return Path()
      ..moveTo(0, r)
      ..quadraticBezierTo(0, 0, r, 0)
      ..lineTo(size.width - r, 0)
      ..quadraticBezierTo(size.width, 0, size.width, r)
      ..lineTo(size.width, y(170))
      ..cubicTo(x(340), y(200), x(330), y(150), x(285), y(180))
      ..cubicTo(x(245), y(206), x(230), y(232), x(195), y(232))
      ..cubicTo(x(160), y(232), x(145), y(206), x(105), y(180))
      ..cubicTo(x(60), y(150), x(50), y(200), 0, y(170))
      ..close();
  }

  @override
  bool shouldReclip(WaveBottomClipper oldClipper) =>
      oldClipper.topRadius != topRadius;
}
