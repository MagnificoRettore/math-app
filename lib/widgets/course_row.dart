import 'package:flutter/material.dart';

import '../models/course.dart';
import '../theme/app_colors.dart';
import 'progress_bar.dart';
import 'app_card.dart';

class CourseRow extends StatelessWidget {
  final Course course;
  final VoidCallback onTap;
  final double progress;
  final Color? iconColor;

  const CourseRow({
    super.key,
    required this.course,
    required this.onTap,
    required this.progress,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final effectiveIconColor = iconColor ?? c.accent;
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: effectiveIconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.menu_book_outlined,
              color: effectiveIconColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  course.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: c.textPrimary,
                  ),
                ),
                if (course.subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    course.subtitle,
                    style: TextStyle(fontSize: 13, color: c.textSecondary),
                  ),
                ],
                const SizedBox(height: 10),
                ProgressBar(progress: progress, height: 5),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.chevron_right, color: c.textSecondary),
        ],
      ),
    );
  }
}
