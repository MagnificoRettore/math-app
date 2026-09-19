import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/app_card.dart';
import '../widgets/mission_hero.dart';

class MissionScreen extends StatelessWidget {
  const MissionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          const MissionHero(),
          const SizedBox(height: 24),
          Text(
            'Cosa facciamo',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _FeatureCard(
            icon: Icons.menu_book_outlined,
            title: 'Esercizi risolti passo-passo',
            color: c.accent,
            description:
                'Ogni esercizio è spiegato con passaggi chiari e ragionati, '
                'per capire non solo "come" si risolve, ma soprattutto "perché".',
          ),
          const SizedBox(height: 12),
          _FeatureCard(
            icon: Icons.calculate_outlined,
            title: 'Formule in LaTeX',
            color: c.purple,
            description:
                'Le notazioni matematiche sono renderizzate con cura, '
                'così ogni formula è sempre leggibile e precisa.',
          ),
          const SizedBox(height: 12),
          _FeatureCard(
            icon: Icons.trending_up,
            title: 'Progressi personalizzati',
            color: c.teal,
            description:
                'Tieni traccia di ciò che hai imparato e di ciò che va ripassato, '
                'con un percorso di studio su misura per te.',
          ),
          const SizedBox(height: 12),
          _FeatureCard(
            icon: Icons.offline_pin_outlined,
            title: 'Contenuti offline',
            color: c.pink,
            description:
                'Tutti gli esercizi sono sempre disponibili, anche senza connessione, '
                'dalla scuola superiore all\'università.',
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color? color;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final effectiveColor = color ?? c.accent;
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: effectiveColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: effectiveColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: c.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    color: c.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
