import 'package:flutter/material.dart';

import '../data/progress_store.dart';
import '../models/course.dart';
import '../models/level.dart';
import '../models/topic.dart';
import '../theme/app_colors.dart';
import '../widgets/pill_nav_bar.dart';
import '../widgets/topic_row.dart';
import 'exercise_feed_screen.dart';

class CourseScreen extends StatefulWidget {
  final Level level;
  final bool showPill;

  const CourseScreen({
    super.key,
    required this.level,
    this.showPill = false,
  });

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
          child: Container(
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: c.border)),
            ),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints:
                        BoxConstraints(minWidth: constraints.maxWidth),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        for (final (index, course) in courses.indexed)
                          _YearTab(
                            circleText: _circleText(course.title),
                            label: course.title,
                            selected: index == _selectedIndex,
                            onTap: () => _selectYear(index),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
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

  String _circleText(String title) {
    final digit = RegExp(r'\d+').firstMatch(title);
    if (digit != null) return digit.group(0)!;

    final roman =
        RegExp(r'\b([IVXLCDM]+)\b', caseSensitive: false).firstMatch(title);
    if (roman != null) return roman.group(1)!.toUpperCase();

    final words =
        title.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return '';
    if (words.length == 1) return words.first.substring(0, 1).toUpperCase();
    return words.take(2).map((w) => w.substring(0, 1)).join().toUpperCase();
  }
}

class _YearTab extends StatelessWidget {
  final String circleText;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _YearTab({
    required this.circleText,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected ? c.accent : c.surface,
              border: Border.all(
                color: selected ? c.accent : c.border,
                width: 1.5,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: c.accent.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: Text(
              circleText,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : c.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 5),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 72),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected
                    ? c.textPrimary
                    : c.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CourseTopicsView extends StatelessWidget {
  final Level level;
  final Course course;

  const _CourseTopicsView({
    required this.level,
    required this.course,
  });

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
              style: TextStyle(
                fontSize: 14,
                color: c.textSecondary,
              ),
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
        builder: (_) => ExerciseFeedScreen(
          level: level,
          course: course,
          topic: topic,
        ),
      ),
    );
  }

  double _topicProgress(Topic topic) {
    final ids = topic.exercises.map((e) => e.id).toList();
    return ProgressStore.instance.completionFor(ids);
  }
}