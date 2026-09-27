/// Un esercizio a scelta multipla di uno step `practice_quiz`.
///
/// `prompt` è la traccia: può essere un'equazione (`$$...$$`), un'immagine
/// (percorso di asset o URL) o testo misto inline. `text` è la parte discorsiva
/// facoltativa. `correctIndex` punta alla risposta giusta dentro `options`.
class PracticeExercise {
  final String prompt;
  final String text;
  final List<String> options;
  final int correctIndex;
  final String explanation;

  const PracticeExercise({
    required this.prompt,
    this.text = '',
    this.options = const [],
    this.correctIndex = -1,
    this.explanation = '',
  });

  factory PracticeExercise.fromJson(Map<String, dynamic> json) {
    return PracticeExercise(
      prompt: json['prompt'] as String? ?? '',
      text: json['text'] as String? ?? '',
      options: (json['options'] as List<dynamic>? ?? const [])
          .map((e) => e as String)
          .toList(),
      correctIndex: json['correctIndex'] as int? ?? -1,
      explanation: json['explanation'] as String? ?? '',
    );
  }

  /// `true` solo se [correctIndex] punta davvero a una risposta presente.
  bool get hasAnswer => correctIndex >= 0 && correctIndex < options.length;

  Map<String, dynamic> toJson() => {
    'prompt': prompt,
    if (text.isNotEmpty) 'text': text,
    'options': options,
    'correctIndex': correctIndex,
    if (explanation.isNotEmpty) 'explanation': explanation,
  };
}
