import 'package:flutter/material.dart';

import '../data/content_repository.dart';
import '../data/lesson_repository.dart';
import '../data/progress_store.dart';
import '../models/argomento.dart';
import '../models/course.dart';
import '../screens/lesson_screen.dart';
import '../theme/app_colors.dart';
import '../theme/topic_style.dart';
import '../widgets/app_card.dart';
import '../widgets/pill_nav_bar.dart';
import '../widgets/year_tabs.dart';

class LessonListScreen extends StatefulWidget {
  final String? levelId;
  final bool showPill;

  const LessonListScreen({super.key, this.levelId, this.showPill = false});

  @override
  State<LessonListScreen> createState() => _LessonListScreenState();
}

class _LessonListScreenState extends State<LessonListScreen> {
  late final PageController _pageController;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _selectYear(int index) {
    setState(() => _selectedIndex = index);
    _pageController.jumpToPage(index);
  }

  void _openArgomento(Argomento argomento) {
    if (argomento.lessons.isEmpty) return;
    final lesson = argomento.lessons.first;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            LessonScreen(lesson: lesson, levelId: argomento.levelId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final levelId = widget.levelId;
    if (levelId == null) {
      return Scaffold(
        appBar: AppBar(),
        body: _wrapBody(
          const _EmptyLessons(
            title: 'Nessuna lezione disponibile',
            subtitle: 'Le lezioni guidate per questo livello sono in arrivo.',
          ),
        ),
      );
    }
    final level = ContentRepository.instance.levelById(levelId);
    final courses = level?.courses ?? const <Course>[];

    if (courses.isEmpty) {
      return Scaffold(
        appBar: AppBar(),
        body: _wrapBody(
          const _EmptyLessons(
            title: 'Nessuna lezione disponibile',
            subtitle: 'Le lezioni guidate per questo livello sono in arrivo.',
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(88),
          child: YearTabs(
            courses: courses,
            selectedIndex: _selectedIndex,
            onSelected: _selectYear,
          ),
        ),
      ),
      body: _wrapBody(
        PageView(
          controller: _pageController,
          onPageChanged: (index) => setState(() => _selectedIndex = index),
          children: [
            for (final course in courses)
              _YearArgumenti(
                levelId: levelId,
                course: course,
                onTapArgomento: _openArgomento,
              ),
          ],
        ),
      ),
    );
  }

  Widget _wrapBody(Widget body) {
    if (!widget.showPill) return body;
    return PillNavOverlay(selected: PillTab.lessons, child: body);
  }
}

class _YearArgumenti extends StatelessWidget {
  final String levelId;
  final Course course;
  final ValueChanged<Argomento> onTapArgomento;

  const _YearArgumenti({
    required this.levelId,
    required this.course,
    required this.onTapArgomento,
  });

  @override
  Widget build(BuildContext context) {
    final argomenti = LessonRepository.instance.argomenti
        .where((a) => a.levelId == levelId && a.yearId == course.id)
        .toList();

    if (argomenti.isEmpty) {
      return _EmptyLessons(
        title: 'Nessuna lezione in ${course.title}',
        subtitle: 'Le lezioni guidate per ${course.title} sono in arrivo.',
      );
    }

    return ListenableBuilder(
      listenable: ProgressStore.instance,
      builder: (context, _) => ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          for (final argomento in argomenti)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _ArgomentoCard(
                argomento: argomento,
                completed:
                    argomento.lessons.isNotEmpty &&
                    argomento.lessons.every(
                      (lesson) => ProgressStore.instance.isLessonCompleted(
                        argomento.levelId,
                        lesson.id,
                      ),
                    ),
                onTap: () => onTapArgomento(argomento),
              ),
            ),
        ],
      ),
    );
  }
}

class _ArgomentoCard extends StatelessWidget {
  final Argomento argomento;
  final bool completed;
  final VoidCallback onTap;

  const _ArgomentoCard({
    required this.argomento,
    required this.completed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final color = topicColor(c, argomento.icon);
    final lessonCount = argomento.lessons.length;

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(_iconFor(argomento.icon), color: color, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  argomento.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: c.textPrimary,
                  ),
                ),
                if (argomento.subtitle.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    argomento.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, color: c.textSecondary),
                  ),
                ],
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.menu_book_outlined,
                      size: 14,
                      color: c.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      lessonCount == 1 ? '1 lezione' : '$lessonCount lezioni',
                      style: TextStyle(fontSize: 12, color: c.textSecondary),
                    ),
                  ],
                ),
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

  IconData _iconFor(String name) {
    switch (name) {
      case 'functions':
        return Icons.functions;
      case 'pie_chart':
        return Icons.pie_chart;
      case 'tag':
        return Icons.tag;
      case 'trending_up':
        return Icons.trending_up;
      case 'show_chart':
        return Icons.show_chart;
      case 'calculate':
        return Icons.calculate;
      case 'grid_on':
        return Icons.grid_on;
      case 'casino':
        return Icons.casino;
      case 'account_tree':
        return Icons.account_tree;
      default:
        return Icons.menu_book;
    }
  }
}

class _EmptyLessons extends StatelessWidget {
  final String title;
  final String subtitle;

  const _EmptyLessons({required this.title, required this.subtitle});

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
