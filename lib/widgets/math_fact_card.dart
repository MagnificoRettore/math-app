import 'package:flutter/material.dart';

import '../data/math_facts.dart';
import '../haptics.dart';
import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import '../theme/app_text.dart';
import 'app_card.dart';

/// «Lo sapevi?»: una curiosità sulla matematica, tutta offline.
///
/// Di partenza ce n'è una per giorno (il giorno dell'anno sul numero delle
/// curiosità), così non cambia a ogni rebuild; il tocco passa alla successiva.
class MathFactCard extends StatefulWidget {
  const MathFactCard({super.key});

  @override
  State<MathFactCard> createState() => _MathFactCardState();
}

class _MathFactCardState extends State<MathFactCard> {
  late int _index = _today() % mathFacts.length;

  static int _today() {
    final now = DateTime.now();
    return now.difference(DateTime(now.year)).inDays;
  }

  /// Solo dopo un tocco la curiosità si scrive a macchina: la prima, quella del
  /// giorno, c'è già.
  bool _typing = false;

  void _next() {
    AppHaptics.selectionClick();
    setState(() {
      _index = (_index + 1) % mathFacts.length;
      _typing = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return AppCard(
      key: const Key('math-fact-card'),
      onTap: _next,
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: c.yellow,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.lightbulb_outline_rounded,
                  color: c.textPrimary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'Lo sapevi?',
                  style: TextStyle(
                    fontFamily: AppText.headingFont,
                    fontSize: AppText.title,
                    fontWeight: FontWeight.w600,
                    color: c.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _TypedText(
            key: ValueKey(_index),
            text: mathFacts[_index],
            animate: _typing,
            style: TextStyle(
              fontSize: AppText.bodyLarge,
              height: 1.5,
              color: c.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(Icons.refresh_rounded, size: 16, color: c.accent),
              const SizedBox(width: 6),
              Text(
                'Un\'altra curiosità',
                style: TextStyle(
                  fontSize: AppText.label,
                  fontWeight: FontWeight.w500,
                  color: c.accent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Il testo che si scrive lettera per lettera, come una risposta generata.
///
/// Le lettere ancora da scrivere ci sono già, trasparenti: il testo occupa
/// subito tutta la sua altezza e la card non cresce mentre si scrive. Il
/// tempo è per lettera, con un tetto, così le curiosità lunghe non fanno
/// aspettare. Col movimento ridotto compare tutto insieme.
class _TypedText extends StatelessWidget {
  final String text;
  final bool animate;
  final TextStyle style;

  const _TypedText({
    super.key,
    required this.text,
    required this.animate,
    required this.style,
  });

  static const _perLetter = Duration(milliseconds: 22);
  static const _cap = Duration(milliseconds: 1800);

  @override
  Widget build(BuildContext context) {
    if (!animate || AppMotion.reduced(context)) {
      return Text(text, style: style);
    }
    final total = _perLetter * text.length;
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: text.length),
      duration: total > _cap ? _cap : total,
      builder: (context, shown, _) => Text.rich(
        TextSpan(
          style: style,
          children: [
            TextSpan(text: text.substring(0, shown)),
            TextSpan(
              text: text.substring(shown),
              style: const TextStyle(color: Color(0x00000000)),
            ),
          ],
        ),
      ),
    );
  }
}
