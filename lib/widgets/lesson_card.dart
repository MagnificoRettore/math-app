import 'package:flutter/material.dart';

import '../models/lesson.dart';
import '../theme/app_colors.dart';
import 'app_card.dart';

class LessonCard extends StatelessWidget {
  final Lesson lesson;
  final bool completed;
  final int? number;
  final VoidCallback onTap;

  const LessonCard({
    super.key,
    required this.lesson,
    required this.completed,
    required this.onTap,
    this.number,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final color = _colorFor(c, lesson.icon);
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: (completed ? c.easy : color).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, animation) =>
                  ScaleTransition(scale: animation, child: child),
              child: Icon(
                completed ? Icons.check_circle : Icons.play_circle_outlined,
                key: ValueKey(completed),
                color: completed ? c.easy : color,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (number != null) ...[
                      Text(
                        '$number.',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: c.accent,
                        ),
                      ),
                      const SizedBox(width: 4),
                    ],
                    Expanded(
                      child: Text(
                        lesson.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: c.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.schedule, size: 13, color: c.textSecondary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '$_minutes min${lesson.subtitle.isEmpty ? '' : ' · ${lesson.subtitle}'}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 13, color: c.textSecondary),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: c.textSecondary),
        ],
      ),
    );
  }

  int get _minutes =>
      lesson.minutes > 0 ? lesson.minutes : lesson.steps.length * 2;

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
