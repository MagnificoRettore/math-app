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

  /// Gli argomenti di un anno scolastico, nell'ordine in cui arrivano dal
  /// contenuto: `lessonsInYear` li appiattisce e perde l'argomento di
  /// appartenenza, questa no.
  List<Argomento> argomentiInYear(String levelId, String yearId) {
    return [
      for (final argomento in _argomenti)
        if (argomento.levelId == levelId && argomento.yearId == yearId)
          argomento,
    ];
  }

  /// Le lezioni di un anno in ordine: perdono l'argomento di appartenenza,
  /// per elencare i titoli non serve. Per sapere a quale argomento
  /// appartiene una lezione usa `argomentoFor`.
  List<Lesson> lessonsInYear(String levelId, String yearId) {
    return [
      for (final argomento in argomentiInYear(levelId, yearId))
        ...argomento.lessons,
    ];
  }

  /// L'argomento che contiene la lezione data, o null se nel contenuto non
  /// c'è più: serve a ritrovare dove riprendere una lezione.
  Argomento? argomentoFor(String levelId, String lessonId) {
    for (final argomento in _argomenti) {
      if (argomento.levelId != levelId) continue;
      for (final lesson in argomento.lessons) {
        if (lesson.id == lessonId) return argomento;
      }
    }
    return null;
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
