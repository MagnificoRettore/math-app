import 'package:flutter/material.dart';

import '../data/math_facts.dart';
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

  void _next() => setState(() => _index = (_index + 1) % mathFacts.length);

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
          AnimatedSwitcher(
            duration: AppMotion.duration(context, AppMotion.medium),
            switchInCurve: AppMotion.standard,
            child: Text(
              mathFacts[_index],
              key: ValueKey(_index),
              style: TextStyle(
                fontSize: AppText.bodyLarge,
                height: 1.5,
                color: c.textSecondary,
              ),
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
