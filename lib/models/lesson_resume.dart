/// Punto di ripresa di una lezione: quale lezione l'utente ha lasciato
/// aperta e a che passo si era fermato. Vale per qualunque lezione aperta e
/// poi abbandonata senza arrivare in fondo, senza bisogno di un'azione esplicita.
class LessonResume {
  final String levelId;
  final String lessonId;
  final int step;

  const LessonResume({
    required this.levelId,
    required this.lessonId,
    required this.step,
  });

  Map<String, dynamic> toJson() {
    return {'levelId': levelId, 'lessonId': lessonId, 'step': step};
  }

  factory LessonResume.fromJson(Map<String, dynamic> json) {
    return LessonResume(
      levelId: json['levelId'] as String? ?? '',
      lessonId: json['lessonId'] as String? ?? '',
      step: (json['step'] as num?)?.toInt() ?? 0,
    );
  }
}
