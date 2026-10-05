import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import 'app_card.dart';
import 'math_text.dart';

/// Un passaggio della soluzione: il numero in un tondino e il testo accanto.
class ExerciseStepCard extends StatelessWidget {
  final int number;
  final String text;

  const ExerciseStepCard({super.key, required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: c.accentSoft,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$number',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: AppText.label,
                color: c.accent,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: MathText(
              text,
              fontSize: AppText.bodyLarge,
              textAlign: TextAlign.left,
            ),
          ),
        ],
      ),
    );
  }
}
