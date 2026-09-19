import 'package:flutter/material.dart';

import '../data/lesson_repository.dart';
import '../data/progress_store.dart';
import '../models/course.dart';
import '../models/level.dart';
import '../models/lesson.dart';
import '../models/section.dart';
import '../models/topic.dart';
import '../theme/app_colors.dart';
import '../widgets/lesson_card.dart';
import '../widgets/section_header.dart';
import 'lesson_screen.dart';

class LessonSectionsScreen extends StatelessWidget {
  final Level level;
  final Course course;
  final String title;
  final Topic? topic;

  const LessonSectionsScreen({
    super.key,
    required this.level,
    required this.course,
    required this.title,
    this.topic,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final groups = _groups();
    return Scaffold(
      appBar: AppBar(),
      body: groups.isEmpty
          ? const _EmptySections()
          : ListenableBuilder(
              listenable: ProgressStore.instance,
              builder: (context, _) => ListView(
                padding: const EdgeInsets.only(top: 8, bottom: 40),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 2),
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: c.textPrimary,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
                    child: Text(
                      course.title,
                      style: TextStyle(fontSize: 14, color: c.textSecondary),
                    ),
                  ),
                  for (final group in groups) ...[
                    SectionHeader(group.section.title),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          for (final lesson in group.lessons)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: LessonCard(
                                lesson: lesson,
                                completed: ProgressStore.instance
                                    .isLessonCompleted(lesson.id),
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        LessonScreen(lesson: lesson),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  List<_SectionLessons> _groups() {
    final result = <_SectionLessons>[];
    final recognized = <String>{
      for (final section in course.sections) ...section.topics.map((t) => t.id),
    };
    for (final section in course.sections) {
      final sectionLessons = LessonRepository.instance.lessonsInSection(
        level.id,
        section.id,
      );
      final lessons = topic == null
          ? sectionLessons
                .where((l) => !l.topics.any(recognized.contains))
                .toList()
          : sectionLessons.where((l) => l.topics.contains(topic!.id)).toList();
      if (lessons.isEmpty) continue;
      result.add(_SectionLessons(section: section, lessons: lessons));
    }
    return result;
  }
}

class _SectionLessons {
  final Section section;
  final List<Lesson> lessons;

  const _SectionLessons({required this.section, required this.lessons});
}

class _EmptySections extends StatelessWidget {
  const _EmptySections();

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
              'Nessuna lezione in questa sezione',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: c.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
