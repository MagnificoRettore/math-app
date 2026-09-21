import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StudyStore extends ChangeNotifier {
  static final StudyStore instance = StudyStore._();
  StudyStore._();

  static const _key = 'study_stats_v1';

  static const int exerciseGoal = 5;
  static const int minutesGoal = 10;

  bool _loaded = false;
  DateTime _today = _dateOnly(DateTime.now());
  DateTime? _lastActiveDate;
  int _currentStreak = 0;
  int _bestStreak = 0;
  int _todayExercises = 0;
  int _todayMinutes = 0;
  final Set<String> _todayExerciseIds = {};
  DateTime? _debugNow;

  bool get loaded => _loaded;
  DateTime get today => _today;
  DateTime? get lastActiveDate => _lastActiveDate;
  int get currentStreak => _currentStreak;
  int get bestStreak => _bestStreak;
  int get todayExercises => _todayExercises;
  int get todayMinutes => _todayMinutes;

  bool get exerciseGoalReached => _todayExercises >= exerciseGoal;
  bool get minutesGoalReached => _todayMinutes >= minutesGoal;
  bool get allGoalsReached => exerciseGoalReached && minutesGoalReached;

  double get exerciseGoalProgress =>
      (_todayExercises / exerciseGoal).clamp(0.0, 1.0);
  double get minutesGoalProgress =>
      (_todayMinutes / minutesGoal).clamp(0.0, 1.0);

  Future<void> load() async {
    if (_loaded) return;
    final today = _dateOnly(_dateNow());
    _rollover();

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null) {
      try {
        final json = jsonDecode(raw) as Map<String, dynamic>;
        _currentStreak = json['currentStreak'] as int? ?? 0;
        _bestStreak = json['bestStreak'] as int? ?? 0;
        final last = json['lastActiveDate'] as String?;
        _lastActiveDate = last == null
            ? null
            : _dateOnly(DateTime.tryParse(last) ?? DateTime.now());
        if (json['today'] == _keyOf(today)) {
          _todayExercises = json['todayExercises'] as int? ?? 0;
          _todayMinutes = json['todayMinutes'] as int? ?? 0;
          final ids = json['todayExerciseIds'] as List<dynamic>? ?? const [];
          _todayExerciseIds
            ..clear()
            ..addAll(ids.cast<String>());
        }
      } catch (_) {
        // dati corrotti: si riparte da zero.
      }
    }
    _today = today;
    _loaded = true;
    notifyListeners();
  }

  Future<bool> recordExerciseCompleted(String exerciseId) async {
    await _ensureLoaded();
    _recordActivity();
    if (_todayExerciseIds.contains(exerciseId)) return false;
    _todayExerciseIds.add(exerciseId);
    final was = exerciseGoalReached;
    _todayExercises++;
    final reached = exerciseGoalReached && !was;
    notifyListeners();
    await _persist();
    return reached;
  }

  Future<bool> addMinutes(int minutes) async {
    await _ensureLoaded();
    _recordActivity();
    final was = minutesGoalReached;
    _todayMinutes += minutes;
    final reached = minutesGoalReached && !was;
    notifyListeners();
    await _persist();
    return reached;
  }

  Future<void> _ensureLoaded() async {
    if (!_loaded) await load();
  }

  void _rollover() {
    final today = _dateOnly(_dateNow());
    if (today != _today) {
      _today = today;
      _todayExercises = 0;
      _todayMinutes = 0;
      _todayExerciseIds.clear();
    }
  }

  void _recordActivity() {
    _rollover();
    final today = _dateOnly(_dateNow());
    if (_lastActiveDate == today) return;
    final yesterday = today.subtract(const Duration(days: 1));
    if (_lastActiveDate != null && _lastActiveDate == yesterday) {
      _currentStreak++;
    } else {
      _currentStreak = 1;
    }
    _lastActiveDate = today;
    if (_currentStreak > _bestStreak) _bestStreak = _currentStreak;
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode({
        'today': _keyOf(_today),
        'lastActiveDate': _lastActiveDate?.toIso8601String(),
        'currentStreak': _currentStreak,
        'bestStreak': _bestStreak,
        'todayExercises': _todayExercises,
        'todayMinutes': _todayMinutes,
        'todayExerciseIds': _todayExerciseIds.toList(),
      }),
    );
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static String _keyOf(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  DateTime _dateNow() => _debugNow ?? DateTime.now();

  @visibleForTesting
  void debugSetNow(DateTime now) {
    _debugNow = now;
  }

  @visibleForTesting
  Future<void> resetForTest() async {
    _loaded = false;
    _today = _dateOnly(_dateNow());
    _lastActiveDate = null;
    _currentStreak = 0;
    _bestStreak = 0;
    _todayExercises = 0;
    _todayMinutes = 0;
    _todayExerciseIds.clear();
    await load();
  }
}
