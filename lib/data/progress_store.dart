import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/argomento.dart';
import '../models/argomento_status.dart';
import '../models/lesson_resume.dart';
import '../models/progress.dart';
import 'auth_store.dart';

class ProgressStore extends ChangeNotifier {
  static final ProgressStore instance = ProgressStore._();
  ProgressStore._();

  static const _progressKey = 'exercise_progress_v1';
  static const _lessonsKey = 'lessons_completed_v1';
  static const _resumeKey = 'lessons_in_progress_v1';
  static const _quizKey = 'quiz_results_v1';

  /// Quanti esercizi di «Prova tu» giusti al primo colpo superano un argomento
  /// (meno, se l'argomento ne ha meno).
  static const quizPassCount = 3;

  final Map<String, ExerciseProgress> _progress = {};
  final Set<String> _completedLessons = {};

  /// Gli esiti di «Prova tu» per lezione (`scopedKey`): gli esercizi giusti al
  /// primo colpo e se almeno uno è stato sbagliato.
  final Map<String, _QuizRecord> _quizResults = {};
  LessonResume? _resume;
  bool _loaded = false;
  Object? _loadError;
  String _lastOwner = ExerciseProgress.guestOwner;
  bool _listening = false;

  /// Di chi sono i progressi che si vedono: l'account della sessione, o
  /// l'ospite. Cambiando utente cambiano i progressi, senza toccare quelli
  /// dell'altro.
  String get ownerId =>
      AuthStore.instance.currentUser?.accountId ?? ExerciseProgress.guestOwner;

  void _onAuthChanged() {
    final owner = ownerId;
    if (owner == _lastOwner) return;
    _lastOwner = owner;
    notifyListeners();
  }

  bool get loaded => _loaded;
  Object? get loadError => _loadError;

  Future<void> load() async {
    if (_loaded) return;
    _loadError = null;
    if (!_listening) {
      _listening = true;
      AuthStore.instance.addListener(_onAuthChanged);
    }
    _lastOwner = ownerId;
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
        // Una chiave di prima ha due parti (`livello::lezione`): era dell'uso
        // senza account, e diventa dell'ospite.
        _completedLessons.addAll(
          done.map(
            (key) => '::'.allMatches(key).length == 1
                ? '${ExerciseProgress.guestOwner}::$key'
                : key,
          ),
        );
      }
      final rawQuiz = prefs.getString(_quizKey);
      if (rawQuiz != null) {
        final map = jsonDecode(rawQuiz) as Map<String, dynamic>;
        map.forEach((key, value) {
          _quizResults[key] = _QuizRecord.fromJson(
            value as Map<String, dynamic>,
          );
        });
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
    _quizResults.clear();
    _resume = null;
    await load();
  }

  @visibleForTesting
  Future<void> resetForTest() async {
    _loaded = false;
    _progress.clear();
    _completedLessons.clear();
    _quizResults.clear();
    _resume = null;
    _loadError = null;
    await load();
  }

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
        ExerciseProgress(
          ownerId: ownerId,
          levelId: levelId,
          exerciseId: exerciseId,
          status: ExerciseStatus.none,
        );
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
  LessonResume? get lessonResume =>
      _resume?.ownerId == ownerId ? _resume : null;

  /// Ricorda la lezione aperta e il passo raggiunto: scritta a ogni cambio di
  /// card, così un kill dell'app non perde il punto di ripresa.
  Future<void> saveLessonResume(LessonResume resume) async {
    // Il punto è dell'utente di adesso, chiunque costruisca il `LessonResume`.
    _resume = LessonResume(
      ownerId: ownerId,
      levelId: resume.levelId,
      lessonId: resume.lessonId,
      step: resume.step,
    );
    notifyListeners();
    await _persistResume();
  }

  /// Chiamata quando la lezione è completata: non c'è più niente da
  /// riprendere, quindi la sezione deve tornare a puntare alla prossima.
  Future<void> clearLessonResume() async {
    if (lessonResume == null) return;
    _resume = null;
    notifyListeners();
    await _persistResume();
  }

  bool isLessonCompleted(String levelId, String lessonId) =>
      _completedLessons.contains(scopedKey(levelId, lessonId));

  /// Quante lezioni dell'argomento sono completate.
  int completedLessonCount(Argomento argomento) => argomento.lessons
      .where((lesson) => isLessonCompleted(argomento.levelId, lesson.id))
      .length;

  /// Un argomento è completato quando lo sono tutte le sue lezioni; uno senza
  /// lezioni no, perché non c'è niente da completare.
  bool isArgomentoCompleted(Argomento argomento) =>
      argomento.lessons.isNotEmpty &&
      argomento.lessons.every(
        (lesson) => isLessonCompleted(argomento.levelId, lesson.id),
      );

  /// Registra la prima risposta a un esercizio di «Prova tu»: [correct] se è
  /// giusta al primo colpo, altrimenti è un errore. Gli errori dopo la prima
  /// risposta sbagliata dello stesso esercizio non si ripetono: lo chiama
  /// `PracticeQuizView` una volta per tentativo.
  Future<void> recordQuizAnswer(
    String levelId,
    String lessonId, {
    required int step,
    required int exercise,
    required bool correct,
  }) async {
    final record = _quizResults.putIfAbsent(
      scopedKey(levelId, lessonId),
      _QuizRecord.new,
    );
    if (correct) {
      if (!record.correct.add('$step#$exercise')) return;
    } else {
      if (record.failed) return;
      record.failed = true;
    }
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _quizKey,
      jsonEncode(_quizResults.map((k, v) => MapEntry(k, v.toJson()))),
    );
  }

  /// Lo stato dell'argomento per il badge. «Superato» è aver risposto giusto
  /// al primo colpo a 3 esercizi diversi di «Prova tu» (meno se l'argomento ne
  /// ha meno); senza esercizi basta aver finito le lezioni. «Non superato» è
  /// un errore nella prova non ancora rimediato.
  ArgomentoStatus statusOfArgomento(Argomento argomento) {
    final records = [
      for (final lesson in argomento.lessons)
        ?_quizResults[scopedKey(argomento.levelId, lesson.id)],
    ];
    final total = argomento.practiceExerciseCount;
    if (total > 0) {
      final need = total < quizPassCount ? total : quizPassCount;
      final correct = records.fold(0, (sum, r) => sum + r.correct.length);
      if (correct >= need) return ArgomentoStatus.passed;
      if (records.any((r) => r.failed)) return ArgomentoStatus.failed;
    } else if (isArgomentoCompleted(argomento)) {
      return ArgomentoStatus.passed;
    }
    final resume = lessonResume;
    final started =
        completedLessonCount(argomento) > 0 ||
        records.isNotEmpty ||
        (resume != null &&
            resume.levelId == argomento.levelId &&
            argomento.lessons.any((l) => l.id == resume.lessonId));
    return started ? ArgomentoStatus.started : ArgomentoStatus.notStarted;
  }

  Future<void> completeLesson(String levelId, String lessonId) async {
    if (!_completedLessons.add(scopedKey(levelId, lessonId))) return;
    notifyListeners();
    await _persistLessons();
  }

  String scopedKey(String levelId, String id) => '$ownerId::$levelId::$id';

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

class _QuizRecord {
  final Set<String> correct;
  bool failed;

  _QuizRecord({Set<String>? correct, this.failed = false})
    : correct = correct ?? {};

  factory _QuizRecord.fromJson(Map<String, dynamic> json) => _QuizRecord(
    correct: {
      ...(json['correct'] as List<dynamic>? ?? const []).cast<String>(),
    },
    failed: json['failed'] as bool? ?? false,
  );

  Map<String, dynamic> toJson() => {
    'correct': correct.toList(),
    'failed': failed,
  };
}
