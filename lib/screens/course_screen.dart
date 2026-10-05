import 'package:flutter/material.dart';

import '../data/auth_store.dart';
import '../data/browse_store.dart';
import '../data/content_repository.dart';
import '../data/progress_store.dart';
import '../models/course.dart';
import '../models/level.dart';
import '../models/exercise.dart';
import '../models/topic.dart';
import '../theme/app_colors.dart';
import '../theme/topic_style.dart';
import '../widgets/main_header.dart';
import '../widgets/pill_nav_bar.dart';
import '../widgets/empty_state.dart';
import '../widgets/list_filter_bar.dart';
import '../widgets/resume_card.dart';
import '../widgets/school_choice_sheet.dart';
import '../widgets/streak_chip.dart';
import '../widgets/section_header.dart';
import '../widgets/topic_grid.dart';
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
  ListFilter _filter = ListFilter.all;

  /// Il livello su cui la pagina sta guardando: quello in visita se l'utente
  /// ne ha aperta un'altra, altrimenti quello con cui la pagina è nata.
  ///
  /// La scuola del profilo viene prima di quella con cui la pagina è nata:
  /// cambiandola dal profilo mentre questa pagina è sotto, deve seguirla.
  Level get _level =>
      ContentRepository.instance.levelById(
        BrowseStore.instance.levelId ?? _profileLevelId ?? '',
      ) ??
      widget.level;

  static String? get _profileLevelId {
    final id = AuthStore.instance.currentUser?.schoolLevelId;
    return id == null || id.isEmpty ? null : id;
  }

  /// Scuola e anno del profilo all'ultimo controllo, per accorgersi che sono
  /// cambiati.
  String? _seenLevelId;
  String? _seenCourseId;

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
    _seenLevelId = _profileLevelId;
    _seenCourseId = AuthStore.instance.currentUser?.courseId;
    BrowseStore.instance.addListener(_onBrowseChanged);
    AuthStore.instance.addListener(_onProfileChanged);
  }

  @override
  void dispose() {
    BrowseStore.instance.removeListener(_onBrowseChanged);
    AuthStore.instance.removeListener(_onProfileChanged);
    super.dispose();
  }

  /// Cambiando scuola cambia il numero di corsi, quindi l'anno corrente può
  /// finire fuori range: si torna al primo.
  void _onBrowseChanged() {
    if (!mounted) return;
    setState(() => _selectedIndex = 0);
  }

  /// Se dal profilo cambia la scuola o l'anno, la pagina si aggiorna subito: si
  /// riparte dall'anno del profilo (o dal primo) sulla scuola nuova.
  void _onProfileChanged() {
    final levelId = _profileLevelId;
    final courseId = AuthStore.instance.currentUser?.courseId;
    if (levelId == _seenLevelId && courseId == _seenCourseId) return;
    _seenLevelId = levelId;
    _seenCourseId = courseId;
    if (!mounted || BrowseStore.instance.levelId != null) return;
    final level = _level;
    setState(() {
      _selectedIndex = AuthStore.instance.preferredCourseIndex(
        level.id,
        level.courses,
      );
    });
  }

  void _selectYear(int index) => setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    final level = _level;
    final courses = level.courses;

    return Scaffold(
      appBar: MainHeaderAppBar(
        title: MainHeaderTitle(levelId: level.id),
        actions: const [
          SchoolBrowseButton(destination: SchoolChoiceDestination.exercises),
          HeaderStreakChip(),
          HeaderCustomizationButton(),
        ],
      ),
      body: _buildPages(level, courses),
    );
  }

  Widget _buildPages(Level level, List<Course> courses) {
    if (courses.isEmpty) return const SizedBox.shrink();
    // L'anno si cambia dal menu in cima: lo swipe orizzontale è della
    // navigazione fra le pagine principali. La chiave azzera lo scorrimento.
    final course = courses[_selectedIndex.clamp(0, courses.length - 1)];
    final page = Column(
      children: [
        ListFilterBar(
          courses: courses,
          selectedIndex: _selectedIndex,
          onYear: _selectYear,
          filter: _filter,
          onFilter: (filter) => setState(() => _filter = filter),
        ),
        Expanded(
          child: _CourseSectionsView(
            key: ValueKey(course.id),
            level: level,
            course: course,
            filter: _filter,
          ),
        ),
      ],
    );
    if (!widget.showPill) return SafeArea(child: page);
    return PillNavOverlay(selected: PillTab.exercises, child: page);
  }
}

class _CourseSectionsView extends StatelessWidget {
  final Level level;
  final Course course;
  final ListFilter filter;

  const _CourseSectionsView({
    super.key,
    required this.level,
    required this.course,
    required this.filter,
  });

  /// Quanti esercizi del topic sono fatti (padroneggiati o da ripassare).
  double _completion(Iterable<Exercise> exercises) => ProgressStore.instance
      .completionFor(level.id, [for (final e in exercises) e.id]);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ProgressStore.instance,
      builder: (context, _) {
        final c = AppColors.of(context);
        final topics = course.topics;
        final all = [for (final topic in topics) ...topic.exercises];
        // «In corso»: almeno un esercizio fatto, ma non tutti.
        final shown = [
          for (final topic in topics)
            if (filter == ListFilter.all ||
                (_completion(topic.exercises) > 0 &&
                    _completion(topic.exercises) < 1))
              topic,
        ];
        final resume = _resume(context, topics);
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            if (resume != null) ...[const SizedBox(height: 8), resume],
            const SectionHeader('Tutti gli argomenti', top: 16),
            if (filter == ListFilter.inProgress && shown.isEmpty)
              const EmptyState(
                key: Key('nessun-topic-in-corso'),
                title: 'Nessun argomento in corso',
                subtitle:
                    'Qui trovi gli argomenti di cui hai iniziato gli esercizi '
                    'e non ancora finito.',
              )
            else
              TopicGrid(
                entries: [
                  if (filter == ListFilter.all)
                    TopicGridEntry(
                      key: const Key('tutti-esercizi'),
                      icon: Icons.all_inclusive,
                      color: c.teal,
                      title: 'Tutti gli esercizi',
                      caption: _caption(all.length, _completion(all)),
                      onTap: () => _openAll(context),
                    ),
                  for (final topic in shown)
                    TopicGridEntry(
                      key: Key('topic-${topic.id}'),
                      icon: topicIcon(topic.icon),
                      color: topicColor(c, topic.icon),
                      title: topic.title,
                      caption: _caption(
                        topic.exercises.length,
                        _completion(topic.exercises),
                      ),
                      onTap: () => _openTopic(context, topic),
                    ),
                ],
              ),
          ],
        );
      },
    );
  }

  String _caption(int count, double completion) =>
      '${count == 1 ? '1 esercizio' : '$count esercizi'} · '
      '${(completion * 100).round()}%';

  /// Il primo topic iniziato e non finito, da cui ripartire. Gli esercizi non
  /// salvano «l'ultimo aperto»: si parte da quello che è a metà.
  Widget? _resume(BuildContext context, List<Topic> topics) {
    for (final topic in topics) {
      final completion = _completion(topic.exercises);
      if (completion <= 0 || completion >= 1) continue;
      final total = topic.exercises.length;
      final done = (completion * total).round();
      return ResumeCard(
        title: topic.title,
        caption: 'Esercizio $done di $total',
        progress: completion,
        onTap: () => _openTopic(context, topic),
      );
    }
    return null;
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
