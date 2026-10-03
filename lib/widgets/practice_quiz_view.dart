import 'dart:math';

import 'package:flutter/material.dart';

import '../haptics.dart';
import '../models/practice_exercise.dart';
import '../theme/app_text.dart';
import 'math_text.dart';
import 'mcq_option_tile.dart';
import 'prompt_view.dart';

/// Corpo di uno step `practice_quiz`: mostra **un solo** esercizio per volta,
/// scelto dal primo dell'array. Il tasto per caricarne un altro a caso sta nel
/// footer della card (vedi `LessonScreen`) e chiama [reload].
class PracticeQuizView extends StatefulWidget {
  final List<PracticeExercise> exercises;

  /// Stessa scala di `fontSizeMultiplier` degli altri step.
  final double scale;

  const PracticeQuizView({
    super.key,
    required this.exercises,
    this.scale = 1.0,
  });

  /// `true` se c'è più di un esercizio da cui pescare.
  bool get canReload => exercises.length > 1;

  @override
  PracticeQuizViewState createState() => PracticeQuizViewState();
}

class PracticeQuizViewState extends State<PracticeQuizView> {
  final Random _random = Random();

  int _current = 0;
  late List<int> _queue = [for (var i = 1; i < widget.exercises.length; i++) i]
    ..shuffle(_random);

  int? _selected;
  final Set<int> _wrong = {};
  int _attemptId = 0;
  bool _solved = false;

  /// Estrae l'esercizio successivo da una coda mescolata, senza ripeterlo finché
  /// il giro non si esaurisce.
  void reload() {
    if (!widget.canReload) return;
    if (_queue.isEmpty) {
      _queue = [
        for (var i = 0; i < widget.exercises.length; i++)
          if (i != _current) i,
      ]..shuffle(_random);
    }
    setState(() {
      _current = _queue.removeAt(0);
      _selected = null;
      _wrong.clear();
      _attemptId = 0;
      _solved = false;
    });
  }

  void _select(PracticeExercise exercise, int index) {
    if (_solved || !exercise.hasAnswer) return;
    if (index == exercise.correctIndex) {
      AppHaptics.lightImpact();
      setState(() {
        _selected = index;
        _solved = true;
      });
    } else {
      AppHaptics.heavyImpact();
      setState(() {
        _wrong.add(index);
        _attemptId++;
      });
    }
  }

  McqOptionState _stateFor(PracticeExercise exercise, int index) {
    if (_solved && index == exercise.correctIndex) {
      return McqOptionState.correct;
    }
    if (_wrong.contains(index)) return McqOptionState.wrong;
    if (_selected == index) return McqOptionState.selected;
    return McqOptionState.idle;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.exercises.isEmpty) return const SizedBox.shrink();
    final exercise = widget.exercises[_current];
    final scale = widget.scale;
    // `layoutBuilder` restituisce solo il child corrente: l'esercizio uscente
    // sparisce subito, senza sovrapporlo a quello entrante.
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      layoutBuilder: (current, previous) => current ?? const SizedBox.shrink(),
      transitionBuilder: (child, animation) =>
          FadeTransition(opacity: animation, child: child),
      child: Column(
        key: ValueKey('exercise_$_current'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PromptView(
            prompt: exercise.prompt,
            fontSize: AppText.titleMedium * scale,
          ),
          if (exercise.text.isNotEmpty) ...[
            const SizedBox(height: 10),
            MathText(exercise.text, fontSize: AppText.bodyLarge * scale),
          ],
          const SizedBox(height: 16),
          for (var i = 0; i < exercise.options.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: McqOptionTile(
                key: ValueKey('quiz_option_$i'),
                label: exercise.options[i],
                state: _stateFor(exercise, i),
                enabled: !_solved,
                scale: scale,
                onTap: () => _select(exercise, i),
              ),
            ),
          const SizedBox(height: 8),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            transitionBuilder: (child, animation) =>
                FadeTransition(opacity: animation, child: child),
            child: _solved
                ? McqFeedbackCard(
                    key: const ValueKey('correct'),
                    correct: true,
                    message: exercise.explanation,
                    scale: scale,
                  )
                : _wrong.isNotEmpty
                ? ShakeWidget(
                    key: ValueKey('wrong-$_attemptId'),
                    child: McqFeedbackCard(
                      correct: false,
                      message: 'Non è corretto. Riprova!',
                      scale: scale,
                    ),
                  )
                : const SizedBox.shrink(key: ValueKey('idle')),
          ),
        ],
      ),
    );
  }
}
