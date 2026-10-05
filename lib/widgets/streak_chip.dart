import 'package:flutter/material.dart';

import '../data/study_store.dart';
import '../haptics.dart';
import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import '../theme/app_text.dart';

/// La serie di giorni nell'header, a sinistra dell'ingranaggio: una fiamma e il
/// numero, senza altro testo.
///
/// La fiamma è arancio se oggi si è già fatto qualcosa, grigia se no: un
/// promemoria silenzioso. Il tocco apre il foglio con la settimana e il record.
/// Si ascolta da sé, come le altre sezioni che leggono `StudyStore`.
class HeaderStreakChip extends StatelessWidget {
  const HeaderStreakChip({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: StudyStore.instance,
      builder: (context, _) {
        final c = AppColors.of(context);
        final store = StudyStore.instance;
        final streak = store.liveStreak;
        final active = store.activeToday;
        final flame = active
            ? c.orange
            : c.textSecondary.withValues(alpha: 0.6);
        return Semantics(
          button: true,
          excludeSemantics: true,
          label:
              'Serie di $streak ${streak == 1 ? 'giorno' : 'giorni'}'
              '${active ? ', fatto oggi' : ', oggi non ancora'}',
          onTap: () => showStreakSheet(context),
          child: GestureDetector(
            key: const Key('header-streak'),
            behavior: HitTestBehavior.opaque,
            onTap: () => showStreakSheet(context),
            // Il bersaglio è alto 48 anche se la pillola è più bassa.
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              child: Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: c.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: active ? c.orange : c.border,
                    width: 2,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.local_fire_department_rounded,
                      key: const Key('streak-flame'),
                      size: 20,
                      color: flame,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '$streak',
                      style: TextStyle(
                        fontFamily: AppText.headingFont,
                        fontSize: AppText.titleSmall,
                        fontWeight: FontWeight.w600,
                        color: active ? c.textPrimary : c.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Il foglio della serie: i giorni della settimana (lunedì–domenica), con
/// quelli della serie colorati e oggi cerchiato, e il record.
Future<void> showStreakSheet(BuildContext context) {
  AppHaptics.selectionClick();
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    sheetAnimationStyle: AnimationStyle(
      duration: AppMotion.slow,
      reverseDuration: AppMotion.medium,
      curve: AppMotion.standard,
    ),
    builder: (_) => const _StreakSheet(),
  );
}

class _StreakSheet extends StatelessWidget {
  const _StreakSheet();

  static const _letters = ['L', 'M', 'M', 'G', 'V', 'S', 'D'];

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return ListenableBuilder(
      listenable: StudyStore.instance,
      builder: (context, _) {
        final store = StudyStore.instance;
        final streak = store.liveStreak;
        final now = store.today;
        final monday = DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(Duration(days: now.weekday - DateTime.monday));
        return SafeArea(
          child: Container(
            key: const Key('streak-sheet'),
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            decoration: BoxDecoration(
              color: c.background,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              border: Border(
                top: BorderSide(color: c.border, width: 3),
                left: BorderSide(color: c.border, width: 3),
                right: BorderSide(color: c.border, width: 3),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: c.border,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(
                      Icons.local_fire_department_rounded,
                      size: 36,
                      color: store.activeToday
                          ? c.orange
                          : c.textSecondary.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                            store.activeToday
                                ? 'Oggi hai già studiato.'
                                : 'Oggi non hai ancora studiato.',
                            style: TextStyle(
                              fontSize: AppText.bodySmall,
                              color: c.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    for (var i = 0; i < 7; i++)
                      Expanded(
                        child: _Day(
                          letter: _letters[i],
                          done: store.inStreak(monday.add(Duration(days: i))),
                          today: i == now.weekday - DateTime.monday,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  'Record: ${store.bestStreak} ${store.bestStreak == 1 ? 'giorno' : 'giorni'}',
                  key: const Key('streak-record'),
                  style: TextStyle(
                    fontSize: AppText.bodyMedium,
                    fontWeight: FontWeight.w500,
                    color: c.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Un giorno della settimana: tondo arancio con la fiamma se è della serie,
/// bianco col bordo lilla altrimenti; oggi ha il bordo indaco.
class _Day extends StatelessWidget {
  final String letter;
  final bool done;
  final bool today;

  const _Day({required this.letter, required this.done, required this.today});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Column(
      children: [
        Container(
          key: done ? const Key('streak-day-done') : null,
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: done ? c.orange : c.surface,
            shape: BoxShape.circle,
            border: Border.all(
              color: today ? c.accent : (done ? c.orange : c.border),
              width: today ? 3 : 2,
            ),
          ),
          child: done
              ? Icon(
                  Icons.local_fire_department_rounded,
                  size: 20,
                  color: c.surface,
                )
              : null,
        ),
        const SizedBox(height: 6),
        Text(
          letter,
          style: TextStyle(
            fontSize: AppText.label,
            fontWeight: FontWeight.w500,
            color: today ? c.textPrimary : c.textSecondary,
          ),
        ),
      ],
    );
  }
}
