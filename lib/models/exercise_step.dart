import 'practice_exercise.dart';

/// Un passaggio della soluzione di un esercizio.
///
/// Nel JSON è una stringa (il solo testo del passaggio) oppure un oggetto con
/// `text` e, per la soluzione guidata, la domanda a scelta multipla che lo
/// precede: `prompt`, `options`, `correctIndex` ed eventuale `explanation`
/// (gli stessi campi di `PracticeExercise`).
class ExerciseStep {
  /// Il passaggio come compare nella soluzione.
  final String text;

  /// La domanda da indovinare prima che il passaggio compaia; `null` se il
  /// passaggio è solo testo.
  final PracticeExercise? question;

  const ExerciseStep(this.text, {this.question});

  factory ExerciseStep.fromJson(Object? json) {
    if (json is Map<String, dynamic>) {
      return ExerciseStep(
        json['text'] as String? ?? '',
        question: PracticeExercise.fromJson(json),
      );
    }
    return ExerciseStep(json as String);
  }

  /// `true` se il passaggio ha una domanda con una risposta giusta presente.
  bool get isGuided => question?.hasAnswer ?? false;
}
