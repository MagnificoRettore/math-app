import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'app_card.dart';

class MissionHero extends StatelessWidget {
  final VoidCallback? onTap;

  const MissionHero({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: c.accentSoft,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.auto_stories_outlined,
              color: c.accent,
              size: 28,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'La nostra missione',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Crediamo che la matematica non debba essere un ostacolo: '
            'è un linguaggio che insegna a ragionare. La nostra missione è '
            'aiutare ogni studente a imparare con fiducia, offrendo esercizi '
            'risolti passo-passo, spiegazioni chiare e un percorso di studio '
            'che cresce insieme ai suoi progressi.',
            style: TextStyle(
              fontSize: 15,
              height: 1.5,
              color: c.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}