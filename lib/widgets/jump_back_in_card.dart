import 'package:flutter/material.dart';

import '../data/auth_store.dart';
import '../data/lesson_repository.dart';
import '../data/progress_store.dart';
import '../models/argomento.dart';
import '../models/lesson.dart';
import '../models/lesson_resume.dart';
import '../screens/lesson_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import 'app_button.dart';
import 'app_card.dart';
import 'progress_bar.dart';
import 'section_header.dart';

/// «Jump Back In»: da dove riprendere, subito dopo la serie.
///
/// C'è **sempre**, e quando non ha niente da proporre lo dice: all'ospite che
/// il punto di ripresa si tiene con un profilo, a chi ha un profilo ma nessuna
/// lezione aperta che non c'è ancora niente da riprendere. Si ascolta da sé
/// (in Home è `const`).
class JumpBackInCard extends StatelessWidget {
  const JumpBackInCard({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        AuthStore.instance,
        ProgressStore.instance,
      ]),
      builder: (context, _) {
        final user = AuthStore.instance.currentUser;
        final target = user == null ? null : _target();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SectionHeader('Jump Back In', top: 12),
            if (user == null)
              const _Message(
                key: Key('jump-back-in-guest'),
                title: 'Accedi per riprendere',
                body:
                    'Con un profilo ritrovi qui l\'ultima lezione lasciata a '
                    'metà, esattamente da dove eri rimasto.',
              )
            else if (target == null)
              const _Message(
                key: Key('jump-back-in-empty'),
                title: 'Niente da riprendere',
                body:
                    'Nessuna lezione in corso: aprine una e la ritrovi qui '
                    'se la lasci a metà.',
              )
            else
              _Resume(target: target),
          ],
        );
      },
    );
  }

  /// La lezione lasciata a metà, se esiste ancora nei contenuti.
  static _Target? _target() {
    final resume = ProgressStore.instance.lessonResume;
    if (resume == null) return null;
    for (final argomento in LessonRepository.instance.argomenti) {
      if (argomento.levelId != resume.levelId) continue;
      for (final lesson in argomento.lessons) {
        if (lesson.id == resume.lessonId) {
          return _Target(argomento, lesson, resume);
        }
      }
    }
    return null;
  }
}

class _Target {
  final Argomento argomento;
  final Lesson lesson;
  final LessonResume resume;

  const _Target(this.argomento, this.lesson, this.resume);
}

/// La card senza niente da riprendere: dice perché.
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

/// La lezione da riprendere, con il punto in cui ci si era fermati.
class _Resume extends StatelessWidget {
  final _Target target;

  const _Resume({required this.target});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final total = target.lesson.steps.length;
    final step = target.resume.step.clamp(0, total == 0 ? 0 : total - 1);
    final progress = total == 0 ? 0.0 : step / total;

    return AppCard(
      key: const Key('jump-back-in-card'),
      padding: const EdgeInsets.all(20),
      onTap: () => _open(context, step),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            target.argomento.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: AppText.headingFont,
              fontSize: AppText.headline,
              fontWeight: FontWeight.w600,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            target.lesson.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: AppText.bodySmall,
              color: c.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Card ${step + 1} di $total',
            style: TextStyle(
              fontSize: AppText.labelSmall,
              fontWeight: FontWeight.w500,
              color: c.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          ProgressBar(progress: progress, height: 10),
          const SizedBox(height: 16),
          AppButton(
            key: const Key('jump-back-in-button'),
            label: 'Riprendi',
            icon: Icons.play_arrow_rounded,
            expand: true,
            onPressed: () => _open(context, step),
          ),
        ],
      ),
    );
  }

  void _open(BuildContext context, int step) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LessonScreen(
          lesson: target.lesson,
          levelId: target.resume.levelId,
          initialStep: step,
        ),
      ),
    );
  }
}
