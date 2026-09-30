import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

import '../data/progress_store.dart';
import '../models/lesson.dart';
import '../models/lesson_resume.dart';
import '../models/lesson_step.dart';
import '../theme/app_colors.dart';
import '../widgets/app_card.dart';
import '../widgets/mcq_option_tile.dart';
import '../widgets/notes_text.dart';
import '../widgets/practice_quiz_view.dart';
import '../widgets/prompt_view.dart';
import '../widgets/scientific_calculator.dart';

/// Altezza di «Completa la lezione» (padding 14 sopra e sotto più il
/// contenuto). Serve a dare alla toolbar compatta la stessa altezza: il suo
/// FAB collassato è `M3EToolbarTokens.fabMedium`, cioè 80 (da espanso scende a
/// `fabBaseline`, 56).
const double _kFooterControlHeight = 49;

/// Quanto dura la celebrazione a schermo intero: i 71 frame del trofeo a
/// 30fps durano 2.37s, quindi si chiude poco dopo l'ultimo fotogramma.
const Duration _kCelebrationDuration = Duration(milliseconds: 2400);

/// Quanto si deve trascinare a sinistra sull'ultima card per completare la
/// lezione. Sotto questa soglia niente succede, così il gesto non parte
/// mentre si sta ancora scorrendo il testo o le opzioni.
const double _kSwipeCompleteThreshold = 56;

class LessonScreen extends StatefulWidget {
  final Lesson lesson;
  final String? levelId;

  /// Card da cui aprire la lezione: la sezione «Jump Back In» passa qui il
  /// passo lasciato in sospeso. Fuori zero, cioè dal primo passo.
  final int initialStep;

  const LessonScreen({
    super.key,
    required this.lesson,
    this.levelId,
    this.initialStep = 0,
  });

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  late final PageController _pageController;
  late int _page;

  int? _selectedOption;
  final Set<int> _wrongOptions = {};
  bool _solved = false;
  bool _attempted = false;
  int _attemptId = 0;
  bool _calcOpen = false;
  bool _celebrating = false;
  Timer? _celebrationTimer;

  /// La toolbar vive nel footer di ogni card, quindi ce n'è una per pagina
  /// costruita: senza stato condiviso ogni nuova card nascerebbe collassata.
  bool _toolbarExpanded = false;

  /// Quanto la card è tirata a sinistra dal dito, da 0 a 1: a 1 la lezione è
  /// completata. Va in un `ValueNotifier` perché il trascinamento arriva a
  /// ogni `pointerMove` e non deve ricostruire la pagina a ogni frame.
  final ValueNotifier<double> _swipeProgress = ValueNotifier<double>(0);
  late final Listenable _pageAnimations;
  Offset? _swipeStart;

  /// Una chiave per step quiz: il bottone di reload sta nel footer della card,
  /// fuori dal widget che possiede lo stato degli esercizi.
  final Map<int, GlobalKey<PracticeQuizViewState>> _quizKeys = {};

  LessonStep get _step => widget.lesson.steps[_page];
  int get _total => widget.lesson.steps.length;

  @override
  void initState() {
    super.initState();
    _page = _clampStep(widget.initialStep);
    _pageController = PageController(
      viewportFraction: 0.92,
      initialPage: _page,
    );
    _pageAnimations = Listenable.merge([_pageController, _swipeProgress]);
    // Scrive dopo il frame: dalla `initState` la notifica arriverebbe durante
    // la build della nuova rotta e le sezioni in ascolto del progresso si
    // rimarrebbero da costruire mentre il framework sta già costruendo.
    WidgetsBinding.instance.addPostFrameCallback((_) => _rememberResume());
  }

  /// Il passo salvato può eccedere la lunghezza se il contenuto è cambiato
  /// nel frattempo.
  int _clampStep(int step) {
    final total = widget.lesson.steps.length;
    if (total == 0) return 0;
    return step.clamp(0, total - 1);
  }

  /// Scrive il punto di ripresa a ogni cambio di card, non solo all'uscita:
  /// così un kill dell'app non lo perde. Senza `levelId` il completamento non
  /// viene registrato, quindi non ha senso ricordare nulla.
  void _rememberResume() {
    final levelId = widget.levelId;
    if (levelId == null) return;
    unawaited(
      ProgressStore.instance.saveLessonResume(
        LessonResume(levelId: levelId, lessonId: widget.lesson.id, step: _page),
      ),
    );
  }

  @override
  void dispose() {
    _celebrationTimer?.cancel();
    _swipeProgress.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _selectOption(int index) {
    if (_solved || _step.type != LessonStepType.mcq) return;
    setState(() {
      _attempted = true;
      if (index == _step.correctIndex) {
        _selectedOption = index;
        _solved = true;
        HapticFeedback.lightImpact();
      } else {
        _wrongOptions.add(index);
        _attemptId++;
        HapticFeedback.heavyImpact();
      }
    });
  }

  /// Se sulla card `index` si può chiudere la lezione. Vale per il bottone
  /// «Completa la lezione» e per lo swipe verso sinistra: sull'ultima card
  /// serve il vincolo dell'esercizio risolto, sulle altre mai.
  bool _canCompleteAt(int index) {
    final step = widget.lesson.steps[index];
    return index == _total - 1 &&
        (step.type == LessonStepType.info ||
            step.type == LessonStepType.practiceQuiz ||
            _solved);
  }

  /// Trascinamento a sinistra sull'ultima card. Lo guarda un `Listener` e non
  /// un `GestureDetector`: il drag orizzontale della `PageView` vince l'arena
  /// dei gesture, quindi un recognizer esterno non riceverebbe mai il gesto.
  void _trackSwipe(PointerMoveEvent event) {
    final start = _swipeStart;
    if (start == null || _page != _total - 1) return;
    final dx = event.position.dx - start.dx;
    // scorrimento del testo o della card: non è il gesto che completa
    if ((event.position.dy - start.dy).abs() > dx.abs()) return;
    if (dx >= 0) {
      _swipeProgress.value = 0;
      return;
    }
    _swipeProgress.value = (-dx / _kSwipeCompleteThreshold).clamp(0.0, 1.0);
    if (-dx >= _kSwipeCompleteThreshold && _canCompleteAt(_page)) {
      _complete();
    }
  }

  void _endSwipe() {
    _swipeStart = null;
    _swipeProgress.value = 0;
  }

  Future<void> _complete() async {
    if (_celebrating) return;
    final levelId = widget.levelId;
    if (levelId != null &&
        !ProgressStore.instance.isLessonCompleted(levelId, widget.lesson.id)) {
      await ProgressStore.instance.completeLesson(levelId, widget.lesson.id);
      // Completata: non c'è più niente da riprendere, altrimenti la sezione
      // riproporrebbe la stessa lezione appena finita.
      await ProgressStore.instance.clearLessonResume();
    }
    HapticFeedback.mediumImpact();
    if (!mounted) return;
    setState(() => _celebrating = true);
    _celebrationTimer?.cancel();
    _celebrationTimer = Timer(_kCelebrationDuration, _closeCelebration);
  }

  void _closeCelebration() {
    _celebrationTimer?.cancel();
    _celebrationTimer = null;
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  void _resetStep() {
    setState(() {
      _selectedOption = null;
      _wrongOptions.clear();
      _solved = false;
      _attempted = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(widget.lesson.title)),
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Text(
                          '${_page + 1} di $_total',
                          style: TextStyle(
                            fontSize: 13,
                            color: c.textSecondary,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          widget.lesson.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: c.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    M3EProgressIndicator.linearWavy(
                      value: (_page + 1) / _total,
                      color: c.accent,
                      trackColor: c.border,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Listener(
                  onPointerDown: (event) {
                    _swipeStart = event.position;
                    _swipeProgress.value = 0;
                  },
                  onPointerMove: _trackSwipe,
                  onPointerUp: (_) => _endSwipe(),
                  onPointerCancel: (_) => _endSwipe(),
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _total,
                    onPageChanged: (index) {
                      setState(() => _page = index);
                      _resetStep();
                      _rememberResume();
                    },
                    itemBuilder: (context, index) {
                      final step = widget.lesson.steps[index];
                      final card = Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 12,
                        ),
                        child: _StepCard(
                          index: index,
                          step: step,
                          solved: _solved,
                          attempted: _attempted,
                          attemptId: _attemptId,
                          wrongOptions: _wrongOptions,
                          selectedOption: _selectedOption,
                          onSelectOption: _selectOption,
                          showComplete: _canCompleteAt(index),
                          onComplete: _complete,
                          toolbarExpanded: _toolbarExpanded,
                          onToolbarExpandedChanged: (value) =>
                              setState(() => _toolbarExpanded = value),
                          onOpenCalculator: () =>
                              setState(() => _calcOpen = true),
                          practiceQuizKey: step.isPracticeQuiz
                              ? _quizKeys.putIfAbsent(
                                  index,
                                  GlobalKey<PracticeQuizViewState>.new,
                                )
                              : null,
                        ),
                      );
                      return AnimatedBuilder(
                        animation: _pageAnimations,
                        builder: (context, child) {
                          final position = _pageController.hasClients
                              ? _pageController.page ?? index.toDouble()
                              : index.toDouble();
                          final delta = (position - index).clamp(-1.0, 1.0);
                          final abs = delta.abs();
                          final scale = 1 - 0.07 * abs;
                          final opacity = (1 - 0.35 * abs).clamp(0.0, 1.0);
                          final tilt = delta * 0.05;
                          return Opacity(
                            opacity: opacity,
                            child: Transform.translate(
                              offset: Offset(
                                -_kSwipeCompleteThreshold *
                                    _swipeProgress.value,
                                0,
                              ),
                              child: Transform(
                                alignment: Alignment.center,
                                transform: Matrix4.identity()
                                  ..rotateZ(tilt)
                                  ..scaleByDouble(scale, scale, 1.0, 1.0),
                                child: child,
                              ),
                            ),
                          );
                        },
                        child: card,
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
          if (_calcOpen)
            Positioned.fill(
              child: ScientificCalculatorSheet(
                onClose: () => setState(() => _calcOpen = false),
              ),
            ),
          if (_celebrating)
            Positioned.fill(
              child: _TrophyCelebration(onDismiss: _closeCelebration),
            ),
        ],
      ),
    );
  }
}

class _TrophyCelebration extends StatelessWidget {
  final VoidCallback onDismiss;

  const _TrophyCelebration({required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onDismiss,
      child: ColoredBox(
        color: c.background,
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Lottie.asset(
                  'assets/animations/Trophy.json',
                  width: 240,
                  height: 240,
                  fit: BoxFit.contain,
                  repeat: false,
                  errorBuilder: (_, _, _) =>
                      const SizedBox(width: 240, height: 240),
                ),
                const SizedBox(height: 24),
                Text(
                  'Lezione completata!',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: c.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tocca per continuare',
                  style: TextStyle(fontSize: 15, color: c.textSecondary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  final int index;
  final LessonStep step;
  final bool solved;
  final bool attempted;
  final int attemptId;
  final Set<int> wrongOptions;
  final int? selectedOption;
  final ValueChanged<int> onSelectOption;
  final bool showComplete;
  final VoidCallback onComplete;
  final bool toolbarExpanded;
  final ValueChanged<bool> onToolbarExpandedChanged;
  final VoidCallback onOpenCalculator;
  final GlobalKey<PracticeQuizViewState>? practiceQuizKey;

  const _StepCard({
    required this.index,
    required this.step,
    required this.solved,
    required this.attempted,
    required this.attemptId,
    required this.wrongOptions,
    required this.selectedOption,
    required this.onSelectOption,
    required this.showComplete,
    required this.onComplete,
    required this.toolbarExpanded,
    required this.onToolbarExpandedChanged,
    required this.onOpenCalculator,
    this.practiceQuizKey,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final scale = step.fontSizeMultiplier;
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    return AppCard(
      padding: const EdgeInsets.all(24),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        step.title,
                        style: TextStyle(
                          fontSize: 24 * scale,
                          fontWeight: FontWeight.w700,
                          color: c.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (step.type == LessonStepType.info)
                        NotesText(step.content, fontScale: scale)
                      else if (step.isPracticeQuiz)
                        PracticeQuizView(
                          key: practiceQuizKey,
                          exercises: step.exercises,
                          scale: scale,
                        )
                      else ...[
                        NotesText(step.content, fontScale: scale),
                        if (step.prompt.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          PromptView(prompt: step.prompt, fontSize: 18 * scale),
                        ],
                        const SizedBox(height: 24),
                        for (var i = 0; i < step.options.length; i++)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: McqOptionTile(
                              key: ValueKey('option_$i'),
                              label: step.options[i],
                              state: _stateFor(i),
                              enabled: !solved,
                              scale: scale,
                              onTap: () => onSelectOption(i),
                            ),
                          ),
                        const SizedBox(height: 8),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 280),
                          transitionBuilder: (child, animation) =>
                              FadeTransition(opacity: animation, child: child),
                          child: solved
                              ? McqFeedbackCard(
                                  key: const ValueKey('correct'),
                                  correct: true,
                                  message: step.explanation,
                                  scale: scale,
                                )
                              : attempted
                              ? ShakeWidget(
                                  key: ValueKey('wrong-$attemptId'),
                                  child: McqFeedbackCard(
                                    correct: false,
                                    message: 'Non è corretto. Riprova!',
                                    scale: scale,
                                  ),
                                )
                              : const SizedBox.shrink(key: ValueKey('idle')),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Fascia footer alta quanto «Completa la lezione»: la toolbar ci
              // sta sopra (vedi `_toolsBar`), dentro solo reload e bottone.
              Padding(
                padding: EdgeInsets.only(bottom: bottomInset),
                // Altezza minima quella di «Completa la lezione», ma la fascia
                // cresce se il bottone con una font scale più grande la supera.
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minHeight: _kFooterControlHeight,
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // Larghezza già occupata a sinistra: la toolbar dipinta,
                      // il reload (48 più 8 di padding) quando c'è, più un
                      // piccolo scarto perché il bottone non tocchi il FAB.
                      final taken =
                          _kFooterControlHeight +
                          (step.isPracticeQuiz && step.exercises.length > 1
                              ? 56
                              : 0) +
                          8;
                      // «Completa la lezione» per intero: 20 di padding per
                      // lato, icona da 20, 8 di scarto, più il testo misurato.
                      final labelWidth = (TextPainter(
                        text: const TextSpan(
                          text: 'Completa la lezione',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        textDirection: Directionality.of(context),
                        textScaler: MediaQuery.textScalerOf(context),
                      )..layout()).width;
                      final full = 40 + 20 + 8 + labelWidth;
                      return Row(
                        children: [
                          const Spacer(),
                          if (step.isPracticeQuiz && step.exercises.length > 1)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: IconButton(
                                onPressed: () =>
                                    practiceQuizKey?.currentState?.reload(),
                                icon: const Icon(Icons.refresh_rounded),
                                tooltip: 'Altro esercizio',
                                color: c.textSecondary,
                              ),
                            ),
                          if (showComplete)
                            _completeButton(
                              c,
                              compact: constraints.maxWidth - taken < full,
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            left: 0,
            bottom: bottomInset,
            width: M3EToolbarTokens.fabMedium,
            child: _toolsBar(),
          ),
        ],
      ),
    );
  }

  /// Toolbar della lezione: overlay dentro la card, ancorato al suo fondo, con
  /// il FAB compatto della stessa altezza di «Completa la lezione».
  ///
  /// Non sta nella `Row` del footer perché `M3EToolbar` riserva in layout
  /// l'altezza della pila anche da collassato (136px, di cui 80 di FAB) pur
  /// clip-paintandola a zero: in layout ruberebbe 87px a ogni card. E con
  /// larghezza illimitata, come vuole una `Row`, il suo layout verticale va in
  /// `Infinity`: da qui il `width` nella `Positioned`. La scala parte dal basso
  /// a sinistra, così il FAB dipinto è a filo del padding della card e ha lo
  /// stesso spigolo inferiore del bottone, e la pila si rivela in alto.
  Widget _toolsBar() {
    return Transform.scale(
      alignment: Alignment.bottomLeft,
      scale: _kFooterControlHeight / M3EToolbarTokens.fabMedium,
      child: M3EToolbar(
        key: ValueKey('lesson_toolbar_$index'),
        axis: Axis.vertical,
        fabPosition: M3EToolbarFabPosition.bottom,
        expanded: toolbarExpanded,
        onExpandedChanged: onToolbarExpandedChanged,
        fabExpandIcon: const Icon(M3EIcons.handyman_rounded),
        fabCollapseIcon: const Icon(M3EIcons.close_rounded),
        actions: [
          M3EToolbarAction(
            icon: M3EIcons.calculate_rounded,
            tooltip: 'Calcolatrice',
            onPressed: onOpenCalculator,
          ),
        ],
      ),
    );
  }

  Widget _completeButton(AppPalette c, {required bool compact}) {
    final style = FilledButton.styleFrom(
      backgroundColor: c.accent,
      foregroundColor: c.surface,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    );
    if (compact) {
      // Niente spazio per il testo: resta solo l'icona, col testo nel tooltip.
      return Tooltip(
        message: 'Completa la lezione',
        child: FilledButton(
          onPressed: onComplete,
          style: style,
          child: const Icon(Icons.check_circle_outline, size: 20),
        ),
      );
    }
    return FilledButton.icon(
      onPressed: onComplete,
      style: style,
      icon: const Icon(Icons.check_circle_outline, size: 20),
      label: const Text(
        'Completa la lezione',
        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
    );
  }

  McqOptionState _stateFor(int index) {
    if (solved && index == step.correctIndex) return McqOptionState.correct;
    if (wrongOptions.contains(index)) return McqOptionState.wrong;
    if (selectedOption == index) return McqOptionState.selected;
    return McqOptionState.idle;
  }
}
