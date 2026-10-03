import 'package:flutter/material.dart';

import '../data/progress_store.dart';
import '../data/weak_topic_engine.dart';
import '../models/weak_topic.dart';
import '../screens/weak_points_screen.dart';
import '../screens/weak_topic_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import 'app_card.dart';
import 'section_header.dart';
import 'weak_topic_row.dart';

/// «I tuoi punti deboli»: gli argomenti da ripassare, in ordine.
///
/// Le righe stanno in una card sola e non in una card ciascuna: sono la stessa
/// lista, e tre superfici bianche separate sembrerebbero tre cose diverse.
/// Il contatore della testata e il bottone in fondo dicono quanti sono in tutto
/// quando qui ne compaiono tre.
class WeakTopicsSection extends StatelessWidget {
  const WeakTopicsSection({super.key});

  static const _maxRows = 3;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ProgressStore.instance,
      builder: (context, _) {
        final weakTopics = WeakTopicEngine.weakTopics();
        if (weakTopics.isEmpty) return const SizedBox.shrink();

        final c = AppColors.of(context);
        final total = weakTopics.fold<int>(
          0,
          (sum, w) => sum + w.needsReviewCount,
        );
        final preview = weakTopics.take(_maxRows).toList();
        final hasMore = weakTopics.length > _maxRows;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionHeader(
              'I tuoi punti deboli',
              trailing: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: c.danger.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  total == 1 ? '1 da ripassare' : '$total da ripassare',
                  style: TextStyle(
                    fontSize: AppText.labelSmall,
                    fontWeight: FontWeight.w700,
                    color: c.danger,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: AppCard(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < preview.length; i++) ...[
                      if (i > 0) const Divider(height: 1, indent: 68),
                      WeakTopicRow(
                        weakTopic: preview[i],
                        rank: i + 1,
                        onTap: () => _openWeakTopic(context, preview[i]),
                      ),
                    ],
                    if (hasMore)
                      Padding(
                        padding: const EdgeInsets.only(top: 4, bottom: 4),
                        child: TextButton(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const WeakPointsScreen(),
                            ),
                          ),
                          child: Text(
                            'Vedi tutti (${weakTopics.length})',
                            style: TextStyle(
                              fontSize: AppText.bodySmall,
                              fontWeight: FontWeight.w700,
                              color: c.accent,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _openWeakTopic(BuildContext context, WeakTopic weak) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => WeakTopicScreen(weakTopic: weak)));
  }
}
