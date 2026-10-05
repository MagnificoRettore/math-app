import '../models/argomento.dart';
import '../models/lesson.dart';
import '../models/lesson_resume.dart';
import 'lesson_repository.dart';
import 'progress_store.dart';

/// La lezione da riprendere con il suo argomento e il punto di ripresa.
class ResumeTarget {
  final Argomento argomento;
  final Lesson lesson;
  final LessonResume resume;

  const ResumeTarget(this.argomento, this.lesson, this.resume);

  /// La lezione lasciata a metà, se esiste ancora nei contenuti.
  static ResumeTarget? find() {
    final resume = ProgressStore.instance.lessonResume;
    if (resume == null) return null;
    for (final argomento in LessonRepository.instance.argomenti) {
      if (argomento.levelId != resume.levelId) continue;
      for (final lesson in argomento.lessons) {
        if (lesson.id == resume.lessonId) {
          return ResumeTarget(argomento, lesson, resume);
        }
      }
    }
    return null;
  }

  /// Il passo da cui ripartire, dentro le card della lezione.
  int get step {
    final total = lesson.steps.length;
    return resume.step.clamp(0, total == 0 ? 0 : total - 1);
  }

  /// Quanta lezione è fatta, 0..1.
  double get progress {
    final total = lesson.steps.length;
    return total == 0 ? 0 : step / total;
  }
}
