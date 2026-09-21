enum LessonStepType {
  info,
  mcq;

  static LessonStepType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'info':
      case 'definition':
        return LessonStepType.info;
      case 'mcq':
      case 'multiple_choice':
        return LessonStepType.mcq;
      default:
        return LessonStepType.info;
    }
  }
}

class LessonStep {
  final LessonStepType type;
  final String title;
  final String content;
  final List<String> options;
  final int correctIndex;
  final String explanation;

  const LessonStep({
    required this.type,
    required this.title,
    this.content = '',
    this.options = const [],
    this.correctIndex = -1,
    this.explanation = '',
  });

  factory LessonStep.fromJson(Map<String, dynamic> json) {
    return LessonStep(
      type: LessonStepType.fromString(json['type'] as String? ?? 'info'),
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      options: (json['options'] as List<dynamic>? ?? const [])
          .map((e) => e as String)
          .toList(),
      correctIndex: json['correctIndex'] as int? ?? -1,
      explanation: json['explanation'] as String? ?? '',
    );
  }

  bool get isQuestion => type == LessonStepType.mcq;
}
