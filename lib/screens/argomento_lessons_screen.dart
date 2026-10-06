import 'package:flutter/material.dart';

import '../data/content_repository.dart';
import '../models/argomento.dart';
import '../models/course.dart';
import '../models/level.dart';
import '../models/topic.dart';
import '../models/lesson.dart';
import '../data/progress_store.dart';
import '../data/shell_navigator.dart';
import '../screens/exercise_feed_screen.dart';
import '../screens/lesson_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../theme/topic_style.dart';
import '../widgets/app_button.dart';
import '../widgets/app_card.dart';
import '../widgets/completed_badge.dart';
import '../widgets/empty_state.dart';
import '../widgets/main_header.dart';
import '../widgets/pill_nav_bar.dart';

/// Elenco delle lezioni di un argomento (capitolo).
/// Passo intermedio fra il livello anno e il player a passi [LessonScreen].
class ArgomentoLessonsScreen extends StatelessWidget {
  final Argomento argomento;
  final String? levelId;

  const ArgomentoLessonsScreen({
    super.key,
    required this.argomento,
    this.levelId,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final color = topicColor(c, argomento.icon);
    final exercises = _exercises();

    return Scaffold(
      appBar: MainHeaderAppBar(
        showBack: true,
        title: MainHeaderTitle(levelId: argomento.levelId),
        actions: const [HeaderSearchButton(), HeaderCustomizationButton()],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Heading(argomento: argomento),
                Expanded(child: _body(context, color, exercises != null)),
              ],
            ),
            if (exercises != null)
              Positioned(
                right: 20,
                bottom: 16,
                child: AppButton(
                  key: const Key('vai-agli-esercizi'),
                  label: 'Vai agli esercizi',
                  icon: Icons.fitness_center_rounded,
                  onPressed: () => _openExercises(context, exercises),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Gli esercizi dello stesso argomento (stesso anno, stesso topic), se ci
  /// sono: senza, il pulsante prometterebbe una pagina vuota.
  ({Level level, Course course, Topic topic})? _exercises() {
    final level = ContentRepository.instance.levelById(argomento.levelId);
    if (level == null) return null;
    for (final course in level.courses) {
      if (course.id != argomento.yearId) continue;
      for (final topic in course.topics) {
        if (topic.id == argomento.topicId && topic.exercises.isNotEmpty) {
          return (level: level, course: course, topic: topic);
        }
      }
    }
    return null;
  }

  /// Porta alla sezione Esercizi, sull'anno dell'argomento, e apre gli esercizi
  /// del suo topic: da lì il back torna all'elenco dell'anno. La Home resta la
  /// radice: si torna a lei e le si chiede di mostrare Esercizi.
  void _openExercises(
    BuildContext context,
    ({Level level, Course course, Topic topic}) target,
  ) {
    final navigator = Navigator.of(context);
    navigator.popUntil((route) => route.isFirst);
    ShellNavigator.instance.show(
      PillTab.exercises,
      levelId: target.level.id,
      courseId: target.course.id,
    );
    navigator.push<void>(
      MaterialPageRoute(
        builder: (_) => ExerciseFeedScreen(
          level: target.level,
          course: target.course,
          topic: target.topic,
        ),
      ),
    );
  }

  Widget _body(BuildContext context, Color color, bool hasExercises) {
    final lessons = argomento.lessons;
    return lessons.isEmpty
        ? EmptyState(
            title: 'Nessuna lezione in ${argomento.title}',
            subtitle: 'Le lezioni guidate per questo capitolo sono in arrivo.',
          )
        : ListenableBuilder(
            listenable: ProgressStore.instance,
            builder: (context, _) => ListView(
              // Col pulsante «Vai agli esercizi» sotto, la lista scorre oltre.
              padding: EdgeInsets.fromLTRB(20, 8, 20, hasExercises ? 88 : 24),
              children: [
                for (var i = 0; i < lessons.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _LessonCard(
                      lesson: lessons[i],
                      color: color,
                      completed: ProgressStore.instance.isLessonCompleted(
                        argomento.levelId,
                        lessons[i].id,
                      ),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => LessonScreen(
                              lesson: lessons[i],
                              levelId: levelId ?? argomento.levelId,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          );
  }
}

/// Titolo e sottotitolo dell'argomento in testa alla pagina: nella banda c'è
/// l'identità, quindi il nome della pagina scende nel corpo.
class _Heading extends StatelessWidget {
  final Argomento argomento;

  const _Heading({required this.argomento});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            argomento.title,
            style: TextStyle(
              fontFamily: AppText.headingFont,
              fontSize: AppText.headline,
              fontWeight: FontWeight.w600,
              color: c.textPrimary,
            ),
          ),
          if (argomento.subtitle.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              argomento.subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: AppText.label, color: c.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}

class _LessonCard extends StatelessWidget {
  final Lesson lesson;
  final Color color;
  final bool completed;
  final VoidCallback onTap;

  const _LessonCard({
    required this.lesson,
    required this.color,
    required this.completed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    final card = AppCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      borderColor: color.withValues(alpha: 0.25),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lesson.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: AppText.titleSmall,
                    fontWeight: FontWeight.w500,
                    color: c.textPrimary,
                  ),
                ),
                if (lesson.subtitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    lesson.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: AppText.label,
                      color: c.textSecondary,
                    ),
                  ),
                ],
                if (lesson.minutes > 0) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.schedule, size: 14, color: c.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        lesson.minutes == 1 ? '1 min' : '${lesson.minutes} min',
                        style: TextStyle(
                          fontSize: AppText.caption,
                          color: c.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.chevron_right, color: c.textSecondary),
        ],
      ),
    );
    if (!completed) return card;
    // Il segno «completata» nell'angolo in alto a destra, sopra la card.
    return Stack(children: [card, CompletedBadge.corner()]);
  }
}
