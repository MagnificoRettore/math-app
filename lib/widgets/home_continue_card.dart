import 'package:flutter/material.dart';

import '../data/auth_store.dart';
import '../data/lesson_repository.dart';
import '../data/progress_store.dart';
import '../data/resume_target.dart';
import '../models/argomento.dart';
import '../models/lesson.dart';
import '../screens/lesson_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import 'app_card.dart';
import 'progress_bar.dart';

/// «Continua»: la card grande in cima alla Home.
///
/// Riprende l'ultima lezione lasciata a metà, con la barra e la percentuale. Se
/// non ce n'è, propone la prossima lezione non ancora fatta della scuola del
/// profilo; se non c'è nemmeno quella dice perché (nessun profilo, o tutto
/// fatto). C'è sempre: la Home non cambia disegno da un utente all'altro.
/// Si ascolta da sé (in Home è `const`).
class HomeContinueCard extends StatelessWidget {
  const HomeContinueCard({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        AuthStore.instance,
        ProgressStore.instance,
      ]),
      builder: (context, _) {
        final resume = ResumeTarget.find();
        if (resume != null) {
          return _Big(
            key: const Key('continue-card'),
            label: 'Continua',
            title: '${resume.argomento.title} · ${resume.lesson.title}',
            progress: resume.progress,
            onTap: () => _open(
              context,
              resume.lesson,
              resume.resume.levelId,
              resume.step,
            ),
          );
        }
        final next = _next();
        if (next != null) {
          return _Big(
            key: const Key('continue-next'),
            label: 'Inizia',
            title: '${next.$1.title} · ${next.$2.title}',
            progress: 0,
            onTap: () => _open(context, next.$2, next.$1.levelId, 0),
          );
        }
        final signedIn = AuthStore.instance.currentUser != null;
        return _Message(
          key: Key(signedIn ? 'continue-done' : 'continue-guest'),
          title: signedIn
              ? 'Hai finito tutte le lezioni'
              : 'Accedi per continuare',
          body: signedIn
              ? 'Ripassa con gli esercizi: ce n\'è sempre uno nuovo.'
              : 'Con un profilo ritrovi qui l\'ultima lezione, esattamente da '
                    'dove eri rimasto.',
        );
      },
    );
  }

  /// La prima lezione non completata della scuola del profilo, nell'ordine dei
  /// contenuti.
  static (Argomento, Lesson)? _next() {
    final levelId = AuthStore.instance.currentUser?.schoolLevelId ?? '';
    if (levelId.isEmpty) return null;
    for (final argomento in LessonRepository.instance.argomenti) {
      if (argomento.levelId != levelId) continue;
      for (final lesson in argomento.lessons) {
        if (!ProgressStore.instance.isLessonCompleted(levelId, lesson.id)) {
          return (argomento, lesson);
        }
      }
    }
    return null;
  }

  static void _open(
    BuildContext context,
    Lesson lesson,
    String levelId,
    int step,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            LessonScreen(lesson: lesson, levelId: levelId, initialStep: step),
      ),
    );
  }
}

class _Big extends StatelessWidget {
  final String label;
  final String title;
  final double progress;
  final VoidCallback onTap;

  const _Big({
    super.key,
    required this.label,
    required this.title,
    required this.progress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final percent = (progress * 100).round();
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: c.accent,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  size: 28,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  fontFamily: AppText.headingFont,
                  fontSize: AppText.headline,
                  fontWeight: FontWeight.w600,
                  color: c.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: AppText.titleMedium,
              fontWeight: FontWeight.w500,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: ProgressBar(progress: progress, height: 10)),
              const SizedBox(width: 12),
              Text(
                '$percent%',
                key: const Key('continue-percent'),
                style: TextStyle(
                  fontSize: AppText.label,
                  fontWeight: FontWeight.w500,
                  color: c.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// La card senza niente da riprendere né da iniziare: dice perché.
class _Message extends StatelessWidget {
  final String title;
  final String body;

  const _Message({super.key, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: c.accentSoft,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.history_rounded, color: c.accent),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: AppText.headingFont,
                    fontSize: AppText.titleMedium,
                    fontWeight: FontWeight.w600,
                    color: c.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: TextStyle(
                    fontSize: AppText.bodySmall,
                    height: 1.4,
                    color: c.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
