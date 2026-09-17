import '../models/course.dart';
import '../models/exercise.dart';
import '../models/lesson.dart';
import '../models/level.dart';
import '../models/topic.dart';

enum ResultType { topic, exercise, lesson }

class SearchResult {
  final ResultType type;
  final Level? level;
  final Course? course;
  final Topic? topic;
  final Exercise? exercise;
  final Lesson? lesson;

  const SearchResult({
    required this.type,
    this.level,
    this.course,
    this.topic,
    this.exercise,
    this.lesson,
  });
}

class SearchIndex {
  static final SearchIndex instance = SearchIndex._();
  SearchIndex._();

  final List<SearchResult> _results = [];

  void build(List<Level> levels, {List<Lesson> lessons = const []}) {
    _results.clear();
    for (final level in levels) {
      for (final course in level.courses) {
        for (final topic in course.topics) {
          _results.add(
            SearchResult(
              type: ResultType.topic,
              level: level,
              course: course,
              topic: topic,
            ),
          );
          for (final exercise in topic.exercises) {
            _results.add(
              SearchResult(
                type: ResultType.exercise,
                level: level,
                course: course,
                topic: topic,
                exercise: exercise,
              ),
            );
          }
        }
      }
    }
    for (final lesson in lessons) {
      _results.add(SearchResult(type: ResultType.lesson, lesson: lesson));
    }
  }

  List<SearchResult> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];

    final matches = <SearchResult>[];
    for (final result in _results) {
      if (_matches(result, q)) {
        matches.add(result);
      }
    }

    matches.sort((a, b) => a.type.index.compareTo(b.type.index));
    return matches;
  }

  bool _matches(SearchResult result, String q) {
    switch (result.type) {
      case ResultType.topic:
        final topic = result.topic!;
        final haystack = [
          topic.title,
          topic.subtitle,
          ...topic.exercises.expand((e) => [e.title, ...e.tags]),
        ].join(' ').toLowerCase();
        return haystack.contains(q);
      case ResultType.exercise:
        final ex = result.exercise!;
        final haystack = [
          ex.title,
          ...ex.tags,
          ...ex.formulas,
          ex.problem,
          ...ex.steps,
          ...ex.hints,
        ].join(' ').toLowerCase();
        return haystack.contains(q);
      case ResultType.lesson:
        final lesson = result.lesson!;
        final haystack = [
          lesson.title,
          lesson.subtitle,
          lesson.introduction,
          lesson.completionMessage,
          ...lesson.steps.expand((s) => [s.prompt, s.explanation]),
        ].join(' ').toLowerCase();
        return haystack.contains(q);
    }
  }
}
