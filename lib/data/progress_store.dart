import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/progress.dart';

class ProgressStore extends ChangeNotifier {
  static final ProgressStore instance = ProgressStore._();
  ProgressStore._();

  static const _key = 'exercise_progress_v1';
  static const _lessonsKey = 'lessons_completed_v1';

  final Map<String, ExerciseProgress> _progress = {};
  final Set<String> _completedLessons = {};
  bool _loaded = false;
  Object? _loadError;

  bool get loaded => _loaded;
  Object? get loadError => _loadError;

  Future<void> load() async {
    if (_loaded) return;
    _loadError = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw != null) {
        final list = jsonDecode(raw) as List<dynamic>;
        for (final item in list) {
          final p = ExerciseProgress.fromJson(item as Map<String, dynamic>);
          _progress[p.exerciseId] = p;
        }
      }
      final done = prefs.getStringList(_lessonsKey);
      if (done != null) {
        _completedLessons.addAll(done);
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
    await load();
  }

  ExerciseProgress? forExercise(String id) => _progress[id];

  ExerciseStatus statusOf(String id) =>
      _progress[id]?.status ?? ExerciseStatus.none;

  bool isBookmarked(String id) => _progress[id]?.bookmarked ?? false;

  Future<void> setStatus(String id, ExerciseStatus status) async {
    final current = _progress[id] ??
        ExerciseProgress(exerciseId: id, status: ExerciseStatus.none, bookmarked: false);
    _progress[id] = current.copyWith(status: status);
    notifyListeners();
    await _persist();
  }

  Future<void> toggleBookmark(String id) async {
    final current = _progress[id] ??
        ExerciseProgress(exerciseId: id, status: ExerciseStatus.none, bookmarked: false);
    _progress[id] = current.copyWith(bookmarked: !current.bookmarked);
    notifyListeners();
    await _persist();
  }

  List<String> get bookmarkedIds =>
      _progress.entries.where((e) => e.value.bookmarked).map((e) => e.key).toList();

  double completionFor(Iterable<String> exerciseIds) {
    final ids = exerciseIds.toList();
    if (ids.isEmpty) return 0;
    var done = 0;
    for (final id in ids) {
      final status = statusOf(id);
      if (status == ExerciseStatus.mastered ||
          status == ExerciseStatus.needsReview) {
        done++;
      }
    }
    return done / ids.length;
  }

  bool isLessonCompleted(String id) => _completedLessons.contains(id);

  Set<String> get completedLessonIds => Set.unmodifiable(_completedLessons);

  Future<void> completeLesson(String id) async {
    if (!_completedLessons.add(id)) return;
    notifyListeners();
    await _persistLessons();
  }

  Future<void> _persistLessons() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_lessonsKey, _completedLessons.toList());
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final list = _progress.values.map((p) => p.toJson()).toList();
    await prefs.setString(_key, jsonEncode(list));
  }
}
