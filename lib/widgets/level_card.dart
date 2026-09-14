import 'package:flutter/material.dart';

import '../models/level.dart';
import '../theme/app_colors.dart';
import 'app_card.dart';

class LevelCard extends StatelessWidget {
  final Level level;
  final VoidCallback onTap;
  final double? progress;

  const LevelCard({
    super.key,
    required this.level,
    required this.onTap,
    this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final icon = _iconFor(level.icon);
    final color = _colorFor(c, level.icon);

    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  level.title,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: c.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  level.subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: c.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: c.textSecondary,
          ),
        ],
      ),
    );
  }

  IconData _iconFor(String name) {
    switch (name) {
      case 'school':
        return Icons.school_outlined;
      case 'account_balance':
        return Icons.account_balance_outlined;
      case 'menu_book':
        return Icons.menu_book_outlined;
      default:
        return Icons.category_outlined;
    }
  }

  Color _colorFor(AppPalette c, String name) {
    switch (name) {
      case 'school':
        return c.accent;
      case 'account_balance':
        return c.purple;
      case 'menu_book':
        return c.teal;
      default:
        return c.accent;
    }
  }
}