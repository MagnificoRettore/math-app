import 'package:flutter/material.dart';

import '../models/difficulty.dart';
import '../theme/app_colors.dart';

class DifficultyBadge extends StatelessWidget {
  final Difficulty difficulty;

  const DifficultyBadge({super.key, required this.difficulty});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final color = switch (difficulty) {
      Difficulty.easy => c.easy,
      Difficulty.medium => c.medium,
      Difficulty.hard => c.hard,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        difficulty.label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
