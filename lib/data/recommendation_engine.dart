import '../models/difficulty.dart';
import '../models/lesson.dart';
import '../models/progress.dart';
import 'content_repository.dart';
import 'lesson_repository.dart';
import 'progress_store.dart';

class RecommendationEngine {
  const RecommendationEngine._();

  static List<Lesson> recommendedLessons(
    String levelId, {
    int limit = 2,
  }) {
    final completed = ProgressStore.instance.completedLessonIds;
    final lessons = LessonRepository.instance.lessons
        .where((l) => l.levelId == levelId && !completed.contains(l.id))
        .toList();
    return lessons.take(limit).toList();
  }

  static List<ExerciseLocation> recommendedExercises(
    String levelId, {
    int limit = 4,
  }) {
    final store = ProgressStore.instance;
    final locations = ContentRepository.instance.allExerciseLocations()
        .where((loc) => loc.level.id == levelId)
        .where((loc) => store.statusOf(loc.exercise.id) == ExerciseStatus.none)
        .toList()
      ..sort((a, b) => _rank(a.exercise.difficulty)
          .compareTo(_rank(b.exercise.difficulty)));
    return locations.take(limit).toList();
  }

  static int _rank(Difficulty difficulty) {
    switch (difficulty) {
      case Difficulty.easy:
        return 0;
      case Difficulty.medium:
        return 1;
      case Difficulty.hard:
        return 2;
    }
  }
}