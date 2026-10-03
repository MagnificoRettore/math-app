import 'package:flutter/material.dart';

import '../data/study_store.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import 'app_card.dart';

class StreakCard extends StatelessWidget {
  const StreakCard({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: StudyStore.instance,
      builder: (context, _) {
        final c = AppColors.of(context);
        final store = StudyStore.instance;
        final allDone = store.allGoalsReached;
        return AppCard(
          padding: const EdgeInsets.all(18),
          // La serie è l'unica sezione con il bordo colorato: è quella che si
          // guarda per capire se conviene aprire l'app oggi.
          borderColor: c.accent.withValues(alpha: 0.35),
          glow: c.medium,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: c.medium.withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.local_fire_department,
                      color: c.medium,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Serie di ${store.currentStreak} ${store.currentStreak == 1 ? 'giorno' : 'giorni'}',
                          style: TextStyle(
                            fontSize: AppText.titleSmall,
                            fontWeight: FontWeight.w700,
                            color: c.textPrimary,
                          ),
                        ),
                        Text(
                          'Record personale: ${store.bestStreak}',
                          style: TextStyle(
                            fontSize: AppText.label,
                            color: c.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.emoji_events_outlined, color: c.medium, size: 22),
                ],
              ),
              const SizedBox(height: 16),
              _GoalBar(
                label: 'Esercizi',
                icon: Icons.edit_outlined,
                value: store.todayExercises,
                max: StudyStore.exerciseGoal,
                progress: store.exerciseGoalProgress,
                color: c.easy,
              ),
              const SizedBox(height: 14),
              _GoalBar(
                label: 'Tempo',
                icon: Icons.schedule,
                value: store.todayMinutes,
                max: StudyStore.minutesGoal,
                progress: store.minutesGoalProgress,
                color: c.accent,
              ),
              if (allDone) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: c.easy.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: c.easy, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Obiettivi di oggi raggiunti!',
                          style: TextStyle(
                            fontSize: AppText.bodySmall,
                            fontWeight: FontWeight.w700,
                            color: c.easy,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _GoalBar extends StatelessWidget {
  final String label;
  final IconData icon;
  final int value;
  final int max;
  final double progress;
  final Color color;

  const _GoalBar({
    required this.label,
    required this.icon,
    required this.value,
    required this.max,
    required this.progress,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: color.withValues(alpha: 0.14),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ),
        const SizedBox(width: 10),
        // La spunta arriva quando l'obiettivo è chiuso: è l'unico segnale che
        // distingue «sto andando bene» da «ho finito».
        if (value >= max) ...[
          Icon(Icons.check_circle, color: color, size: 15),
          const SizedBox(width: 5),
        ],
        Text(
          '$value/$max',
          style: TextStyle(
            fontSize: AppText.label,
            fontWeight: FontWeight.w600,
            color: c.textSecondary,
          ),
        ),
      ],
    );
  }
}
