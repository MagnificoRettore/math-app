import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_motion.dart';

/// Da questa altezza in su la barra è quella del design: fondo giallo chiaro,
/// riempimento a strisce e bordo. Sotto, strisce e bordo non si leggono più e
/// la barra resta piena e arrotondata.
const double _kStripedMinHeight = 10;

/// Quando il valore cambia, il riempimento ci arriva in [AppMotion.slow]
/// `easeOut`, strisce comprese; al primo disegno parte già al suo valore. Col
/// movimento ridotto salta subito al valore nuovo.
class ProgressBar extends StatelessWidget {
  final double progress; // 0.0 .. 1.0
  final double height;

  /// Il colore del riempimento; di default il giallo del design.
  final Color? color;

  const ProgressBar({
    super.key,
    required this.progress,
    this.height = 6,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final value = progress.clamp(0.0, 1.0);
    final fill = color ?? c.yellow;
    final striped = height >= _kStripedMinHeight;
    final radius = BorderRadius.circular(striped ? 4 : height);

    return Semantics(
      value: '${(value * 100).round()}%',
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: c.yellowSoft,
          borderRadius: radius,
          border: striped ? Border.all(color: c.yellowDeep, width: 2) : null,
        ),
        child: ClipRRect(
          // Dentro il bordo il raggio si accorcia di quanto è spesso il bordo.
          borderRadius: BorderRadius.circular(striped ? 2 : height),
          child: TweenAnimationBuilder<double>(
            tween: Tween(end: value),
            duration: AppMotion.duration(context, AppMotion.slow),
            curve: AppMotion.standard,
            // Il riempimento non cambia mentre la barra si muove: lo passa una
            // volta, e a ogni frame si ridisegna solo la larghezza.
            child: striped
                ? CustomPaint(
                    painter: _Stripes(
                      fill: fill,
                      stripe: color == null ? c.yellowDeep : _darker(fill),
                    ),
                  )
                : ColoredBox(color: fill),
            builder: (context, animated, child) => Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: animated,
                heightFactor: 1,
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Color _darker(Color color) =>
      Color.lerp(color, Colors.black, 0.25) ?? color;
}

/// Il riempimento a strisce verticali del design: 2 px ogni 12.
class _Stripes extends CustomPainter {
  final Color fill;
  final Color stripe;

  const _Stripes({required this.fill, required this.stripe});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = fill);
    final paint = Paint()..color = stripe;
    for (var x = 10.0; x < size.width; x += 12) {
      canvas.drawRect(Rect.fromLTWH(x, 0, 2, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(_Stripes old) => old.fill != fill || old.stripe != stripe;
}
