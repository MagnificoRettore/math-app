import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import 'app_card.dart';
import 'progress_bar.dart';

/// «Riprendi da dove eri rimasto», in cima a Lezioni ed Esercizi: dove ci si
/// era fermati, la barra e a che punto si è.
class ResumeCard extends StatelessWidget {
  final String title;
  final String caption;
  final double progress;
  final VoidCallback onTap;

  const ResumeCard({
    super.key,
    required this.title,
    required this.caption,
    required this.progress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return AppCard(
      key: const Key('resume-card'),
      onTap: onTap,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Riprendi da dove eri rimasto',
            style: TextStyle(
              fontSize: AppText.label,
              fontWeight: FontWeight.w500,
              color: c.accent,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: AppText.headingFont,
              fontSize: AppText.titleLarge,
              fontWeight: FontWeight.w600,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ProgressBar(progress: progress, height: 10),
          const SizedBox(height: 8),
          Text(
            caption,
            style: TextStyle(
              fontSize: AppText.labelSmall,
              fontWeight: FontWeight.w500,
              color: c.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
