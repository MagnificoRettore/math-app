import 'package:flutter/material.dart';

import '../data/content_repository.dart';
import '../data/lesson_repository.dart';
import '../data/progress_store.dart';
import '../models/lesson.dart';
import '../theme/app_colors.dart';
import '../widgets/lesson_card.dart';
import '../widgets/pill_nav_bar.dart';
import 'lesson_screen.dart';

class LessonListScreen extends StatelessWidget {
  final String? levelId;
  final bool showPill;

  const LessonListScreen({
    super.key,
    this.levelId,
    this.showPill = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final lessons = _resolvedLessons();
    final level =
        levelId == null ? null : ContentRepository.instance.levelById(levelId!);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          level == null ? 'Lezioni interattive' : 'Lezioni · ${level.title}',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: c.textPrimary,
          ),
        ),
      ),
      bottomNavigationBar: showPill
          ? const PillNavBar(selected: PillTab.lessons)
          : null,
      body: lessons.isEmpty
          ? const _EmptyLessons()
          : ListenableBuilder(
              listenable: ProgressStore.instance,
              builder: (context, _) => ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                children: [
                  for (final lesson in lessons)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: LessonCard(
                        lesson: lesson,
                        completed:
                            ProgressStore.instance.isLessonCompleted(lesson.id),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => LessonScreen(lesson: lesson),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  List<Lesson> _resolvedLessons() {
    final all = LessonRepository.instance.lessons;
    if (levelId == null) return all;
    return all.where((l) => l.levelId == levelId).toList();
  }
}

class _EmptyLessons extends StatelessWidget {
  const _EmptyLessons();

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.menu_book_outlined,
              size: 52,
              color: c.textSecondary,
            ),
            const SizedBox(height: 12),
            Text(
              'Nessuna lezione disponibile',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: c.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Le lezioni guidate per questo livello sono in arrivo.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: c.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}