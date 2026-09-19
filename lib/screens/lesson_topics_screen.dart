import 'package:flutter/material.dart';

import '../data/lesson_repository.dart';
import '../models/course.dart';
import '../models/level.dart';
import '../models/lesson.dart';
import '../models/topic.dart';
import '../theme/app_colors.dart';
import '../theme/topic_style.dart';
import '../widgets/topic_image_card.dart';

class LessonTopicsList extends StatelessWidget {
  final Level level;
  final Course course;
  final void Function(String title, Topic? topic) onSelectArgument;

  const LessonTopicsList({
    super.key,
    required this.level,
    required this.course,
    required this.onSelectArgument,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final argomenti = _argomenti();
    if (argomenti.isEmpty) return _EmptyLessons(courseTitle: course.title);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 4),
          child: Text(
            course.title,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: c.textPrimary,
            ),
          ),
        ),
        if (course.subtitle.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              course.subtitle,
              style: TextStyle(fontSize: 14, color: c.textSecondary),
            ),
          ),
        for (final argomento in argomenti)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _ArgomentoRow(
              argomento: argomento,
              onTap: () => onSelectArgument(argomento.title, argomento.topic),
            ),
          ),
      ],
    );
  }

  List<_Argomento> _argomenti() {
    final result = <_Argomento>[];
    final covered = <String>{};
    for (final section in course.sections) {
      final sectionLessons = LessonRepository.instance.lessonsInSection(
        level.id,
        section.id,
      );
      for (final topic in section.topics) {
        final lessons = sectionLessons
            .where((l) => l.topics.contains(topic.id))
            .toList();
        if (lessons.isEmpty) continue;
        covered.addAll(lessons.map((l) => l.id));
        result.add(
          _Argomento(title: topic.title, topic: topic, lessons: lessons),
        );
      }
    }
    final leftovers = [
      for (final section in course.sections)
        ...LessonRepository.instance.lessonsInSection(level.id, section.id),
    ].where((l) => !covered.contains(l.id)).toList();
    if (leftovers.isNotEmpty) {
      result.add(_Argomento(title: 'Altri', topic: null, lessons: leftovers));
    }
    return result;
  }
}

class _Argomento {
  final String title;
  final Topic? topic;
  final List<Lesson> lessons;

  const _Argomento({
    required this.title,
    required this.topic,
    required this.lessons,
  });
}

class _ArgomentoRow extends StatelessWidget {
  final _Argomento argomento;
  final VoidCallback onTap;

  const _ArgomentoRow({required this.argomento, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final topic = argomento.topic;

    return TopicImageCard(
      title: argomento.title,
      image: topic?.image,
      color: topic == null ? c.accent : topicColor(c, topic.icon),
      onTap: onTap,
    );
  }
}

class _EmptyLessons extends StatelessWidget {
  final String courseTitle;

  const _EmptyLessons({required this.courseTitle});

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
              'Nessuna lezione in questo anno',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: c.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Le lezioni guidate per $courseTitle sono in arrivo.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: c.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
