import '../data/content_repository.dart';
import 'course.dart';
import 'level.dart';
import 'topic.dart';

class WeakTopic {
  final Level level;
  final Course course;
  final Topic topic;
  final List<ExerciseLocation> weakExercises;
  final double masteredRatio;

  const WeakTopic({
    required this.level,
    required this.course,
    required this.topic,
    required this.weakExercises,
    required this.masteredRatio,
  });

  int get needsReviewCount => weakExercises.length;
}
