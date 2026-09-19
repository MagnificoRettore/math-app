import '../models/course.dart';
import '../models/lesson.dart';
import '../models/level.dart';
import '../models/progress.dart';
import '../models/topic.dart';
import '../models/weak_topic.dart';
import 'content_repository.dart';
import 'lesson_repository.dart';
import 'progress_store.dart';

class WeakTopicEngine {
  const WeakTopicEngine._();

  static List<WeakTopic> weakTopics({String? levelId}) {
    final store = ProgressStore.instance;
    final locations = ContentRepository.instance.allExerciseLocations().where(
      (loc) => levelId == null || loc.level.id == levelId,
    );

    final byTopic = <String, _Agg>{};
    for (final loc in locations) {
      final agg = byTopic.putIfAbsent(
        loc.topic.id,
        () => _Agg(level: loc.level, course: loc.course, topic: loc.topic),
      );
      final status = store.statusOf(loc.level.id, loc.exercise.id);
      if (status == ExerciseStatus.needsReview) agg.weak.add(loc);
      if (status == ExerciseStatus.mastered) agg.mastered++;
      agg.total++;
    }

    final result = <WeakTopic>[];
    for (final agg in byTopic.values) {
      if (agg.weak.isEmpty) continue;
      result.add(
        WeakTopic(
          level: agg.level,
          course: agg.course,
          topic: agg.topic,
          weakExercises: List.unmodifiable(agg.weak),
          masteredRatio: agg.total == 0 ? 0 : agg.mastered / agg.total,
        ),
      );
    }

    result.sort((a, b) {
      final byCount = b.needsReviewCount.compareTo(a.needsReviewCount);
      if (byCount != 0) return byCount;
      return a.masteredRatio.compareTo(b.masteredRatio);
    });
    return result;
  }

  static WeakTopic? weakTopicFor(String topicId, {String? levelId}) {
    for (final weak in weakTopics(levelId: levelId)) {
      if (weak.topic.id == topicId) return weak;
    }
    return null;
  }

  static List<Lesson> lessonsForTopic(String topicId, {String? levelId}) {
    final store = ProgressStore.instance;
    return LessonRepository.instance.lessons
        .where((l) => l.topics.contains(topicId))
        .where((l) => levelId == null || l.levelId == levelId)
        .where((l) => !store.isLessonCompleted(l.levelId, l.id))
        .toList();
  }
}

class _Agg {
  final Level level;
  final Course course;
  final Topic topic;
  final List<ExerciseLocation> weak = [];
  int total = 0;
  int mastered = 0;

  _Agg({required this.level, required this.course, required this.topic});
}
