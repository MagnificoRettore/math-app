import 'package:flutter/material.dart';

import '../data/auth_store.dart';
import '../data/browse_store.dart';
import '../data/content_repository.dart';
import '../data/progress_store.dart';
import '../models/course.dart';
import '../models/level.dart';
import '../models/topic.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../widgets/app_card.dart';
import '../widgets/main_header.dart';
import '../widgets/pill_nav_bar.dart';
import '../widgets/progress_bar.dart';
import '../widgets/school_choice_sheet.dart';
import '../widgets/topic_row.dart';
import '../widgets/year_tabs.dart';
import 'exercise_feed_screen.dart';
import 'year_exercises_screen.dart';

class CourseScreen extends StatefulWidget {
  final Level level;
  final bool showPill;

  /// L'anno (`Course.id`) con cui aprire la pagina; senza, quello scelto alla
  /// registrazione o il primo.
  final String? initialCourseId;

  const CourseScreen({
    super.key,
    required this.level,
    this.showPill = false,
    this.initialCourseId,
  });

  @override
  State<CourseScreen> createState() => _CourseScreenState();
}

class _CourseScreenState extends State<CourseScreen> {
  int _selectedIndex = 0;

  /// Il livello su cui la pagina sta guardando: quello in visita se l'utente
  /// ne ha aperta un'altra, altrimenti quello con cui la pagina è nata.
  Level get _level =>
      ContentRepository.instance.levelById(
        BrowseStore.instance.levelId ?? '',
      ) ??
      widget.level;

  @override
  void initState() {
    super.initState();
    final initial = widget.level.courses.indexWhere(
      (course) => course.id == widget.initialCourseId,
    );
    if (initial >= 0) {
      _selectedIndex = initial;
    } else if (BrowseStore.instance.levelId == null) {
      _selectedIndex = AuthStore.instance.preferredCourseIndex(
        widget.level.id,
        widget.level.courses,
      );
    }
    BrowseStore.instance.addListener(_onBrowseChanged);
  }

  @override
  void dispose() {
    BrowseStore.instance.removeListener(_onBrowseChanged);
    super.dispose();
  }

  /// Cambiando scuola cambia il numero di corsi, quindi l'anno corrente può
  /// finire fuori range: si torna al primo.
  void _onBrowseChanged() {
    if (!mounted) return;
    setState(() => _selectedIndex = 0);
  }

  void _selectYear(int index) => setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    final level = _level;
    final courses = level.courses;

    return Scaffold(
      appBar: MainHeaderAppBar(
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(88),
          child: YearTabs(
            courses: courses,
            selectedIndex: _selectedIndex,
            onSelected: _selectYear,
          ),
        ),
        title: MainHeaderTitle(levelId: level.id),
        actions: const [
          SchoolBrowseButton(destination: SchoolChoiceDestination.exercises),
          HeaderSearchButton(),
          HeaderCustomizationButton(),
        ],
      ),
      body: _buildPages(level, courses),
    );
  }

  Widget _buildPages(Level level, List<Course> courses) {
    if (courses.isEmpty) return const SizedBox.shrink();
    // L'anno si cambia dagli `YearTabs`: lo swipe orizzontale è della
    // navigazione fra le pagine principali. La chiave azzera lo scorrimento.
    final course = courses[_selectedIndex.clamp(0, courses.length - 1)];
    final page = _CourseSectionsView(
      key: ValueKey(course.id),
      level: level,
      course: course,
    );
    if (!widget.showPill) return SafeArea(child: page);
    return PillNavOverlay(selected: PillTab.exercises, child: page);
  }
}

class _CourseSectionsView extends StatelessWidget {
  final Level level;
  final Course course;

  const _CourseSectionsView({
    super.key,
    required this.level,
    required this.course,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final topics = course.topics;
    final allExerciseIds = <String>[
      for (final topic in topics)
        for (final exercise in topic.exercises) exercise.id,
    ];
    final allProgress = ProgressStore.instance.completionFor(
      level.id,
      allExerciseIds,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        if (course.subtitle.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              course.subtitle,
              style: TextStyle(
                fontSize: AppText.bodyMedium,
                color: c.textSecondary,
              ),
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
                          fontSize: AppText.titleSmall,
                          fontWeight: FontWeight.w500,
                          color: c.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tutti gli esercizi del corso',
                        style: TextStyle(
                          fontSize: AppText.label,
                          color: c.textSecondary,
                        ),
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
