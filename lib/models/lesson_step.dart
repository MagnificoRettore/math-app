enum LessonStepType {
  multipleChoice,
  numeric,
  text;

  static LessonStepType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'mcq':
      case 'multiple_choice':
        return LessonStepType.multipleChoice;
      case 'numeric':
        return LessonStepType.numeric;
      default:
        return LessonStepType.text;
    }
  }
}

class LessonStep {
  final LessonStepType type;
  final String prompt;
  final List<String> options;
  final int correctIndex;
  final List<String> acceptedAnswers;
  final String explanation;

  const LessonStep({
    required this.type,
    required this.prompt,
    this.options = const [],
    this.correctIndex = -1,
    this.acceptedAnswers = const [],
    this.explanation = '',
  });

  factory LessonStep.fromJson(Map<String, dynamic> json) {
    return LessonStep(
      type: LessonStepType.fromString(json['type'] as String),
      prompt: json['prompt'] as String,
      options: (json['options'] as List<dynamic>? ?? const [])
          .map((e) => e as String)
          .toList(),
      correctIndex: json['correctIndex'] as int? ?? -1,
      acceptedAnswers: (json['answers'] as List<dynamic>? ?? const [])
          .map((e) => e as String)
          .toList(),
      explanation: json['explanation'] as String? ?? '',
    );
  }

  bool checkAnswer(String input) {
    final normalized = _normalize(input);
    for (final answer in acceptedAnswers) {
      if (_equalValue(normalized, _normalize(answer))) return true;
    }
    return false;
  }

  static String _normalize(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), '')
        .replaceAll(',', '.');
  }

  static bool _equalValue(String a, String b) {
    if (a == b) return true;
    final da = _toDouble(a);
    final db = _toDouble(b);
    return da != null && db != null && (da - db).abs() < 1e-6;
  }

  static double? _toDouble(String s) {
    final whole = double.tryParse(s);
    if (whole != null) return whole;
    final slash = s.indexOf('/');
    if (slash > 0) {
      final num = double.tryParse(s.substring(0, slash));
      final den = double.tryParse(s.substring(slash + 1));
      if (num != null && den != null && den != 0) return num / den;
    }
    return null;
  }
}
