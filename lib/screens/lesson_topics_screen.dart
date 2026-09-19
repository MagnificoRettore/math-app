import 'package:flutter/material.dart';

import '../data/lesson_repository.dart';
import '../data/progress_store.dart';
import '../models/course.dart';
import '../models/level.dart';
import '../models/lesson.dart';
import '../models/topic.dart';
import '../theme/app_colors.dart';
import '../widgets/app_card.dart';
import '../widgets/progress_bar.dart';

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
    return ListenableBuilder(
      listenable: ProgressStore.instance,
      builder: (context, _) => ListView(
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
                progress: ProgressStore.instance.completionFor(
                  argomento.lessons.map((l) => l.id),
                ),
                onTap: () => onSelectArgument(argomento.title, argomento.topic),
              ),
            ),
        ],
      ),
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
          _Argomento(
            title: topic.title,
            topic: topic,
            lessons: lessons,
            subtitle: topic.subtitle.isEmpty ? section.title : topic.subtitle,
          ),
        );
      }
    }
    final leftovers = [
      for (final section in course.sections)
        ...LessonRepository.instance.lessonsInSection(level.id, section.id),
    ].where((l) => !covered.contains(l.id)).toList();
    if (leftovers.isNotEmpty) {
      result.add(
        _Argomento(
          title: 'Altri',
          topic: null,
          lessons: leftovers,
          subtitle: '',
        ),
      );
    }
    return result;
  }
}

class _Argomento {
  final String title;
  final Topic? topic;
  final List<Lesson> lessons;
  final String subtitle;

  const _Argomento({
    required this.title,
    required this.topic,
    required this.lessons,
    required this.subtitle,
  });
}

class _ArgomentoRow extends StatelessWidget {
  final _Argomento argomento;
  final double progress;
  final VoidCallback onTap;

  const _ArgomentoRow({
    required this.argomento,
    required this.progress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final topic = argomento.topic;
    final icon = topic == null
        ? Icons.menu_book_outlined
        : _iconFor(topic.icon);
    final color = topic == null ? c.accent : _colorFor(c, topic.icon);

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  argomento.title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: c.textPrimary,
                  ),
                ),
                if (argomento.subtitle.isNotEmpty) ...[
                  const SizedBox(height: 1),
                  Text(
                    argomento.subtitle,
                    style: TextStyle(fontSize: 12, color: c.textSecondary),
                  ),
                ],
                const SizedBox(height: 8),
                ProgressBar(progress: progress, height: 4, color: c.accent),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '${argomento.lessons.length}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: c.textSecondary,
            ),
          ),
          const SizedBox(width: 6),
          Icon(Icons.chevron_right, color: c.textSecondary, size: 20),
        ],
      ),
    );
  }

  IconData _iconFor(String name) {
    switch (name) {
      case 'pie_chart':
        return Icons.pie_chart_outline;
      case 'functions':
        return Icons.functions;
      case 'tag':
        return Icons.tag;
      case 'trending_up':
        return Icons.trending_up;
      case 'show_chart':
        return Icons.show_chart;
      case 'calculate':
        return Icons.calculate_outlined;
      case 'grid_on':
        return Icons.grid_on_outlined;
      case 'casino':
        return Icons.casino_outlined;
      case 'account_tree':
        return Icons.account_tree_outlined;
      default:
        return Icons.menu_book_outlined;
    }
  }

  Color _colorFor(AppPalette c, String name) {
    switch (name) {
      case 'pie_chart':
        return c.pink;
      case 'functions':
        return c.accent;
      case 'tag':
        return c.medium;
      case 'trending_up':
        return c.easy;
      case 'show_chart':
        return c.teal;
      case 'calculate':
        return c.purple;
      case 'grid_on':
        return c.indigo;
      case 'casino':
        return c.pink;
      case 'account_tree':
        return c.teal;
      default:
        return c.accent;
    }
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
