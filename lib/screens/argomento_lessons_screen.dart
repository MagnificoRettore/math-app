import 'package:flutter/material.dart';

import '../models/argomento.dart';
import '../models/lesson.dart';
import '../data/progress_store.dart';
import '../screens/lesson_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../theme/topic_style.dart';
import '../widgets/app_card.dart';

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
    final lessons = argomento.lessons;

    return Scaffold(
      appBar: AppBar(
        title: Text(argomento.title),
        bottom: argomento.subtitle.isEmpty
            ? null
            : PreferredSize(
                preferredSize: const Size.fromHeight(28),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: Text(
                    argomento.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: AppText.label,
                      color: c.textSecondary,
                    ),
                  ),
                ),
              ),
      ),
      body: SafeArea(
        child: lessons.isEmpty
            ? _EmptyArgomento(
                title: 'Nessuna lezione in ${argomento.title}',
                subtitle:
                    'Le lezioni guidate per questo capitolo sono in arrivo.',
              )
            : ListenableBuilder(
                listenable: ProgressStore.instance,
                builder: (context, _) => ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
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
              ),
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

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      borderColor: color.withValues(alpha: 0.25),
      glow: color.withValues(alpha: 0.10),
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
                    fontWeight: FontWeight.w700,
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
          if (completed)
            Icon(Icons.check_circle_rounded, size: 22, color: c.easy)
          else
            Icon(Icons.chevron_right, color: c.textSecondary),
        ],
      ),
    );
  }
}

class _EmptyArgomento extends StatelessWidget {
  final String title;
  final String subtitle;

  const _EmptyArgomento({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.menu_book_outlined, size: 52, color: c.textSecondary),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppText.titleMedium,
                fontWeight: FontWeight.w600,
                color: c.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: AppText.label, color: c.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
