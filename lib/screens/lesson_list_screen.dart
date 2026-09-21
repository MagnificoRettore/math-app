import 'package:flutter/material.dart';

import '../data/content_repository.dart';
import '../models/course.dart';
import '../widgets/pill_nav_bar.dart';
import '../widgets/year_tabs.dart';
import '../theme/app_colors.dart';

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

  @override
  Widget build(BuildContext context) {
    final levelId = widget.levelId;
    final level = levelId == null
        ? null
        : ContentRepository.instance.levelById(levelId);
    final courses = level?.courses ?? const <Course>[];

    if (level == null || courses.isEmpty) {
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
              _EmptyLessons(
                title: 'Nessuna lezione in ${course.title}',
                subtitle:
                    'Le lezioni guidate per ${course.title} sono in arrivo.',
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