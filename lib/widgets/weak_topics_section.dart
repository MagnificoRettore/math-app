import 'package:flutter/material.dart';

import '../data/progress_store.dart';
import '../data/weak_topic_engine.dart';
import '../models/weak_topic.dart';
import '../screens/weak_points_screen.dart';
import '../screens/weak_topic_screen.dart';
import '../theme/app_colors.dart';
import 'section_header.dart';
import 'weak_topic_row.dart';

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
              trailing: Text(
                total == 1 ? '1 da ripassare' : '$total da ripassare',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: c.medium,
                ),
              ),
            ),
            for (final weak in preview)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: WeakTopicRow(
                  weakTopic: weak,
                  onTap: () => _openWeakTopic(context, weak),
                ),
              ),
            if (hasMore)
              Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const WeakPointsScreen()),
                  ),
                  child: Text(
                    'Vedi tutti (${weakTopics.length})',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: c.accent,
                    ),
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
