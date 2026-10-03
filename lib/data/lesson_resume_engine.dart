import '../models/lesson.dart';
import '../models/lesson_target.dart';
import 'lesson_repository.dart';
import 'progress_store.dart';

/// Sceglie su quale lezione deve puntare la sezione «Jump Back In».
///
/// La catena è: la lezione lasciata aperta, altrimenti la non completata più
/// vicina che segue quella lezione. Senza una lezione mai aperta non c'è un
/// punto da cui ripartire, quindi la sezione resta nascosta: non si parte mai
/// da un argomento a caso.
class LessonResumeEngine {
  const LessonResumeEngine._();

  static LessonTarget? target({required String levelId}) {
    if (levelId.isEmpty) return null;

    final store = ProgressStore.instance;
    final resume = store.lessonResume;
    if (resume == null) return null;
    if (resume.levelId != levelId) return null;

    final repository = LessonRepository.instance;
    final anchor = repository.argomentoFor(levelId, resume.lessonId);
    if (anchor == null) return null;

    if (!store.isLessonCompleted(levelId, resume.lessonId)) {
      final lesson = anchor.lessons.firstWhere((l) => l.id == resume.lessonId);
      return LessonTarget(
        argomento: anchor,
        lesson: lesson,
        step: _clampStep(resume.step, lesson),
        isPaused: true,
      );
    }

    // La lezione in pausa è stata completata altrove: si cerca la più vicina
    // non completata, prima dentro il suo stesso argomento e poi nei
    // successivi dello stesso anno. Finito anche l'anno, niente da proporre.
    final argomenti = repository.argomentiInYear(levelId, anchor.yearId);
    for (final argomento in argomenti) {
      for (final lesson in argomento.lessons) {
        if (identical(argomento, anchor) && lesson.id == resume.lessonId) {
          continue;
        }
        if (store.isLessonCompleted(levelId, lesson.id)) continue;
        return LessonTarget(
          argomento: argomento,
          lesson: lesson,
          step: 0,
          isPaused: false,
        );
      }
    }
    return null;
  }

  /// Quanto si è avanti dentro l'argomento della lezione indicata.
  ///
  /// Il conteggio è posizionale, non di merito: contano le card superate della
  /// lezione corrente e tutte le card delle lezioni che la precedono
  /// nell'argomento, anche se non sono mai state aperte. Un argomento si
  /// affronta in ordine, quindi la barra dice dove si è, non cosa si è fatto.
  static double topicProgress(LessonTarget target) {
    final conteggio = topicCards(target);
    if (conteggio == null) return 0;
    return conteggio.total == 0
        ? 0
        : (conteggio.passed / conteggio.total).clamp(0.0, 1.0);
  }

  /// Card superate e card totali dell'argomento, per poter scrivere «N di M»
  /// accanto alla percentuale senza rifare il conteggio in un secondo posto.
  ///
  /// Vedi `topicProgress` sul perché il conteggio è posizionale.
  static ({int passed, int total})? topicCards(LessonTarget target) {
    final lezioni = target.argomento.lessons;
    final indice = lezioni.indexWhere((l) => l.id == target.lesson.id);
    if (indice < 0) return null;

    var total = 0;
    var superate = target.step;
    for (var i = 0; i < lezioni.length; i++) {
      final step = lezioni[i].steps.length;
      total += step;
      if (i < indice) superate += step;
    }
    return (passed: superate, total: total);
  }

  /// Il passo salvato può superare la lunghezza della lezione se nel
  /// frattempo il contenuto è cambiato.
  static int _clampStep(int step, Lesson lesson) {
    if (lesson.steps.isEmpty) return 0;
    return step.clamp(0, lesson.steps.length - 1);
  }
}
