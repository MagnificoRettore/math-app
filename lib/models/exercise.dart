import 'difficulty.dart';

class Exercise {
  final String id;
  final String title;
  final Difficulty difficulty;
  final List<String> tags;
  final String problem;
  final List<String> formulas;
  final List<String> hints;
  final List<String> steps;

  const Exercise({
    required this.id,
    required this.title,
    required this.difficulty,
    required this.tags,
    required this.problem,
    required this.formulas,
    required this.hints,
    required this.steps,
  });

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      id: json['id'] as String,
      title: json['title'] as String,
      difficulty: Difficulty.fromString(json['difficulty'] as String),
      tags: (json['tags'] as List<dynamic>? ?? const [])
          .map((e) => e as String)
          .toList(),
      problem: json['problem'] as String,
      formulas: (json['formulas'] as List<dynamic>? ?? const [])
          .map((e) => e as String)
          .toList(),
      hints: (json['hints'] as List<dynamic>? ?? const [])
          .map((e) => e as String)
          .toList(),
      steps: (json['steps'] as List<dynamic>? ?? const [])
          .map((e) => e as String)
          .toList(),
    );
  }
}
