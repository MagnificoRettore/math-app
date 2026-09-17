import 'package:flutter/material.dart';

import '../data/content_repository.dart';
import '../data/lesson_repository.dart';
import '../data/progress_store.dart';
import '../models/course.dart';
import '../models/lesson.dart';
import '../theme/app_colors.dart';
import '../widgets/lesson_card.dart';
import '../widgets/pill_nav_bar.dart';
import '../widgets/year_tabs.dart';
import 'lesson_screen.dart';

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
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final levelId = widget.levelId;
    final level = levelId == null
        ? null
        : ContentRepository.instance.levelById(levelId);
    final courses = level?.courses ?? const <Course>[];

    if (level == null || courses.isEmpty) {
      final lessons = LessonRepository.instance.lessons;
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'Lezioni interattive',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: c.textPrimary,
            ),
          ),
        ),
        bottomNavigationBar: widget.showPill
            ? const PillNavBar(selected: PillTab.lessons)
            : null,
        body: lessons.isEmpty
            ? const _EmptyLessons(
                title: 'Nessuna lezione disponibile',
                subtitle:
                    'Le lezioni guidate per questo livello sono in arrivo.',
              )
            : _LessonsList(lessons: lessons),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Lezioni · ${level.title}',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: c.textPrimary,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(88),
          child: YearTabs(
            courses: courses,
            selectedIndex: _selectedIndex,
            onSelected: _selectYear,
          ),
        ),
      ),
      bottomNavigationBar: widget.showPill
          ? const PillNavBar(selected: PillTab.lessons)
          : null,
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) => setState(() => _selectedIndex = index),
        children: [
          for (final course in courses)
            _YearLessonsView(levelId: level.id, course: course),
        ],
      ),
    );
  }
}

class _YearLessonsView extends StatelessWidget {
  final String levelId;
  final Course course;

  const _YearLessonsView({required this.levelId, required this.course});

  @override
  Widget build(BuildContext context) {
    final lessons = LessonRepository.instance.lessonsInYear(levelId, course.id);
    if (lessons.isEmpty) return const SizedBox.expand();
    return _LessonsList(lessons: lessons);
  }
}

class _LessonsList extends StatelessWidget {
  final List<Lesson> lessons;

  const _LessonsList({required this.lessons});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ProgressStore.instance,
      builder: (context, _) => ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          for (final lesson in lessons)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: LessonCard(
                lesson: lesson,
                completed: ProgressStore.instance.isLessonCompleted(lesson.id),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => LessonScreen(lesson: lesson),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
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
