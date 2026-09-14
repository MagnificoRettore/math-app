import 'package:flutter/material.dart';

import '../models/exercise.dart';
import '../models/progress.dart';
import '../theme/app_colors.dart';
import 'app_card.dart';
import 'difficulty_badge.dart';

class ExerciseCard extends StatelessWidget {
  final Exercise exercise;
  final VoidCallback onTap;
  final bool bookmarked;
  final ExerciseStatus status;
  final ValueChanged<bool> onToggleBookmark;

  const ExerciseCard({
    super.key,
    required this.exercise,
    required this.onTap,
    required this.bookmarked,
    required this.status,
    required this.onToggleBookmark,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _statusColor(c, status).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_statusIcon(status), color: _statusColor(c, status), size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        exercise.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: c.textPrimary,
                        ),
                      ),
                    ),
                    DifficultyBadge(difficulty: exercise.difficulty),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _preview(exercise.problem),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: c.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: () => onToggleBookmark(!bookmarked),
            icon: Icon(
              bookmarked ? Icons.bookmark : Icons.bookmark_border,
              color: bookmarked ? c.accent : c.textSecondary,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  String _preview(String problem) {
    final plain = problem.replaceAll(RegExp(r'\$+'), '');
    return plain.split('\n').where((l) => l.trim().isNotEmpty).join(' ');
  }

  Color _statusColor(AppPalette c, ExerciseStatus status) {
    switch (status) {
      case ExerciseStatus.mastered:
        return c.easy;
      case ExerciseStatus.needsReview:
        return c.medium;
      case ExerciseStatus.none:
        return c.textSecondary;
    }
  }

  IconData _statusIcon(ExerciseStatus status) {
    switch (status) {
      case ExerciseStatus.mastered:
        return Icons.check_circle_outline;
      case ExerciseStatus.needsReview:
        return Icons.autorenew;
      case ExerciseStatus.none:
        return Icons.radio_button_unchecked;
    }
  }
}