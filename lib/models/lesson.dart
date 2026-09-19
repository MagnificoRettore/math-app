import 'lesson_step.dart';

enum LessonAnimation {
  pie,
  numberLine,
  none;

  static LessonAnimation fromString(String value) {
    switch (value.toLowerCase()) {
      case 'pie':
        return LessonAnimation.pie;
      case 'number_line':
      case 'numberline':
        return LessonAnimation.numberLine;
      default:
        return LessonAnimation.none;
    }
  }
}

class Lesson {
  final String id;
  final String title;
  final String subtitle;
  final String icon;
  final String introduction;
  final String? image;
  final String completionMessage;
  final LessonAnimation animation;
  final String levelId;
  final String sectionId;
  final String yearId;
  final List<String> topics;
  final List<LessonStep> steps;

  const Lesson({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.introduction,
    this.image,
    required this.completionMessage,
    required this.animation,
    required this.levelId,
    this.sectionId = '',
    this.yearId = '',
    this.topics = const [],
    required this.steps,
  });

  factory Lesson.fromJson(Map<String, dynamic> json) {
    return Lesson(
      id: json['id'] as String,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String? ?? '',
      icon: json['icon'] as String? ?? 'menu_book',
      introduction: json['introduction'] as String? ?? '',
      image: json['image'] as String?,
      completionMessage: json['completionMessage'] as String? ?? '',
      animation: LessonAnimation.fromString(json['animation'] as String? ?? ''),
      levelId: json['level'] as String? ?? '',
      sectionId: json['section'] as String? ?? '',
      yearId: json['year'] as String? ?? '',
      topics: (json['topics'] as List<dynamic>? ?? const [])
          .map((e) => e as String)
          .toList(),
      steps: (json['steps'] as List<dynamic>? ?? const [])
          .map((e) => LessonStep.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
