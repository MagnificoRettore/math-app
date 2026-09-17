import 'package:flutter/material.dart';

import '../data/content_repository.dart';
import '../data/progress_store.dart';
import '../data/recommendation_engine.dart';
import '../models/user_profile.dart';
import '../screens/course_screen.dart';
import '../screens/exercise_detail_screen.dart';
import '../screens/lesson_screen.dart';
import '../theme/app_colors.dart';
import 'exercise_card.dart';
import 'lesson_card.dart';
import 'section_header.dart';

class RecommendedSection extends StatelessWidget {
  final UserProfile user;

  const RecommendedSection({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    if (user.schoolLevelId.isEmpty) return const SizedBox.shrink();
    final level = ContentRepository.instance.levelById(user.schoolLevelId);
    if (level == null) return const SizedBox.shrink();

    final lessons = RecommendationEngine.recommendedLessons(level.id);
    final exercises = RecommendationEngine.recommendedExercises(level.id);
    if (lessons.isEmpty && exercises.isEmpty) return const SizedBox.shrink();

    final c = AppColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          'Per te · ${level.title}',
          trailing: TextButton(
            onPressed: () => _openLevel(context, level.id),
            child: Text(
              'Esplora',
              style: TextStyle(fontSize: 13, color: c.accent),
            ),
          ),
        ),
        if (lessons.isNotEmpty) const _MiniHeader('Lezioni da provare'),
        for (final lesson in lessons)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: LessonCard(
              lesson: lesson,
              completed: ProgressStore.instance.isLessonCompleted(lesson.id),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => LessonScreen(lesson: lesson)),
              ),
            ),
          ),
        if (exercises.isNotEmpty) ...[
          const SizedBox(height: 10),
          const _MiniHeader('Esercizi da provare'),
        ],
        for (final location in exercises)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: ExerciseCard(
              exercise: location.exercise,
              bookmarked: ProgressStore.instance.isBookmarked(
                location.exercise.id,
              ),
              status: ProgressStore.instance.statusOf(location.exercise.id),
              onToggleBookmark: (_) =>
                  ProgressStore.instance.toggleBookmark(location.exercise.id),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ExerciseDetailScreen(
                    level: location.level,
                    course: location.course,
                    topic: location.topic,
                    exercise: location.exercise,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _openLevel(BuildContext context, String levelId) {
    final level = ContentRepository.instance.levelById(levelId);
    if (level == null) return;
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => CourseScreen(level: level)));
  }
}

class _MiniHeader extends StatelessWidget {
  final String title;

  const _MiniHeader(this.title);

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: c.textSecondary,
        ),
      ),
    );
  }
}
