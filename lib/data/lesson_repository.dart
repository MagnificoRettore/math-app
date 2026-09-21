import 'dart:convert';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/services.dart' show rootBundle;

import '../models/argomento.dart';
import '../models/lesson.dart';

class LessonRepository {
  static final LessonRepository instance = LessonRepository._();
  LessonRepository._();

  List<Argomento> _argomenti = [];
  bool _loaded = false;
  Object? _loadError;

  List<Argomento> get argomenti => _argomenti;
  bool get loaded => _loaded;
  Object? get loadError => _loadError;

  List<Lesson> lessonsInYear(String levelId, String yearId) {
    return [
      for (final argomento in _argomenti)
        if (argomento.levelId == levelId && argomento.yearId == yearId)
          ...argomento.lessons,
    ];
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
      final argomenti = <Argomento>[];
      for (final file in indexJson['argomenti'] as List<dynamic>) {
        final argomento = jsonDecode(
          await rootBundle.loadString('$_dirPath$file'),
        ) as Map<String, dynamic>;
        argomenti.add(Argomento.fromJson(argomento));
      }
      _argomenti = argomenti;
      _loaded = true;
    } catch (error) {
      _loadError = error;
    }
  }

  Future<void> reload() async {
    _loaded = false;
    _argomenti = [];
    await load();
  }

  @visibleForTesting
  Future<void> resetForTest() async {
    _loaded = false;
    _argomenti = [];
    _loadError = null;
    await load();
  }
}
