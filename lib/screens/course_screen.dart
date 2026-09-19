import 'package:flutter/material.dart';

import '../data/progress_store.dart';
import '../models/course.dart';
import '../models/level.dart';
import '../models/topic.dart';
import '../theme/app_colors.dart';
import '../widgets/app_card.dart';
import '../widgets/pill_nav_bar.dart';
import '../widgets/progress_bar.dart';
import '../widgets/topic_row.dart';
import '../widgets/year_tabs.dart';
import 'exercise_feed_screen.dart';
import 'year_exercises_screen.dart';

class CourseScreen extends StatefulWidget {
  final Level level;
  final bool showPill;

  const CourseScreen({super.key, required this.level, this.showPill = false});

  @override
  State<CourseScreen> createState() => _CourseScreenState();
}

class _CourseScreenState extends State<CourseScreen> {
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
    final courses = widget.level.courses;

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
      body: _buildPages(courses),
    );
  }

  Widget _buildPages(List<Course> courses) {
    final pageView = PageView(
      controller: _pageController,
      onPageChanged: (index) => setState(() => _selectedIndex = index),
      children: [
        for (final course in courses)
          _CourseSectionsView(level: widget.level, course: course),
      ],
    );
    if (!widget.showPill) return pageView;
    return PillNavOverlay(selected: PillTab.exercises, child: pageView);
  }
}

class _CourseSectionsView extends StatelessWidget {
  final Level level;
  final Course course;

  const _CourseSectionsView({required this.level, required this.course});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final topics = course.topics;
    final allExerciseIds = <String>[
      for (final topic in topics)
        for (final exercise in topic.exercises) exercise.id,
    ];
    final allProgress = ProgressStore.instance.completionFor(allExerciseIds);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        if (course.subtitle.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              course.subtitle,
              style: TextStyle(fontSize: 14, color: c.textSecondary),
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: AppCard(
            key: const Key('tutti-esercizi'),
            onTap: () => _openAll(context),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: c.teal.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.all_inclusive, size: 22, color: c.teal),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tutti gli esercizi',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: c.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tutti gli esercizi del corso',
                        style: TextStyle(fontSize: 13, color: c.textSecondary),
                      ),
                      const SizedBox(height: 10),
                      ProgressBar(
                        progress: allProgress,
                        height: 8,
                        color: c.teal,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        for (final topic in topics)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: TopicRow(
              key: Key('topic-${topic.id}'),
              topic: topic,
              progress: ProgressStore.instance.completionFor(
                topic.exercises.map((e) => e.id),
              ),
              onTap: () => _openTopic(context, topic),
            ),
          ),
      ],
    );
  }

  void _openAll(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => YearExercisesScreen(level: level, course: course),
      ),
    );
  }

  void _openTopic(BuildContext context, Topic topic) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            ExerciseFeedScreen(level: level, course: course, topic: topic),
      ),
    );
  }
}
