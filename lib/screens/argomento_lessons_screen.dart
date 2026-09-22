import 'package:flutter/material.dart';

import '../models/argomento.dart';
import '../models/lesson.dart';
import '../data/progress_store.dart';
import '../screens/lesson_screen.dart';
import '../theme/app_colors.dart';
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, color: c.textSecondary),
                  ),
                ),
              ),
      ),
      body: lessons.isEmpty
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
                        number: i + 1,
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
    );
  }
}

class _LessonCard extends StatelessWidget {
  final Lesson lesson;
  final int number;
  final Color color;
  final bool completed;
  final VoidCallback onTap;

  const _LessonCard({
    required this.lesson,
    required this.number,
    required this.color,
    required this.completed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              '$number',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lesson.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: c.textPrimary,
                  ),
                ),
                if (lesson.subtitle.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    lesson.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, color: c.textSecondary),
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
                        style: TextStyle(fontSize: 12, color: c.textSecondary),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (completed)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: c.easy.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, size: 14, color: c.easy),
                  const SizedBox(width: 4),
                  Text(
                    'Completata',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: c.easy,
                    ),
                  ),
                ],
              ),
            )
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
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: c.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: c.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
