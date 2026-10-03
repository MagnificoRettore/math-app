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
            const SizedBox(height: 24),
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
    final carte = LessonResumeEngine.topicCards(target);
    final progresso = LessonResumeEngine.topicProgress(target);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: AppCard(
        key: const Key('jump-back-in-card'),
        padding: const EdgeInsets.all(18),
        glow: c.accent,
        onTap: () => _open(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: c.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: c.accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        target.isPaused ? 'In corso' : 'Da iniziare',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: c.accent,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Il topic è il titolo grande e la lezione il sottotitolo: è
            // l'argomento che dice dove si sta, la lezione è una delle sue
            // card.
            Text(
              target.argomento.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: c.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              target.lesson.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13.5, color: c.textSecondary),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _progressoTesto(progresso, carte),
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: c.textSecondary,
                    ),
                  ),
                ),
                Text(
                  '${(progresso * 100).round()}%',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: c.accent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ProgressBar(progress: progresso, height: 10),
            const SizedBox(height: 16),
            // Il tappo della card e il bottone fanno la stessa cosa: il bottone
            // dice cosa succede, la card dice che si può anche premere tutto.
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                key: const Key('jump-back-in-button'),
                onPressed: () => _open(context),
                style: FilledButton.styleFrom(
                  backgroundColor: c.accent,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.play_arrow_rounded, size: 22),
                label: const Text(
                  'Riprendi',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Il conteggio è di card, non di esercizi: `LessonResumeEngine` sa dove si
  /// sta, non quanto si è capito. Sul totale la percentuale non aggiunge
  /// niente, quindi sparisce.
  String _progressoTesto(double progresso, ({int passed, int total})? carte) {
    if (carte == null || carte.total == 0) return 'Prima card';
    return '${progresso == 0 ? 0 : carte.passed} di ${carte.total} card';
  }

  void _open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LessonScreen(
          lesson: target.lesson,
          levelId: levelId,
          initialStep: target.step,
        ),
      ),
    );
  }
}
