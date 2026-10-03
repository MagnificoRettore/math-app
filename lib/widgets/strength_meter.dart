import 'package:flutter/material.dart';

import '../data/auth_validators.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';

/// Quattro segmenti che dicono quanto è robusta la password appena scritta.
///
/// Il colore segue il punteggio di [AuthValidators.passwordScore]; senza
/// password il metro resta spento, non grigio di «mancante».
class StrengthMeter extends StatelessWidget {
  final String password;

  const StrengthMeter({super.key, required this.password});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final score = password.isEmpty ? 0 : AuthValidators.passwordScore(password);
    final label = AuthValidators.passwordLabel(password);
    final color = switch (score) {
      <= 1 => c.hard,
      2 => c.medium,
      3 => c.easy,
      _ => c.teal,
    };

    return Row(
      children: [
        for (var i = 0; i < 4; i++) ...[
          if (i > 0) const SizedBox(width: 4),
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              height: 4,
              decoration: BoxDecoration(
                color: password.isEmpty || i >= score ? c.border : color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
        const SizedBox(width: 10),
        SizedBox(
          width: 74,
          child: Text(
            label ?? '',
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: AppText.caption,
              fontWeight: FontWeight.w600,
              color: password.isEmpty ? c.textSecondary : color,
            ),
          ),
        ),
      ],
    );
  }
}
