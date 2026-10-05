import 'package:flutter/material.dart';

import '../data/auth_store.dart';
import '../data/content_repository.dart';
import '../models/course.dart';
import '../models/exercise.dart';
import '../models/level.dart';
import '../models/topic.dart';
import '../screens/exercise_detail_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import 'app_button.dart';
import 'app_card.dart';
import 'difficulty_badge.dart';

/// Un esercizio, con il percorso per arrivarci.
class DailyExercise {
  final Level level;
  final Course course;
  final Topic topic;
  final Exercise exercise;

  const DailyExercise(this.level, this.course, this.topic, this.exercise);

  /// L'esercizio di [day]: uno per giorno (il giorno dell'anno sul numero degli
  /// esercizi), quindi non cambia a ogni rebuild. Si pesca fra quelli della
  /// scuola del profilo; senza profilo, fra quelli di tutte le scuole.
  static DailyExercise? of(DateTime day) {
    final schoolId = AuthStore.instance.currentUser?.schoolLevelId ?? '';
    final levels = [
      for (final level in ContentRepository.instance.levels)
        if (schoolId.isEmpty || level.id == schoolId) level,
    ];
    final pool = <DailyExercise>[
      for (final level in levels)
        for (final course in level.courses)
          for (final topic in course.topics)
            for (final exercise in topic.exercises)
              DailyExercise(level, course, topic, exercise),
    ];
    if (pool.isEmpty) return null;
    final dayOfYear = day.difference(DateTime(day.year)).inDays;
    return pool[dayOfYear % pool.length];
  }
}

/// «Esercizio del giorno»: la card media sotto «Continua». «Provalo» apre
/// l'esercizio. Si ascolta da sé, perché il profilo (e la scuola) cambia.
class DailyExerciseCard extends StatelessWidget {
  const DailyExerciseCard({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AuthStore.instance,
      builder: (context, _) {
        final daily = DailyExercise.of(DateTime.now());
        if (daily == null) return const SizedBox.shrink();
        final c = AppColors.of(context);
        final exercise = daily.exercise;
        // Il testo del problema senza i segni delle formule: qui è un'anteprima.
        final preview = exercise.problem.replaceAll(r'$', '').trim();
        void open() => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => ExerciseDetailScreen(
              level: daily.level,
              course: daily.course,
              topic: daily.topic,
              exercise: exercise,
            ),
          ),
        );
        return AppCard(
          key: const Key('daily-exercise-card'),
          onTap: open,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Esercizio del giorno',
                      style: TextStyle(
                        fontFamily: AppText.headingFont,
                        fontSize: AppText.title,
                        fontWeight: FontWeight.w600,
                        color: c.textPrimary,
                      ),
                    ),
                  ),
                  DifficultyBadge(difficulty: exercise.difficulty),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                preview.isEmpty ? exercise.title : preview,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: AppText.bodyLarge,
                  height: 1.4,
                  color: c.textSecondary,
                ),
              ),
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerRight,
                child: AppButton(
                  key: const Key('daily-exercise-button'),
                  label: 'Provalo',
                  variant: AppButtonVariant.secondary,
                  height: 44,
                  onPressed: open,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
