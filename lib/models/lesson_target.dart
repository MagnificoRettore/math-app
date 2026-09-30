import 'argomento.dart';
import 'lesson.dart';

/// La lezione su cui la sezione «Jump Back In» punta, con il passo da cui
/// ripartire.
class LessonTarget {
  final Argomento argomento;
  final Lesson lesson;

  /// Passo da cui riaprire la lezione, zero-based.
  final int step;

  /// Vero quando è proprio la lezione lasciata aperta, falso quando è la
  /// prima non completata trovata dalla catena di ripescaggio.
  final bool isPaused;

  const LessonTarget({
    required this.argomento,
    required this.lesson,
    required this.step,
    required this.isPaused,
  });
}
