import 'package:flutter/material.dart';

import '../data/progress_store.dart';
import '../models/course.dart';
import '../models/level.dart';
import '../models/topic.dart';
import '../theme/app_colors.dart';
import '../widgets/pill_nav_bar.dart';
import '../widgets/topic_row.dart';
import '../widgets/year_tabs.dart';
import 'exercise_feed_screen.dart';

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
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final courses = widget.level.courses;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.level.title,
          style: TextStyle(
            fontSize: 22,
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
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) => setState(() => _selectedIndex = index),
        children: [
          for (final course in courses)
            _CourseTopicsView(level: widget.level, course: course),
        ],
      ),
      bottomNavigationBar: widget.showPill
          ? const PillNavBar(selected: PillTab.exercises)
          : null,
    );
  }
}

class _CourseTopicsView extends StatelessWidget {
  final Level level;
  final Course course;

  const _CourseTopicsView({required this.level, required this.course});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
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
        for (final topic in course.topics)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TopicRow(
              topic: topic,
              progress: _topicProgress(topic),
              onTap: () => _openTopic(context, topic),
            ),
          ),
      ],
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

  double _topicProgress(Topic topic) {
    final ids = topic.exercises.map((e) => e.id).toList();
    return ProgressStore.instance.completionFor(ids);
  }
}
