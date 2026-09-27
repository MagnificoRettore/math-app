import 'dart:convert';

import 'practice_exercise.dart';

enum LessonStepType {
  info,
  mcq,
  practiceQuiz;

  static LessonStepType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'info':
      case 'definition':
        return LessonStepType.info;
      case 'mcq':
      case 'multiple_choice':
        return LessonStepType.mcq;
      case 'practice_quiz':
      case 'practice':
        return LessonStepType.practiceQuiz;
      default:
        return LessonStepType.info;
    }
  }
}

class LessonStep {
  final LessonStepType type;
  final String title;
  final String content;
  final String prompt;
  final List<String> options;
  final int correctIndex;
  final String explanation;
  final List<PracticeExercise> exercises;
  final double fontSizeMultiplier;

  const LessonStep({
    required this.type,
    required this.title,
    this.content = '',
    this.prompt = '',
    this.options = const [],
    this.correctIndex = -1,
    this.explanation = '',
    this.exercises = const [],
    this.fontSizeMultiplier = 1.0,
  });

  factory LessonStep.fromJson(Map<String, dynamic> json) {
    return LessonStep(
      type: LessonStepType.fromString(json['type'] as String? ?? 'info'),
      title: json['title'] as String? ?? '',
      content: _contentFromJson(json['content']),
      prompt: json['prompt'] as String? ?? '',
      options: (json['options'] as List<dynamic>? ?? const [])
          .map((e) => e as String)
          .toList(),
      correctIndex: json['correctIndex'] as int? ?? -1,
      explanation: json['explanation'] as String? ?? '',
      exercises: (json['exercises'] as List<dynamic>? ?? const [])
          .map((e) => PracticeExercise.fromJson(e as Map<String, dynamic>))
          .toList(),
      fontSizeMultiplier:
          ((json['fontSizeMultiplier'] as num?)?.toDouble() ?? 1.0).clamp(
            0.5,
            2.0,
          ),
    );
  }

  /// `content` può essere una stringa markdown oppure un array di segmenti:
  /// elementi stringa sono righe di testo, elementi mappa sono riquadri
  /// multifunzione (serializzati nella sintassi `::box`/`::endbox`).
  static String _contentFromJson(Object? raw) {
    if (raw is String) return raw;
    if (raw is List) {
      final out = <String>[];
      for (final seg in raw) {
        if (seg is String) {
          out.add(seg);
        } else if (seg is Map<String, dynamic>) {
          out.add('::box\n${jsonEncode(seg)}\n::endbox');
        }
      }
      return out.join('\n');
    }
    return '';
  }

  bool get isQuestion => type == LessonStepType.mcq;

  /// `true` se lo step è una card di verifica: la card non ha testo
  /// introduttivo, mostra solo gli esercizi.
  bool get isPracticeQuiz => type == LessonStepType.practiceQuiz;
}
