import 'dart:async';

import 'package:flutter/material.dart';

import '../haptics.dart';
import '../models/exercise_step.dart';
import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import '../theme/app_text.dart';
import 'app_card.dart';
import 'exercise_step_card.dart';
import 'math_text.dart';
import 'mcq_option_tile.dart';
import 'shake.dart';

/// Quanto resta in vista la risposta giusta prima che il passaggio si appenda
/// e compaia la domanda dopo.
const Duration _kAdvanceDelay = Duration(milliseconds: 600);

/// La soluzione di un esercizio passo dopo passo.
///
/// Si vede una domanda alla volta: indovinata, il suo passaggio si appende alla
/// soluzione e compare la domanda successiva; sbagliata, la risposta si segna e
/// si riprova. Finiti i passaggi la soluzione è completa. Domande e opzioni
/// sono le stesse dei quiz delle lezioni (`McqOptionTile`, `ShakeWidget`).
///
/// Tutti i passaggi devono avere una domanda (`Exercise.isGuided`).
class GuidedSolution extends StatefulWidget {
  final List<ExerciseStep> steps;

  const GuidedSolution({super.key, required this.steps});

  @override
  State<GuidedSolution> createState() => _GuidedSolutionState();
}

class _GuidedSolutionState extends State<GuidedSolution> {
  /// I passaggi già indovinati: la soluzione appesa finora.
  int _done = 0;

  /// La risposta giusta data alla domanda in corso, in attesa che il
  /// passaggio si appenda.
  int? _correct;

  /// Le opzioni sbagliate già provate alla domanda in corso.
  final Set<int> _wrong = {};
  int _attempt = 0;
  Timer? _timer;

  bool get _finished => _done >= widget.steps.length;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _select(int index) {
    if (_correct != null || _finished) return;
    final question = widget.steps[_done].question!;
    if (index == question.correctIndex) {
      AppHaptics.lightImpact();
      setState(() => _correct = index);
      final delay = AppMotion.duration(context, _kAdvanceDelay);
      // Col movimento ridotto non si aspetta: il passaggio si appende subito.
      if (delay == Duration.zero) {
        _advance();
      } else {
        _timer = Timer(delay, _advance);
      }
    } else {
      AppHaptics.heavyImpact();
      setState(() {
        _wrong.add(index);
        _attempt++;
      });
    }
  }

  void _advance() {
    if (!mounted) return;
    setState(() {
      _done++;
      _correct = null;
      _wrong.clear();
      _attempt = 0;
    });
    if (_finished) AppHaptics.mediumImpact();
  }

  McqOptionState _stateFor(int index) {
    if (_correct == index) return McqOptionState.correct;
    if (_wrong.contains(index)) return McqOptionState.wrong;
    return McqOptionState.idle;
  }

  @override
  Widget build(BuildContext context) {
    final scale = textScaleFactorOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < _done; i++)
          Padding(
            key: ValueKey('guided-step-$i'),
            padding: const EdgeInsets.only(bottom: 10),
            child: ExerciseStepCard(number: i + 1, text: widget.steps[i].text),
          ),
        AnimatedSwitcher(
          duration: AppMotion.duration(context, AppMotion.slow),
          transitionBuilder: (child, animation) =>
              FadeTransition(opacity: animation, child: child),
          layoutBuilder: (current, previous) =>
              current ?? const SizedBox.shrink(),
          child: _finished
              ? _Completed(key: const ValueKey('guided-done'), scale: scale)
              : _question(scale),
        ),
      ],
    );
  }

  Widget _question(double scale) {
    final c = AppColors.of(context);
    final question = widget.steps[_done].question!;
    return AppCard(
      key: ValueKey('guided-question-$_done'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Passaggio ${_done + 1} di ${widget.steps.length}',
            style: TextStyle(
              fontSize: AppText.label,
              fontWeight: FontWeight.w500,
              color: c.accent,
            ),
          ),
          const SizedBox(height: 8),
          MathText(
            question.prompt,
            fontSize: AppText.titleSmall * scale,
            inline: true,
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < question.options.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              // Sbagliando, la risposta sbagliata si scuote: la chiave nuova a
              // ogni tentativo rifà la scossa solo a lei.
              child: _wrong.contains(i)
                  ? ShakeWidget(
                      key: ValueKey('guided-wrong-$_done-$i-$_attempt'),
                      child: _tile(question.options[i], i, scale),
                    )
                  : _tile(question.options[i], i, scale),
            ),
        ],
      ),
    );
  }

  Widget _tile(String label, int index, double scale) => McqOptionTile(
    key: ValueKey('guided-option-$index'),
    label: label,
    state: _stateFor(index),
    enabled: _correct == null,
    scale: scale,
    onTap: () => _select(index),
  );
}

/// La soluzione è completa.
class _Completed extends StatelessWidget {
  final double scale;

  const _Completed({super.key, required this.scale});

  @override
  Widget build(BuildContext context) {
    return McqFeedbackCard(
      correct: true,
      message: 'Hai completato la soluzione, passo dopo passo.',
      scale: scale,
    );
  }
}
