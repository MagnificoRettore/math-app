import 'package:flutter/material.dart';

import '../data/study_store.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';

/// La serie di giorni come la card «Traguardo» del design: arancio con il
/// gradino pieno sotto, i tagliandi bianchi sul bordo sinistro e una striscia
/// chiara a destra. Dentro, su riquadri bianchi perché sull'arancio i colori
/// delle barre non si leggerebbero: la serie, i sette giorni della settimana e
/// gli obiettivi di oggi.
class StreakCard extends StatelessWidget {
  const StreakCard({super.key});

  /// Quanti giorni mostra la fila dei blocchi: una settimana.
  static const int _week = 7;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: StudyStore.instance,
      builder: (context, _) {
        final c = AppColors.of(context);
        final store = StudyStore.instance;
        final allDone = store.allGoalsReached;
        final streak = store.currentStreak;
        final light = Color.lerp(c.orange, Colors.white, 0.45)!;
        final white = BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(10),
        );
        return Container(
          key: const Key('streak-card'),
          decoration: BoxDecoration(
            color: c.orange,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(color: c.orangeDeep, offset: const Offset(0, 6)),
            ],
          ),
          child: Stack(
            children: [
              // La striscia chiara a destra e i tagliandi a sinistra: il
              // biglietto del traguardo.
              Positioned(
                right: 26,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 14,
                  color: Color.lerp(c.orange, Colors.white, 0.2),
                ),
              ),
              Positioned(
                left: 0,
                top: 22,
                bottom: 22,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    for (var i = 0; i < 6; i++)
                      Container(
                        width: 22,
                        height: 8,
                        decoration: BoxDecoration(
                          color: c.surface,
                          borderRadius: const BorderRadius.horizontal(
                            right: Radius.circular(6),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(48, 24, 50, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                      decoration: white,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TRAGUARDO',
                            style: TextStyle(
                              fontSize: AppText.label,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              color: c.medium,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Serie di $streak ${streak == 1 ? 'giorno' : 'giorni'}',
                            style: TextStyle(
                              fontFamily: AppText.headingFont,
                              fontSize: AppText.headline,
                              fontWeight: FontWeight.w600,
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
                    const SizedBox(height: 14),
                    // I giorni della serie nella settimana: indaco quelli
                    // fatti, arancio chiaro quelli che mancano.
                    Semantics(
                      label:
                          '${streak.clamp(0, _week)} giorni su $_week di questa settimana',
                      child: ExcludeSemantics(
                        child: Row(
                          children: [
                            for (var i = 0; i < _week; i++) ...[
                              if (i > 0) const SizedBox(width: 8),
                              Expanded(
                                child: Container(
                                  height: 34,
                                  decoration: BoxDecoration(
                                    color: i < streak ? c.accent : light,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: white,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _GoalBar(
                            label: 'Esercizi',
                            icon: Icons.edit_outlined,
                            value: store.todayExercises,
                            max: StudyStore.exerciseGoal,
                            progress: store.exerciseGoalProgress,
                            color: c.easy,
                          ),
                          const SizedBox(height: 12),
                          _GoalBar(
                            label: 'Tempo',
                            icon: Icons.schedule,
                            value: store.todayMinutes,
                            max: StudyStore.minutesGoal,
                            progress: store.minutesGoalProgress,
                            color: c.accent,
                          ),
                          if (allDone) ...[
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  color: c.easy,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Obiettivi di oggi raggiunti!',
                                    style: TextStyle(
                                      fontSize: AppText.bodySmall,
                                      fontWeight: FontWeight.w800,
                                      color: c.easy,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
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
