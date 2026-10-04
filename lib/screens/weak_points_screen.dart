import 'package:flutter/material.dart';

import '../data/auth_store.dart';
import '../data/progress_store.dart';
import '../data/weak_topic_engine.dart';
import '../models/weak_topic.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../widgets/empty_state.dart';
import '../widgets/illustration.dart';
import '../widgets/weak_topic_row.dart';
import 'weak_topic_screen.dart';
import 'welcome_screen.dart';
import '../widgets/app_button.dart';

class WeakPointsScreen extends StatelessWidget {
  const WeakPointsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: ProgressStore.instance,
          builder: (context, _) {
            // «Tutto assimilato» è un merito, e un ospite non ha ancora
            // studiato niente: gli si dice cosa può fare, non che ha finito.
            if (AuthStore.instance.currentUser == null) {
              return const _GuestWeakPoints();
            }
            final weakTopics = WeakTopicEngine.weakTopics();
            if (weakTopics.isEmpty) {
              return EmptyState(
                illustration: AppIllustration.razzo,
                title: 'Tutto assimilato!',
                subtitle: 'Non hai esercizi da ripassare. Ottimo lavoro!',
              );
            }

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
      ),
    );
  }

  void _openWeakTopic(BuildContext context, WeakTopic weak) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => WeakTopicScreen(weakTopic: weak)));
  }
}

/// Lo stato vuoto dell'ospite: non ha ancora esercizi da ripassare, quindi il
/// «Tutto assimilato!» dello stato vuoto gli direbbe una cosa non vera.
class _GuestWeakPoints extends StatelessWidget {
  const _GuestWeakPoints();

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.insights_outlined, size: 52, color: c.accent),
            const SizedBox(height: 12),
            Text(
              'Ancora niente da ripassare',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppText.titleMedium,
                fontWeight: FontWeight.w700,
                color: c.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Crea il tuo profilo e segna i tuoi esercizi: qui vedrai gli '
              'argomenti da rivedere.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: AppText.label, color: c.textSecondary),
            ),
            const SizedBox(height: 20),
            AppButton(
              key: const Key('weak-points-guest-cta'),
              label: 'Crea il tuo profilo',
              onPressed: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const WelcomeScreen())),
            ),
          ],
        ),
      ),
    );
  }
}
