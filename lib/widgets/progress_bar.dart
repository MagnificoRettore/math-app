import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class ProgressBar extends StatelessWidget {
  final double progress; // 0.0 .. 1.0
  final double height;
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

    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: LinearProgressIndicator(
        value: value,
        minHeight: height,
        backgroundColor: c.border,
        valueColor: AlwaysStoppedAnimation(color ?? c.accent),
      ),
    );
  }
}
