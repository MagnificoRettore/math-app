import 'package:flutter/material.dart';

import '../data/auth_store.dart';
import '../data/browse_store.dart';
import '../data/content_repository.dart';
import '../data/lesson_repository.dart';
import '../data/progress_store.dart';
import '../data/resume_target.dart';
import '../models/argomento.dart';
import '../models/course.dart';
import '../screens/argomento_lessons_screen.dart';
import '../theme/app_colors.dart';
import '../theme/topic_style.dart';
import '../widgets/empty_state.dart';
import '../widgets/list_filter_bar.dart';
import '../widgets/main_header.dart';
import '../widgets/pill_nav_bar.dart';
import '../widgets/resume_card.dart';
import '../widgets/section_header.dart';
import '../widgets/topic_grid.dart';
import 'lesson_screen.dart';

class LessonListScreen extends StatefulWidget {
  final String? levelId;

  /// `true` dentro la `HomeScreen`: solo il contenuto, perché header e barra
  /// sono suoi e restano fermi mentre le pagine scorrono. `false` è una pagina
  /// a sé, con il suo header.
  final bool embedded;

  const LessonListScreen({super.key, this.levelId, this.embedded = false});

  @override
  State<LessonListScreen> createState() => _LessonListScreenState();
}

class _LessonListScreenState extends State<LessonListScreen> {
  int _selectedIndex = 0;
  ListFilter _filter = ListFilter.all;

  /// Il livello su cui la pagina sta guardando: quello in visita se l'utente
  /// ne ha aperta un'altra, altrimenti quello con cui la pagina è nata.
  ///
  /// La scuola del profilo viene prima di quella con cui la pagina è nata:
  /// cambiandola dal profilo mentre questa pagina è sotto, deve seguirla.
  String? get _levelId =>
      BrowseStore.instance.levelId ?? _profileLevelId ?? widget.levelId;

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
    final level = ContentRepository.instance.levelById(_levelId ?? '');
    if (level != null && BrowseStore.instance.levelId == null) {
      _selectedIndex = AuthStore.instance.preferredCourseIndex(
        level.id,
        level.courses,
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

  /// Cambiando scuola cambia il numero di corsi, quindi l'indice dell'anno
  /// corrente può finire fuori range: si torna al primo.
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
    final level = ContentRepository.instance.levelById(_levelId ?? '');
    setState(() {
      _selectedIndex = level == null
          ? 0
          : AuthStore.instance.preferredCourseIndex(level.id, level.courses);
    });
  }

  void _selectYear(int index) => setState(() => _selectedIndex = index);

  void _openArgomento(Argomento argomento) {
    if (argomento.lessons.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ArgomentoLessonsScreen(
          argomento: argomento,
          levelId: _levelId ?? argomento.levelId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final levelId = _levelId;
    const vuoto = EmptyState(
      title: 'Nessuna lezione disponibile',
      subtitle: 'Le lezioni guidate per questo livello sono in arrivo.',
    );
    final level = levelId == null
        ? null
        : ContentRepository.instance.levelById(levelId);
    final courses = level?.courses ?? const <Course>[];

    final Widget body;
    if (levelId == null || courses.isEmpty) {
      body = vuoto;
    } else {
      // L'anno si cambia dal menu in cima: lo swipe orizzontale è della
      // navigazione fra le pagine principali. La chiave azzera lo scorrimento.
      body = Column(
        children: [
          ListFilterBar(
            courses: courses,
            selectedIndex: _selectedIndex,
            onYear: _selectYear,
            filter: _filter,
            onFilter: (filter) => setState(() => _filter = filter),
          ),
          Expanded(
            child: _YearArgumenti(
              key: ValueKey(
                courses[_selectedIndex.clamp(0, courses.length - 1)].id,
              ),
              levelId: levelId,
              course: courses[_selectedIndex.clamp(0, courses.length - 1)],
              filter: _filter,
              onTapArgomento: _openArgomento,
            ),
          ),
        ],
      );
    }
    if (widget.embedded) return body;
    return Scaffold(
      appBar: mainHeaderFor(PillTab.lessons, levelId: _levelId),
      body: SafeArea(child: body),
    );
  }
}

class _YearArgumenti extends StatelessWidget {
  final String levelId;
  final Course course;
  final ListFilter filter;
  final ValueChanged<Argomento> onTapArgomento;

  const _YearArgumenti({
    super.key,
    required this.levelId,
    required this.course,
    required this.filter,
    required this.onTapArgomento,
  });

  @override
  Widget build(BuildContext context) {
    final argomenti = LessonRepository.instance.argomenti
        .where((a) => a.levelId == levelId && a.yearId == course.id)
        .toList();

    if (argomenti.isEmpty) {
      return EmptyState(
        title: 'Nessuna lezione in ${course.title}',
        subtitle: 'Le lezioni guidate per ${course.title} sono in arrivo.',
      );
    }

    return ListenableBuilder(
      listenable: ProgressStore.instance,
      builder: (context, _) {
        final store = ProgressStore.instance;
        // «In corso»: almeno una lezione fatta, ma non tutte.
        final shown = [
          for (final argomento in argomenti)
            if (filter == ListFilter.all ||
                (store.completedLessonCount(argomento) > 0 &&
                    !store.isArgomentoCompleted(argomento)))
              argomento,
        ];
        final resume = _resume();
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            if (resume != null) ...[const SizedBox(height: 8), resume],
            const SectionHeader('Tutti gli argomenti', top: 16),
            if (shown.isEmpty)
              const EmptyState(
                key: Key('nessun-argomento-in-corso'),
                title: 'Nessun argomento in corso',
                subtitle:
                    'Qui trovi gli argomenti che hai iniziato e non ancora '
                    'finito.',
              )
            else
              TopicGrid(
                entries: [
                  for (final argomento in shown) _entry(context, argomento),
                ],
              ),
          ],
        );
      },
    );
  }

  /// La lezione lasciata a metà, se è di questa scuola.
  Widget? _resume() {
    final target = ResumeTarget.find();
    if (target == null || target.resume.levelId != levelId) return null;
    final total = target.lesson.steps.length;
    final step = target.resume.step.clamp(0, total == 0 ? 0 : total - 1);
    return Builder(
      builder: (context) => ResumeCard(
        title: '${target.argomento.title} · ${target.lesson.title}',
        caption: 'Card ${step + 1} di $total',
        progress: total == 0 ? 0 : step / total,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => LessonScreen(
              lesson: target.lesson,
              levelId: levelId,
              initialStep: step,
            ),
          ),
        ),
      ),
    );
  }

  TopicGridEntry _entry(BuildContext context, Argomento argomento) {
    final c = AppColors.of(context);
    final lessonCount = argomento.lessons.length;
    final percent = lessonCount == 0
        ? 0
        : (ProgressStore.instance.completedLessonCount(argomento) *
                  100 /
                  lessonCount)
              .round();
    return TopicGridEntry(
      key: Key(
        'argomento-${argomento.topicId.isEmpty ? argomento.title : argomento.topicId}',
      ),
      icon: topicIcon(argomento.icon),
      color: topicColor(c, argomento.icon),
      title: argomento.title,
      caption:
          '${lessonCount == 1 ? '1 lezione' : '$lessonCount lezioni'} · '
          '$percent%',
      status: ProgressStore.instance.statusOfArgomento(argomento),
      onTap: () => onTapArgomento(argomento),
    );
  }
}
