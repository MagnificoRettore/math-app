import 'dart:convert';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/services.dart' show rootBundle;

import '../models/lesson.dart';

class LessonRepository {
  static final LessonRepository instance = LessonRepository._();
  LessonRepository._();

  List<Lesson> _lessons = [];
  bool _loaded = false;
  Object? _loadError;

  List<Lesson> get lessons => _lessons;
  bool get loaded => _loaded;
  Object? get loadError => _loadError;

  List<Lesson> lessonsInYear(String levelId, String yearId) {
    return _lessons
        .where((l) => l.levelId == levelId && l.yearId == yearId)
        .toList();
  }

  List<Lesson> lessonsInSection(String levelId, String sectionId) {
    return _lessons
        .where((l) => l.levelId == levelId && l.sectionId == sectionId)
        .toList();
  }

  static const _indexPath = 'assets/data/lessons/index.json';
  static const _dirPath = 'assets/data/lessons/';

  Future<void> load() async {
    if (_loaded) return;
    _loadError = null;
    try {
      final indexJson = jsonDecode(
        await rootBundle.loadString(_indexPath),
      ) as Map<String, dynamic>;
      final lessons = <Lesson>[];
      for (final file in indexJson['argomenti'] as List<dynamic>) {
        final argomento = jsonDecode(
          await rootBundle.loadString('$_dirPath$file'),
        ) as Map<String, dynamic>;
        lessons.addAll(_lessonsOf(argomento));
      }
      _lessons = lessons;
      _loaded = true;
    } catch (error) {
      _loadError = error;
    }
  }

  List<Lesson> _lessonsOf(Map<String, dynamic> argomento) {
    final levelId = argomento['level'] as String;
    final yearId = argomento['year'] as String;
    final sectionId = argomento['section'] as String;
    final topicId = argomento['topic'] as String;
    return [
      for (final lesson in argomento['lessons'] as List<dynamic>)
        Lesson.fromJson({
          ...(lesson as Map<String, dynamic>),
          'level': levelId,
          'year': yearId,
          'section': sectionId,
          'topics': [topicId],
        }),
    ];
  }

  Future<void> reload() async {
    _loaded = false;
    _lessons = [];
    await load();
  }

  @visibleForTesting
  Future<void> resetForTest() async {
    _loaded = false;
    _lessons = [];
    _loadError = null;
    await load();
  }
}
