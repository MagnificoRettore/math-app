import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import '../theme/app_text.dart';
import 'math_text.dart';

enum McqOptionState { idle, selected, correct, wrong }

/// Riga di risposta di un esercizio a scelta multipla, con gli stati
/// colorati di risposta indovinata, sbagliata, selezionata e neutra.
class McqOptionTile extends StatelessWidget {
  final String label;
  final McqOptionState state;
  final bool enabled;
  final double scale;
  final VoidCallback onTap;

  const McqOptionTile({
    super.key,
    required this.label,
    required this.state,
    required this.enabled,
    required this.scale,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final (borderColor, fillColor, iconColor, check) = switch (state) {
      McqOptionState.correct => (
        c.easy,
        c.easy.withValues(alpha: 0.12),
        c.easy,
        Icons.check_circle,
      ),
      McqOptionState.wrong => (
        c.hard,
        c.hard.withValues(alpha: 0.10),
        c.hard,
        null,
      ),
      McqOptionState.selected => (c.accent, c.accentSoft, c.accent, null),
      McqOptionState.idle => (c.border, c.surface, c.textSecondary, null),
    };

    final reduced = AppMotion.reduced(context);
    final tile = AnimatedContainer(
      duration: AppMotion.duration(context, AppMotion.medium),
      curve: AppMotion.standard,
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(14),
        // Il bordo da 3 dei controlli del design: lilla a riposo, poi il
        // colore dello stato.
        border: Border.all(color: borderColor, width: 3),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: MathText(
                    label,
                    fontSize: AppText.titleSmall * scale,
                    inline: true,
                  ),
                ),
                if (check != null) ...[
                  const SizedBox(width: 10),
                  // La spunta entra in scala con il rimbalzo, al montaggio.
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: reduced ? 1 : 0, end: 1),
                    duration: AppMotion.duration(context, AppMotion.slow),
                    curve: AppMotion.bounce,
                    builder: (context, value, child) =>
                        Transform.scale(scale: value, child: child),
                    child: Icon(check, size: 22, color: iconColor),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
    // Il pop della risposta giusta: una campana di scala, 1 → 1.06 → 1,
    // mentre il valore va da 0 a 1. È un'animazione implicita e sempre
    // presente: la struttura non cambia, quindi il passaggio di colore non
    // riparte, e a differenza di un `Animate` non lascia timer al montaggio.
    return TweenAnimationBuilder<double>(
      tween: Tween(end: state == McqOptionState.correct ? 1 : 0),
      duration: AppMotion.duration(context, AppMotion.slow),
      curve: AppMotion.standard,
      builder: (context, value, child) => Transform.scale(
        scale: 1 + (_kPop - 1) * math.sin(math.pi * value),
        child: child,
      ),
      child: tile,
    );
  }
}

/// Quanto cresce l'opzione giusta al culmine del pop.
const double _kPop = 1.06;

/// Esito della risposta: messaggio verde su quella giusta, rosso su quella
/// sbagliata.
class McqFeedbackCard extends StatelessWidget {
  final bool correct;
  final String message;
  final double scale;

  const McqFeedbackCard({
    super.key,
    required this.correct,
    required this.message,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final color = correct ? c.easy : c.hard;
    return AnimatedContainer(
      duration: AppMotion.duration(context, AppMotion.medium),
      curve: AppMotion.standard,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                correct ? Icons.check_circle : Icons.cancel_outlined,
                color: color,
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                correct ? 'Corretto!' : 'Non è corretto',
                style: TextStyle(
                  fontSize: AppText.titleSmall * scale,
                  fontFamily: AppText.headingFont,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
          if (message.isNotEmpty) ...[
            const SizedBox(height: 8),
            MathText(
              message,
              fontSize: AppText.bodyMedium * scale,
              inline: true,
            ),
          ],
        ],
      ),
    );
  }
}
