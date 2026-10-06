import 'lesson.dart';

class Argomento {
  final String levelId;
  final String yearId;
  final String sectionId;
  final String topicId;
  final String title;
  final String subtitle;
  final String icon;
  final List<Lesson> lessons;

  const Argomento({
    required this.levelId,
    required this.yearId,
    required this.sectionId,
    required this.topicId,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.lessons,
  });

  /// Quanti esercizi di «Prova tu» ha l'argomento, in tutte le sue lezioni.
  int get practiceExerciseCount => lessons.fold(
    0,
    (sum, lesson) =>
        sum +
        lesson.steps
            .where((step) => step.isPracticeQuiz)
            .fold(0, (n, step) => n + step.exercises.length),
  );

  factory Argomento.fromJson(Map<String, dynamic> json) {
    return Argomento(
      levelId: json['level'] as String,
      yearId: json['year'] as String,
      sectionId: json['section'] as String? ?? '',
      topicId: json['topic'] as String? ?? '',
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      icon: json['icon'] as String? ?? 'menu_book',
      lessons: (json['lessons'] as List<dynamic>? ?? const [])
          .map((e) => Lesson.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
