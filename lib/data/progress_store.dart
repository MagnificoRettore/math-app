import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/lesson_resume.dart';
import '../models/progress.dart';

class ProgressStore extends ChangeNotifier {
  static final ProgressStore instance = ProgressStore._();
  ProgressStore._();

  static const _progressKey = 'exercise_progress_v1';
  static const _lessonsKey = 'lessons_completed_v1';
  static const _resumeKey = 'lessons_in_progress_v1';

  final Map<String, ExerciseProgress> _progress = {};
  final Set<String> _completedLessons = {};
  LessonResume? _resume;
  bool _loaded = false;
  Object? _loadError;

  bool get loaded => _loaded;
  Object? get loadError => _loadError;

  Future<void> load() async {
    if (_loaded) return;
    _loadError = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_progressKey);
      if (raw != null) {
        final list = jsonDecode(raw) as List<dynamic>;
        for (final item in list) {
          final p = ExerciseProgress.fromJson(item as Map<String, dynamic>);
          _progress[p.scopedKey] = p;
        }
      }
      final done = prefs.getStringList(_lessonsKey);
      if (done != null) {
        _completedLessons.addAll(done);
      }
      final rawResume = prefs.getString(_resumeKey);
      if (rawResume != null) {
        _resume = LessonResume.fromJson(
          jsonDecode(rawResume) as Map<String, dynamic>,
        );
      }
      _loaded = true;
      notifyListeners();
    } catch (error) {
      _loadError = error;
    }
  }

  Future<void> reload() async {
    _loaded = false;
    _progress.clear();
    _completedLessons.clear();
    _resume = null;
    await load();
  }

  @visibleForTesting
  Future<void> resetForTest() async {
    _loaded = false;
    _progress.clear();
    _completedLessons.clear();
    _resume = null;
    _loadError = null;
    await load();
  }

  /// Restituisce il progresso per un esercizio nel livello scolastico indicato.
  ExerciseProgress? forExercise(String levelId, String exerciseId) =>
      _progress[scopedKey(levelId, exerciseId)];

  ExerciseStatus statusOf(String levelId, String exerciseId) =>
      _progress[scopedKey(levelId, exerciseId)]?.status ?? ExerciseStatus.none;

  Future<void> setStatus(
    String levelId,
    String exerciseId,
    ExerciseStatus status,
  ) async {
    final key = scopedKey(levelId, exerciseId);
    final current =
        _progress[key] ??
        ExerciseProgress(exerciseId: exerciseId, status: ExerciseStatus.none);
    _progress[key] = current.copyWith(status: status);
    notifyListeners();
    await _persist();
  }

  /// Completeness (mastered + needsReview) per il livello indicato.
  double completionFor(String levelId, Iterable<String> exerciseIds) {
    final ids = exerciseIds.toList();
    if (ids.isEmpty) return 0;
    var done = 0;
    for (final id in ids) {
      final status = statusOf(levelId, id);
      if (status == ExerciseStatus.mastered ||
          status == ExerciseStatus.needsReview) {
        done++;
      }
    }
    return done / ids.length;
  }

  /// Ratio di esercizi padroneggiati (solo mastered) per il livello indicato.
  double masteredRatioFor(String levelId, Iterable<String> exerciseIds) {
    final ids = exerciseIds.toList();
    if (ids.isEmpty) return 0;
    var mastered = 0;
    for (final id in ids) {
      if (statusOf(levelId, id) == ExerciseStatus.mastered) mastered++;
    }
    return mastered / ids.length;
  }

  /// La lezione lasciata aperta, se l'utente ne ha abbandonata una senza
  /// completarla. È il punto da cui ripartire la sezione «Jump Back In».
  LessonResume? get lessonResume => _resume;

  /// Ricorda la lezione aperta e il passo raggiunto: scritta a ogni cambio di
  /// card, così un kill dell'app non perde il punto di ripresa.
  Future<void> saveLessonResume(LessonResume resume) async {
    _resume = resume;
    notifyListeners();
    await _persistResume();
  }

  /// Chiamata quando la lezione è completata: non c'è più niente da
  /// riprendere, quindi la sezione deve tornare a puntare alla prossima.
  Future<void> clearLessonResume() async {
    if (_resume == null) return;
    _resume = null;
    notifyListeners();
    await _persistResume();
  }

  bool isLessonCompleted(String levelId, String lessonId) =>
      _completedLessons.contains(scopedKey(levelId, lessonId));

  Future<void> completeLesson(String levelId, String lessonId) async {
    if (!_completedLessons.add(scopedKey(levelId, lessonId))) return;
    notifyListeners();
    await _persistLessons();
  }

  static String scopedKey(String levelId, String id) => '$levelId::$id';

  Future<void> _persistLessons() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_lessonsKey, _completedLessons.toList());
  }

  Future<void> _persistResume() async {
    final prefs = await SharedPreferences.getInstance();
    final resume = _resume;
    if (resume == null) {
      await prefs.remove(_resumeKey);
      return;
    }
    await prefs.setString(_resumeKey, jsonEncode(resume.toJson()));
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final list = _progress.values.map((p) => p.toJson()).toList();
    await prefs.setString(_progressKey, jsonEncode(list));
  }
}
