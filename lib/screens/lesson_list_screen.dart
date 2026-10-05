import 'package:flutter/material.dart';

import '../data/auth_store.dart';
import '../data/browse_store.dart';
import '../data/content_repository.dart';
import '../data/lesson_repository.dart';
import '../data/progress_store.dart';
import '../models/argomento.dart';
import '../models/course.dart';
import '../screens/argomento_lessons_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../theme/topic_style.dart';
import '../widgets/app_card.dart';
import '../widgets/progress_bar.dart';
import '../widgets/completed_badge.dart';
import '../widgets/empty_state.dart';
import '../widgets/main_header.dart';
import '../widgets/pill_nav_bar.dart';
import '../widgets/school_choice_sheet.dart';
import '../widgets/year_tabs.dart';

class LessonListScreen extends StatefulWidget {
  final String? levelId;
  final bool showPill;

  const LessonListScreen({super.key, this.levelId, this.showPill = false});

  @override
  State<LessonListScreen> createState() => _LessonListScreenState();
}

class _LessonListScreenState extends State<LessonListScreen> {
  int _selectedIndex = 0;

  /// Il livello su cui la pagina sta guardando: quello in visita se l'utente
  /// ne ha aperta un'altra, altrimenti quello con cui la pagina è nata.
  String? get _levelId => BrowseStore.instance.levelId ?? widget.levelId;

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
    BrowseStore.instance.addListener(_onBrowseChanged);
  }

  @override
  void dispose() {
    BrowseStore.instance.removeListener(_onBrowseChanged);
    super.dispose();
  }

  /// Cambiando scuola cambia il numero di corsi, quindi l'indice dell'anno
  /// corrente può finire fuori range: si torna al primo.
  void _onBrowseChanged() {
    if (!mounted) return;
    setState(() => _selectedIndex = 0);
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
    if (levelId == null) {
      return Scaffold(
        appBar: MainHeaderAppBar(
          title: MainHeaderTitle(levelId: _levelId),
          actions: _actions(),
        ),
        body: _wrapBody(
          const EmptyState(
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
        appBar: MainHeaderAppBar(
          title: MainHeaderTitle(levelId: _levelId),
          actions: _actions(),
        ),
        body: _wrapBody(
          const EmptyState(
            title: 'Nessuna lezione disponibile',
            subtitle: 'Le lezioni guidate per questo livello sono in arrivo.',
          ),
        ),
      );
    }

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
        title: MainHeaderTitle(levelId: _levelId),
        actions: _actions(),
      ),
      body: _wrapBody(
        // L'anno si cambia dagli `YearTabs`: lo swipe orizzontale è della
        // navigazione fra le pagine principali. La chiave azzera lo scorrimento.
        _YearArgumenti(
          key: ValueKey(
            courses[_selectedIndex.clamp(0, courses.length - 1)].id,
          ),
          levelId: levelId,
          course: courses[_selectedIndex.clamp(0, courses.length - 1)],
          onTapArgomento: _openArgomento,
        ),
      ),
    );
  }

  /// Le azioni dell'header: le altre scuole per primo, poi la lente e la
  /// personalizzazione, che è l'ultima a destra come sulla Home. Anche negli
  /// stati vuoti i bottoni ci sono, perché è proprio da lì che si sceglie
  /// un'altra scuola quando questa non ha lezioni.
  List<Widget> _actions() => const [
    SchoolBrowseButton(destination: SchoolChoiceDestination.lessons),
    HeaderSearchButton(),
    HeaderCustomizationButton(),
  ];

  Widget _wrapBody(Widget body) {
    if (!widget.showPill) return SafeArea(child: body);
    return PillNavOverlay(selected: PillTab.lessons, child: body);
  }
}

class _YearArgumenti extends StatelessWidget {
  final String levelId;
  final Course course;
  final ValueChanged<Argomento> onTapArgomento;

  const _YearArgumenti({
    super.key,
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
      return EmptyState(
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
                completed: ProgressStore.instance.isArgomentoCompleted(
                  argomento,
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

    final card = AppCard(
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
                    fontSize: AppText.titleMedium,
                    fontWeight: FontWeight.w500,
                    color: c.textPrimary,
                  ),
                ),
                if (argomento.subtitle.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    argomento.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: AppText.label,
                      color: c.textSecondary,
                    ),
                  ),
                ],
                if (lessonCount > 0) ...[
                  const SizedBox(height: 8),
                  ProgressBar(
                    progress:
                        ProgressStore.instance.completedLessonCount(argomento) /
                        lessonCount,
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
                      style: TextStyle(
                        fontSize: AppText.caption,
                        color: c.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.chevron_right, color: c.textSecondary),
        ],
      ),
    );
    if (!completed) return card;
    // Il segno «completata» nell'angolo in alto a destra, sopra la card.
    return Stack(children: [card, CompletedBadge.corner()]);
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
