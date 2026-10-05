/// Punto di ripresa di una lezione: quale lezione l'utente ha lasciato
/// aperta e a che passo si era fermato. Vale per qualunque lezione aperta e
/// poi abbandonata senza arrivare in fondo, senza bisogno di un'azione esplicita.
class LessonResume {
  final String ownerId;
  final String levelId;
  final String lessonId;
  final int step;

  const LessonResume({
    this.ownerId = 'guest',
    required this.levelId,
    required this.lessonId,
    required this.step,
  });

  Map<String, dynamic> toJson() {
    return {
      'ownerId': ownerId,
      'levelId': levelId,
      'lessonId': lessonId,
      'step': step,
    };
  }

  factory LessonResume.fromJson(Map<String, dynamic> json) {
    return LessonResume(
      ownerId: json['ownerId'] as String? ?? 'guest',
      levelId: json['levelId'] as String? ?? '',
      lessonId: json['lessonId'] as String? ?? '',
      step: (json['step'] as num?)?.toInt() ?? 0,
    );
  }
}
