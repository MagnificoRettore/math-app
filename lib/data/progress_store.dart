import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/progress.dart';

class ProgressStore extends ChangeNotifier {
  static final ProgressStore instance = ProgressStore._();
  ProgressStore._();

  static const _progressKey = 'exercise_progress_v1';

  final Map<String, ExerciseProgress> _progress = {};
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
      _loaded = true;
      notifyListeners();
    } catch (error) {
      _loadError = error;
    }
  }

  Future<void> reload() async {
    _loaded = false;
    _progress.clear();
    await load();
  }

  @visibleForTesting
  Future<void> resetForTest() async {
    _loaded = false;
    _progress.clear();
    _loadError = null;
    await load();
  }

  /// Restituisce il progresso per un esercizio nel livello scolastico indicato.
  ExerciseProgress? forExercise(String levelId, String exerciseId) =>
      _progress[scopedKey(levelId, exerciseId)];

  ExerciseStatus statusOf(String levelId, String exerciseId) =>
      _progress[scopedKey(levelId, exerciseId)]?.status ?? ExerciseStatus.none;

  bool isBookmarked(String levelId, String exerciseId) =>
      _progress[scopedKey(levelId, exerciseId)]?.bookmarked ?? false;

  Future<void> setStatus(
    String levelId,
    String exerciseId,
    ExerciseStatus status,
  ) async {
    final key = scopedKey(levelId, exerciseId);
    final current =
        _progress[key] ??
        ExerciseProgress(
          exerciseId: exerciseId,
          status: ExerciseStatus.none,
          bookmarked: false,
        );
    _progress[key] = current.copyWith(status: status);
    notifyListeners();
    await _persist();
  }

  Future<void> toggleBookmark(String levelId, String exerciseId) async {
    final current =
        _progress[scopedKey(levelId, exerciseId)] ??
        ExerciseProgress(
          exerciseId: exerciseId,
          status: ExerciseStatus.none,
          bookmarked: false,
        );
    _progress[scopedKey(levelId, exerciseId)] =
        current.copyWith(bookmarked: !current.bookmarked);
    notifyListeners();
    await _persist();
  }

  /// Id dei segnalibri del livello scolastico indicato (esercizi marcati).
  List<String> bookmarkedIdsFor(String levelId) => _progress.entries
      .where((e) => e.key.startsWith('$levelId::') && e.value.bookmarked)
      .map((e) => e.value.exerciseId)
      .toList();

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

  static String scopedKey(String levelId, String id) => '$levelId::$id';

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final list = _progress.values.map((p) => p.toJson()).toList();
    await prefs.setString(_progressKey, jsonEncode(list));
  }
}
