import 'package:flutter/material.dart';

import '../data/auth_store.dart';
import '../data/lesson_resume_engine.dart';
import '../data/progress_store.dart';
import '../models/lesson_target.dart';
import '../screens/lesson_screen.dart';
import '../theme/app_colors.dart';
import 'app_card.dart';
import 'progress_bar.dart';
import 'section_header.dart';

/// Prima sezione della home: da dove riprendere.
///
/// Non esiste per gli ospiti e non esiste finché l'utente non ha aperto una
/// lezione almeno una volta: senza quel punto di ripresa non c'è niente di
/// onesto da proporre, e una lezione scelta a caso sarebbe solo rumore.
class JumpBackInSection extends StatelessWidget {
  const JumpBackInSection({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ProgressStore.instance,
      builder: (context, _) {
        final user = AuthStore.instance.currentUser;
        if (user == null) return const SizedBox.shrink();

        final levelId = user.schoolLevelId;
        final target = LessonResumeEngine.target(levelId: levelId);
        if (target == null) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SectionHeader('Jump Back In'),
            _JumpBackInCard(levelId: levelId, target: target),
            // Lo stacco è qui dentro e non nella lista: quando la sezione non
            // esiste non deve restare un buco davanti al carousel.
            const SizedBox(height: 20),
          ],
        );
      },
    );
  }
}

class _JumpBackInCard extends StatelessWidget {
  final String levelId;
  final LessonTarget target;

  const _JumpBackInCard({required this.levelId, required this.target});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: AppCard(
        key: const Key('jump-back-in-card'),
        padding: const EdgeInsets.all(16),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => LessonScreen(
              lesson: target.lesson,
              levelId: levelId,
              initialStep: target.step,
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: c.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.play_arrow_rounded, color: c.accent, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Il topic è il titolo grande e la lezione il sottotitolo:
                  // è l'argomento che dice dove si sta, la lezione è una delle
                  // sue card.
                  Text(
                    target.argomento.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: c.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    target.lesson.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, color: c.textSecondary),
                  ),
                  const SizedBox(height: 10),
                  ProgressBar(
                    progress: LessonResumeEngine.topicProgress(target),
                    height: 8,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
