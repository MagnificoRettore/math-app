enum LessonStepType {
  info,
  multipleChoice,
  numeric,
  text;

  static LessonStepType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'info':
      case 'definition':
        return LessonStepType.info;
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

class LessonExample {
  final String expression;
  final String note;
  final bool positive;

  const LessonExample({
    required this.expression,
    this.note = '',
    this.positive = true,
  });

  factory LessonExample.fromJson(Map<String, dynamic> json) {
    return LessonExample(
      expression: json['expression'] as String? ?? '',
      note: json['note'] as String? ?? '',
      positive: json['positive'] as bool? ?? true,
    );
  }
}

class NumberLineSpec {
  final int min;
  final int max;
  final List<int> values;

  const NumberLineSpec({
    required this.min,
    required this.max,
    required this.values,
  });

  factory NumberLineSpec.fromJson(Map<String, dynamic> json) {
    return NumberLineSpec(
      min: json['min'] as int? ?? -10,
      max: json['max'] as int? ?? 10,
      values: (json['values'] as List<dynamic>? ?? const [])
          .map((e) => e as int)
          .toList(),
    );
  }
}

class LessonStep {
  final LessonStepType type;
  final String prompt;
  final List<String> cards;
  final List<String> options;
  final int correctIndex;
  final List<String> acceptedAnswers;
  final String explanation;
  final String formula;
  final List<LessonExample> examples;
  final NumberLineSpec? numberLine;

  const LessonStep({
    required this.type,
    required this.prompt,
    this.cards = const [],
    this.options = const [],
    this.correctIndex = -1,
    this.acceptedAnswers = const [],
    this.explanation = '',
    this.formula = '',
    this.examples = const [],
    this.numberLine,
  });

  factory LessonStep.fromJson(Map<String, dynamic> json) {
    return LessonStep(
      type: LessonStepType.fromString(json['type'] as String),
      prompt: json['prompt'] as String,
      cards: (json['cards'] as List<dynamic>? ?? const [])
          .map((e) => e as String)
          .toList(),
      options: (json['options'] as List<dynamic>? ?? const [])
          .map((e) => e as String)
          .toList(),
      correctIndex: json['correctIndex'] as int? ?? -1,
      acceptedAnswers: (json['answers'] as List<dynamic>? ?? const [])
          .map((e) => e as String)
          .toList(),
      explanation: json['explanation'] as String? ?? '',
      formula: json['formula'] as String? ?? '',
      examples: (json['examples'] as List<dynamic>? ?? const [])
          .map((e) => LessonExample.fromJson(e as Map<String, dynamic>))
          .toList(),
      numberLine: json['numberLine'] == null
          ? null
          : NumberLineSpec.fromJson(json['numberLine'] as Map<String, dynamic>),
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
