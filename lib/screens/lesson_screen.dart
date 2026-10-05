import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

import '../data/auth_store.dart';
import '../data/progress_store.dart';
import '../haptics.dart';
import '../models/lesson.dart';
import '../models/lesson_resume.dart';
import '../models/lesson_step.dart';
import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import '../theme/app_text.dart';
import '../widgets/app_button.dart';
import '../widgets/app_card.dart';
import '../widgets/mcq_option_tile.dart';
import '../widgets/shake.dart';
import '../widgets/notes_text.dart';
import '../widgets/practice_quiz_view.dart';
import '../widgets/prompt_view.dart';
import '../widgets/scientific_calculator.dart';
import '../widgets/tools_bar.dart';

/// Altezza di «Completa la lezione» e della toolbar compatta: la stessa.
/// L'altezza dei bottoni del piede della lezione (con il gradino). La toolbar
/// è più grande (`kToolsBarHeight`) e cresce in alto dallo stesso spigolo.
const double _kFooterControlHeight = 49;

/// La `PageView` mostra il 92% della larghezza: si intravedono le card vicine.
const double _kViewportFraction = 0.92;

/// Margini della card nella sua pagina: 4 ai lati, 12 sopra e sotto, più i 12
/// sotto la `PageView`.
const double _kCardSideMargin = 4;
const double _kCardGapBottom = 12;

/// Padding interno della card: anche la colonna di testo a cui si allineano i
/// bottoni galleggianti.
const double _kCardPadding = 24;

/// Dal fondo dello schermo al fondo dei bottoni galleggianti: dove stava il
/// piede della card, cioè i due 12 sotto la card più il suo padding.
const double _kCardControlsBottom = 2 * _kCardGapBottom + _kCardPadding;

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

  /// Se la toolbar degli strumenti è aperta: resta com'è cambiando card,
  /// perché la toolbar galleggia sopra le card ed è una sola.
  bool _toolbarExpanded = false;

  /// Quanto la card è tirata a sinistra dal dito, da 0 a 1: a 1 la lezione è
  /// completata. Va in un `ValueNotifier` perché il trascinamento arriva a
  /// ogni `pointerMove` e non deve ricostruire la pagina a ogni frame.
  final ValueNotifier<double> _swipeProgress = ValueNotifier<double>(0);
  late final Listenable _pageAnimations;
  Offset? _swipeStart;

  /// Una chiave per step quiz: il bottone di reload galleggia sopra le card,
  /// fuori dal widget che possiede lo stato degli esercizi.
  final Map<int, GlobalKey<PracticeQuizViewState>> _quizKeys = {};

  LessonStep get _step => widget.lesson.steps[_page];
  int get _total => widget.lesson.steps.length;

  @override
  void initState() {
    super.initState();
    _page = _clampStep(widget.initialStep);
    _pageController = PageController(
      viewportFraction: _kViewportFraction,
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

  /// Se la lezione è della scuola che l'utente ha scelto come propria.
  ///
  /// Il punto di ripresa è uno solo (`lessons_in_progress_v1`) e vale per il
  /// profilo: una lezione aperta per dare un'occhiata a un'altra scuola non
  /// deve cancellare la ripresa di quella di casa, sennò «Jump Back In»
  /// sparisce dalla home e l'utente non sa più dove era.
  bool get _isOwnLevel {
    final levelId = widget.levelId;
    if (levelId == null) return false;
    return AuthStore.instance.currentUser?.schoolLevelId == levelId;
  }

  /// Scrive il punto di ripresa a ogni cambio di card, non solo all'uscita:
  /// così un kill dell'app non lo perde. Senza `levelId` il completamento non
  /// viene registrato, quindi non ha senso ricordare nulla, e su una scuola in
  /// visita il ricordo toccherebbe quello della scuola del profilo.
  void _rememberResume() {
    final levelId = widget.levelId;
    if (levelId == null || !_isOwnLevel) return;
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
        AppHaptics.lightImpact();
      } else {
        _wrongOptions.add(index);
        _attemptId++;
        AppHaptics.heavyImpact();
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
      // Il completamento si registra anche per una scuola in visita: la
      // progressione è già scoping per livello (`ProgressStore.scopedKey`) e
      // quella lezione è davvero stata fatta. La ripresa invece no, perché è
      // una sola e appartiene alla scuola del profilo.
      await ProgressStore.instance.completeLesson(levelId, widget.lesson.id);
      if (_isOwnLevel) {
        // Completata: non c'è più niente da riprendere, altrimenti la sezione
        // riproporrebbe la stessa lezione appena finita.
        await ProgressStore.instance.clearLessonResume();
      }
    }
    AppHaptics.mediumImpact();
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

  /// I bottoni della lezione, in sovraimpressione sulle card e fermi mentre
  /// le card scorrono: la toolbar degli strumenti a sinistra, il reload della
  /// verifica e «Completa la lezione» a destra. Stanno dove stava il piede
  /// della card ferma, a filo della colonna di testo.
  ///
  /// Ognuno c'è solo dove serve, per la card corrente ([_page]): il reload
  /// sulle verifiche con più di un esercizio, «Completa la lezione» quando
  /// [_canCompleteAt]. Comparendo e sparendo si dissolvono e scalano in
  /// [AppMotion.medium]; col movimento ridotto cambiano e basta.
  Widget _floatingControls(AppPalette c) {
    final step = widget.lesson.steps[_page];
    final showReload = step.isPracticeQuiz && step.exercises.length > 1;
    final showComplete = _canCompleteAt(_page);
    final bottom =
        _kCardControlsBottom + MediaQuery.viewPaddingOf(context).bottom;
    final duration = AppMotion.duration(context, AppMotion.medium);

    Widget appear(String key, bool visible, Widget child) => AnimatedSwitcher(
      duration: duration,
      switchInCurve: AppMotion.standard,
      switchOutCurve: AppMotion.standard,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.8, end: 1).animate(animation),
          child: child,
        ),
      ),
      child: visible
          ? KeyedSubtree(key: ValueKey('$key-$_page'), child: child)
          : SizedBox.shrink(key: ValueKey('$key-none')),
    );

    return Positioned.fill(
      child: LayoutBuilder(
        builder: (context, constraints) {
          // La colonna di testo della card ferma: il margine della `PageView`
          // (4% per lato con `viewportFraction` 0.92), quello della card e il
          // suo padding interno.
          final inner =
              constraints.maxWidth * (1 - _kViewportFraction) / 2 +
              _kCardSideMargin +
              _kCardPadding;
          return Stack(
            children: [
              Positioned(
                left: inner,
                right: inner,
                bottom: bottom,
                child: Row(
                  children: [
                    // Lo spazio della toolbar, che sta qui sotto da sola.
                    const SizedBox(width: kToolsBarHeight + 8),
                    const Spacer(),
                    appear(
                      'reload',
                      showReload,
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: AppButton(
                          icon: Icons.refresh_rounded,
                          tooltip: 'Altro esercizio',
                          variant: AppButtonVariant.outline,
                          height: _kFooterControlHeight - AppButton.depth,
                          onPressed: () =>
                              _quizKeys[_page]?.currentState?.reload(),
                        ),
                      ),
                    ),
                    appear(
                      'complete',
                      showComplete,
                      _completeButton(
                        compact: _completeDoesNotFit(
                          context,
                          constraints.maxWidth - 2 * inner,
                          showReload,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: inner,
                bottom: bottom,
                width: M3EToolbarTokens.fabMedium,
                child: _toolsBar(),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Se «Completa la lezione» per intero non ci sta in [width] accanto alla
  /// toolbar e, quando c'è, al reload: allora resta solo l'icona.
  bool _completeDoesNotFit(BuildContext context, double width, bool reload) {
    // Larghezza già occupata a sinistra: la toolbar dipinta, il reload (44
    // più 8 di scarto) quando c'è, più un piccolo scarto perché il bottone
    // non tocchi il FAB.
    final taken = kToolsBarHeight + (reload ? 52 : 0) + 8;
    // «Completa la lezione» per intero: 20 di padding per lato, icona da 20,
    // 8 di scarto, più il testo misurato.
    final painter = TextPainter(
      text: const TextSpan(
        text: 'Completa la lezione',
        style: TextStyle(
          fontSize: AppText.bodyLarge,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    final full = 40 + 20 + 8 + painter.width;
    painter.dispose();
    return width - taken < full;
  }

  /// Toolbar della lezione: la stessa degli esercizi (`AppToolsBar`). Sta in una
  /// `Positioned` sua e non nella `Row` dei bottoni: vedi il suo commento.
  Widget _toolsBar() {
    return AppToolsBar(
      toolbarKey: const ValueKey('lesson_toolbar'),
      expanded: _toolbarExpanded,
      onExpandedChanged: (value) => setState(() => _toolbarExpanded = value),
      onCalculator: () => setState(() => _calcOpen = true),
    );
  }

  Widget _completeButton({required bool compact}) {
    // Faccia da 44 più il gradino: insieme fanno l'altezza della toolbar.
    const height = _kFooterControlHeight - AppButton.depth;
    if (compact) {
      // Niente spazio per il testo: resta solo l'icona, col testo nel tooltip.
      return AppButton(
        icon: Icons.check_circle_outline,
        tooltip: 'Completa la lezione',
        height: height,
        onPressed: _complete,
      );
    }
    return AppButton(
      label: 'Completa la lezione',
      icon: Icons.check_circle_outline,
      height: height,
      onPressed: _complete,
    );
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
                            fontSize: AppText.label,
                            color: c.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Il titolo lungo cede spazio invece di sforare.
                        Expanded(
                          child: Text(
                            widget.lesson.title,
                            textAlign: TextAlign.end,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: AppText.label,
                              color: c.textSecondary,
                            ),
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
                          horizontal: _kCardSideMargin,
                          vertical: _kCardGapBottom,
                        ),
                        child: _StepCard(
                          step: step,
                          solved: _solved,
                          attempted: _attempted,
                          attemptId: _attemptId,
                          wrongOptions: _wrongOptions,
                          selectedOption: _selectedOption,
                          onSelectOption: _selectOption,
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
              const SizedBox(height: _kCardGapBottom),
            ],
          ),
          _floatingControls(c),
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
                    fontFamily: AppText.headingFont,
                    fontSize: AppText.title,
                    fontWeight: FontWeight.w600,
                    color: c.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tocca per continuare',
                  style: TextStyle(
                    fontSize: AppText.bodyLarge,
                    color: c.textSecondary,
                  ),
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
  final LessonStep step;
  final bool solved;
  final bool attempted;
  final int attemptId;
  final Set<int> wrongOptions;
  final int? selectedOption;
  final ValueChanged<int> onSelectOption;
  final GlobalKey<PracticeQuizViewState>? practiceQuizKey;

  const _StepCard({
    required this.step,
    required this.solved,
    required this.attempted,
    required this.attemptId,
    required this.wrongOptions,
    required this.selectedOption,
    required this.onSelectOption,
    this.practiceQuizKey,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final scale = step.fontSizeMultiplier;
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    return AppCard(
      bordered: false,
      padding: const EdgeInsets.all(_kCardPadding),
      child: SizedBox.expand(
        child: SingleChildScrollView(
          // I bottoni galleggiano sul fondo della card: il testo può
          // scorrere fin sopra di loro, non finire sotto.
          padding: EdgeInsets.only(bottom: 16 + kToolsBarHeight + bottomInset),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                step.title,
                style: TextStyle(
                  fontFamily: AppText.headingFont,
                  fontSize: AppText.headline * scale,
                  fontWeight: FontWeight.w600,
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
                  PromptView(
                    prompt: step.prompt,
                    fontSize: AppText.titleMedium * scale,
                  ),
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
    );
  }

  McqOptionState _stateFor(int index) {
    if (solved && index == step.correctIndex) return McqOptionState.correct;
    if (wrongOptions.contains(index)) return McqOptionState.wrong;
    if (selectedOption == index) return McqOptionState.selected;
    return McqOptionState.idle;
  }
}
