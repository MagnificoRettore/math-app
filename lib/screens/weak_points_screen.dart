import 'package:flutter/material.dart';

import '../data/progress_store.dart';
import '../data/weak_topic_engine.dart';
import '../models/weak_topic.dart';
import '../theme/app_colors.dart';
import '../widgets/weak_topic_row.dart';
import 'weak_topic_screen.dart';

class WeakPointsScreen extends StatelessWidget {
  const WeakPointsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: ListenableBuilder(
        listenable: ProgressStore.instance,
        builder: (context, _) {
          final weakTopics = WeakTopicEngine.weakTopics();
          if (weakTopics.isEmpty) return const _AllResolved();

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              for (final weak in weakTopics)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: WeakTopicRow(
                    weakTopic: weak,
                    onTap: () => _openWeakTopic(context, weak),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  void _openWeakTopic(BuildContext context, WeakTopic weak) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => WeakTopicScreen(weakTopic: weak)));
  }
}

class _AllResolved extends StatelessWidget {
  const _AllResolved();

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.task_alt, size: 52, color: c.easy),
            const SizedBox(height: 12),
            Text(
              'Tutto assimilato!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: c.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Non hai esercizi da ripassare. Ottimo lavoro!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: c.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
