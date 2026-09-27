import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
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

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: borderColor,
          width: state == McqOptionState.correct ? 1.8 : 1.2,
        ),
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
                Expanded(child: MathText(label, fontSize: 16 * scale)),
                if (check != null) ...[
                  const SizedBox(width: 10),
                  Icon(check, size: 22, color: iconColor),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

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
      duration: const Duration(milliseconds: 200),
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
                  fontSize: 16 * scale,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
          if (message.isNotEmpty) ...[
            const SizedBox(height: 8),
            MathText(message, fontSize: 14 * scale),
          ],
        ],
      ),
    );
  }
}

/// Scuotimento orizzontale usato sulla risposta sbagliata.
class ShakeWidget extends StatefulWidget {
  final Widget child;

  const ShakeWidget({super.key, required this.child});

  @override
  State<ShakeWidget> createState() => _ShakeWidgetState();
}

class _ShakeWidgetState extends State<ShakeWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );
  late final Animation<double> _shake = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(
        begin: 0.0,
        end: -12.0,
      ).chain(CurveTween(curve: Curves.easeOut)),
      weight: 2,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: -12.0,
        end: 12.0,
      ).chain(CurveTween(curve: Curves.easeInOut)),
      weight: 4,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: 12.0,
        end: -8.0,
      ).chain(CurveTween(curve: Curves.easeInOut)),
      weight: 3,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: -8.0,
        end: 0.0,
      ).chain(CurveTween(curve: Curves.easeOut)),
      weight: 3,
    ),
  ]).animate(_controller);

  @override
  void initState() {
    super.initState();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) =>
          Transform.translate(offset: Offset(_shake.value, 0), child: child),
      child: widget.child,
    );
  }
}
