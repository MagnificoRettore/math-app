import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

class AnimatedNumberLine extends StatefulWidget {
  const AnimatedNumberLine({super.key});

  @override
  State<AnimatedNumberLine> createState() => _AnimatedNumberLineState();
}

class _AnimatedNumberLineState extends State<AnimatedNumberLine> {
  static const int min = -5;
  static const int max = 5;
  static const double markerWidth = 64;

  int _value = 4;

  void _setValueFromOffset(double x, double width) {
    final fraction = (x / width).clamp(0.0, 1.0);
    final value = (min + fraction * (max - min)).round().clamp(min, max);
    if (value != _value) {
      setState(() => _value = value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return SizedBox(
      height: 110,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final fraction = (_value - min) / (max - min);
          final left = (fraction * width - markerWidth / 2).clamp(
            8.0,
            width - markerWidth - 8,
          );

          return Stack(
            children: [
              GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTapDown: (details) =>
                    _setValueFromOffset(details.localPosition.dx, width),
                onHorizontalDragUpdate: (details) =>
                    _setValueFromOffset(details.localPosition.dx, width),
                child: SizedBox(
                  width: width,
                  height: 40,
                  child: CustomPaint(
                    painter: _NumberLinePainter(
                      min: min,
                      max: max,
                      borderColor: c.border,
                      textColor: c.textSecondary,
                    ),
                  ),
                ),
              ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
                top: 2,
                left: left,
                width: markerWidth,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: c.accent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'x = $_value',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: c.accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _NumberLinePainter extends CustomPainter {
  final int min;
  final int max;
  final Color borderColor;
  final Color textColor;

  _NumberLinePainter({
    required this.min,
    required this.max,
    required this.borderColor,
    required this.textColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final midY = size.height;
    final left = 8.0;
    final right = size.width - 8;

    final line = Paint()
      ..color = borderColor
      ..strokeWidth = 2;
    canvas.drawLine(Offset(left, midY), Offset(right, midY), line);

    final tick = Paint()
      ..color = textColor
      ..strokeWidth = 1.5;
    final labelStyle = TextStyle(
      fontSize: 11,
      color: textColor,
      fontWeight: FontWeight.w600,
    );

    for (var v = min; v <= max; v++) {
      final x = left + (v - min) / (max - min) * (right - left);
      canvas.drawLine(Offset(x, midY - 5), Offset(x, midY + 5), tick);

      if (v % 5 == 0) {
        final painter = TextPainter(
          text: TextSpan(text: '$v', style: labelStyle),
          textDirection: TextDirection.ltr,
        )..layout();
        painter.paint(canvas, Offset(x - painter.width / 2, midY + 8));
      }
    }
  }

  @override
  bool shouldRepaint(_NumberLinePainter old) =>
      old.min != min ||
      old.max != max ||
      old.borderColor != borderColor ||
      old.textColor != textColor;
}
