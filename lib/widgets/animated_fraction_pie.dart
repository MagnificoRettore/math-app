import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

class AnimatedFractionPie extends StatefulWidget {
  const AnimatedFractionPie({super.key});

  @override
  State<AnimatedFractionPie> createState() => _AnimatedFractionPieState();
}

class _AnimatedFractionPieState extends State<AnimatedFractionPie>
    with SingleTickerProviderStateMixin {
  static const _fractions = [
    (num: 1, den: 2),
    (num: 1, den: 3),
    (num: 2, den: 3),
    (num: 3, den: 4),
    (num: 1, den: 4),
  ];

  late final AnimationController _fill = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..value = 1;

  int _index = 0;

  void _nextFraction() {
    setState(() => _index = (_index + 1) % _fractions.length);
    _fill.forward(from: 0);
  }

  @override
  void dispose() {
    _fill.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final (num: num, den: den) = _fractions[_index];
    final color = c.iconPalette[_index % c.iconPalette.length];
    final totalSweep = 2 * math.pi * (num / den);

    return GestureDetector(
      onTap: _nextFraction,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          SizedBox(
            width: 170,
            height: 170,
            child: AnimatedBuilder(
              animation: _fill,
              builder: (context, _) => CustomPaint(
                painter: _PiePainter(
                  sweep: totalSweep * _fill.value,
                  color: color,
                  trackColor: c.accentSoft,
                  ringColor: c.border,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '$num/$den',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tocca la torta per esplorare',
            style: TextStyle(fontSize: 13, color: c.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _PiePainter extends CustomPainter {
  final double sweep;
  final Color color;
  final Color trackColor;
  final Color ringColor;

  _PiePainter({
    required this.sweep,
    required this.color,
    required this.trackColor,
    required this.ringColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 8;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final track = Paint()
      ..color = trackColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, track);

    final sector = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawArc(rect, -math.pi / 2, sweep, true, sector);

    final ring = Paint()
      ..color = ringColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, radius, ring);
  }

  @override
  bool shouldRepaint(_PiePainter old) =>
      old.sweep != sweep ||
      old.color != color ||
      old.trackColor != trackColor ||
      old.ringColor != ringColor;
}