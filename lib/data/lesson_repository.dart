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

  Future<void> load() async {
    if (_loaded) return;
    _loadError = null;
    try {
      final json = jsonDecode(
        await rootBundle.loadString('assets/data/lessons.json'),
      ) as Map<String, dynamic>;
      _lessons = (json['lessons'] as List<dynamic>)
          .map((e) => Lesson.fromJson(e as Map<String, dynamic>))
          .toList();
      _loaded = true;
    } catch (error) {
      _loadError = error;
    }
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
