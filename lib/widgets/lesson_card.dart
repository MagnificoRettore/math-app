import 'package:flutter/material.dart';

import '../models/lesson.dart';
import '../theme/app_colors.dart';
import 'app_card.dart';

class LessonCard extends StatelessWidget {
  final Lesson lesson;
  final bool completed;
  final VoidCallback onTap;

  const LessonCard({
    super.key,
    required this.lesson,
    required this.completed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final color = _colorFor(c, lesson.icon);
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(_iconFor(lesson.icon), color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lesson.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: c.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${lesson.steps.length} passaggi · ${lesson.subtitle}',
                  style: TextStyle(
                    fontSize: 13,
                    color: c.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (completed) ...[
            Icon(Icons.check_circle, color: c.easy, size: 22),
            const SizedBox(width: 8),
          ],
          Icon(Icons.chevron_right, color: c.textSecondary),
        ],
      ),
    );
  }

  IconData _iconFor(String name) {
    switch (name) {
      case 'pie_chart':
        return Icons.pie_chart_outline;
      case 'functions':
        return Icons.functions;
      case 'triangle':
        return Icons.change_history_outlined;
      default:
        return Icons.menu_book_outlined;
    }
  }

  Color _colorFor(AppPalette c, String name) {
    switch (name) {
      case 'pie_chart':
        return c.pink;
      case 'functions':
        return c.accent;
      case 'triangle':
        return c.purple;
      default:
        return c.teal;
    }
  }
}