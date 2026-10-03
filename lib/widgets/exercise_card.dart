import 'package:flutter/material.dart';

import '../models/exercise.dart';
import '../models/progress.dart';
import '../theme/app_colors.dart';
import 'difficulty_badge.dart';
import 'recommendation_row.dart';

/// Un esercizio consigliato sulla Home: il suo stato diventa il colore della
/// piastra e il play è dichiarato esplicitamente.
///
/// La riga è di [RecommendationRow], la stessa che fa da invito all'ospite.
class ExerciseCard extends StatelessWidget {
  final Exercise exercise;
  final VoidCallback onTap;
  final ExerciseStatus status;

  /// Bottone pieno a destra. Sulla Home l'esercizio consigliato ha già il suo
  /// bottone «play»: metterlo dentro la card dice che l'azione è una sola e
  /// dice quale, il tappo della card resta aperto a chi tocca altrove.
  final bool showPlayButton;

  const ExerciseCard({
    super.key,
    required this.exercise,
    required this.onTap,
    required this.status,
    this.showPlayButton = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return RecommendationRow(
      plateColor: _statusColor(c, status),
      plateIcon: _statusIcon(status),
      title: exercise.title,
      badge: DifficultyBadge(difficulty: exercise.difficulty),
      preview: _preview(exercise.problem),
      onTap: onTap,
      showPlayButton: showPlayButton,
      playKey: Key('exercise-play-${exercise.id}'),
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
