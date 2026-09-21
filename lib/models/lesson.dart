import 'lesson_step.dart';

class Lesson {
  final String id;
  final String title;
  final String subtitle;
  final int minutes;
  final List<LessonStep> steps;

  const Lesson({
    required this.id,
    required this.title,
    this.subtitle = '',
    this.minutes = 0,
    required this.steps,
  });

  factory Lesson.fromJson(Map<String, dynamic> json) {
    return Lesson(
      id: json['id'] as String,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String? ?? '',
      minutes: json['minutes'] as int? ?? 0,
      steps: (json['steps'] as List<dynamic>? ?? const [])
          .map((e) => LessonStep.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
