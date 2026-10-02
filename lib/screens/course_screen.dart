import 'package:flutter/material.dart';

import '../data/browse_store.dart';
import '../data/content_repository.dart';
import '../data/progress_store.dart';
import '../models/course.dart';
import '../models/level.dart';
import '../models/topic.dart';
import '../theme/app_colors.dart';
import '../widgets/app_card.dart';
import '../widgets/main_header.dart';
import '../widgets/pill_nav_bar.dart';
import '../widgets/profile_button.dart';
import '../widgets/progress_bar.dart';
import '../widgets/school_choice_sheet.dart';
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
  late PageController _pageController;
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
    _pageController = PageController();
    BrowseStore.instance.addListener(_onBrowseChanged);
  }

  @override
  void dispose() {
    BrowseStore.instance.removeListener(_onBrowseChanged);
    _pageController.dispose();
    super.dispose();
  }

  /// Cambiando scuola cambia il numero di corsi, quindi l'anno corrente può
  /// finire fuori range: si torna al primo e si rifà il `PageController`.
  void _onBrowseChanged() {
    if (!mounted) return;
    setState(() {
      _selectedIndex = 0;
      _pageController.dispose();
      _pageController = PageController();
    });
  }

  void _selectYear(int index) {
    setState(() => _selectedIndex = index);
    _pageController.jumpToPage(index);
  }

  @override
  Widget build(BuildContext context) {
    final level = _level;
    final courses = level.courses;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: kHeaderToolbarHeight,
        titleSpacing: kHeaderHorizontalMargin,
        // Il titolo occupa tutta la larghezza rimasta, e il `Center` dentro
        // `ProfileButton` metterebbe l'avatar al centro di quella: lo stringo
        // alla sua misura, così resta a filo del margine sinistro.
        title: const SizedBox(
          width: kProfileAvatarSize,
          child: ProfileButton(),
        ),
        actionsPadding: kHeaderActionsPadding,
        actions: const [
          SchoolBrowseButton(destination: SchoolChoiceDestination.exercises),
          HeaderSearchButton(),
          HeaderCustomizationButton(),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(88),
          child: YearTabs(
            courses: courses,
            selectedIndex: _selectedIndex,
            onSelected: _selectYear,
          ),
        ),
      ),
      body: _buildPages(level, courses),
    );
  }

  Widget _buildPages(Level level, List<Course> courses) {
    final pageView = PageView(
      controller: _pageController,
      onPageChanged: (index) => setState(() => _selectedIndex = index),
      children: [
        for (final course in courses)
          _CourseSectionsView(level: level, course: course),
      ],
    );
    if (!widget.showPill) return SafeArea(child: pageView);
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
