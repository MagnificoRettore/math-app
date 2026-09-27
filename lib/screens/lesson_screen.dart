import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

import '../data/progress_store.dart';
import '../models/lesson.dart';
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

class LessonScreen extends StatefulWidget {
  final Lesson lesson;
  final String? levelId;

  const LessonScreen({super.key, required this.lesson, this.levelId});

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  late final PageController _pageController;
  int _page = 0;

  int? _selectedOption;
  final Set<int> _wrongOptions = {};
  bool _solved = false;
  bool _attempted = false;
  int _attemptId = 0;
  bool _calcOpen = false;

  /// La toolbar vive nel footer di ogni card, quindi ce n'è una per pagina
  /// costruita: senza stato condiviso ogni nuova card nascerebbe collassata.
  bool _toolbarExpanded = false;

  /// Una chiave per step quiz: il bottone di reload sta nel footer della card,
  /// fuori dal widget che possiede lo stato degli esercizi.
  final Map<int, GlobalKey<PracticeQuizViewState>> _quizKeys = {};

  LessonStep get _step => widget.lesson.steps[_page];
  int get _total => widget.lesson.steps.length;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.92);
  }

  @override
  void dispose() {
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

  Future<void> _complete() async {
    final levelId = widget.levelId;
    if (levelId != null &&
        !ProgressStore.instance.isLessonCompleted(levelId, widget.lesson.id)) {
      await ProgressStore.instance.completeLesson(levelId, widget.lesson.id);
    }
    HapticFeedback.mediumImpact();
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Lezione completata!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
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
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _total,
                  onPageChanged: (index) {
                    setState(() => _page = index);
                    _resetStep();
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
                        showComplete:
                            index == _total - 1 &&
                            (step.type == LessonStepType.info ||
                                step.type == LessonStepType.practiceQuiz ||
                                _solved),
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
                      animation: _pageController,
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
                          child: Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.identity()
                              ..rotateZ(tilt)
                              ..scaleByDouble(scale, scale, 1.0, 1.0),
                            child: child,
                          ),
                        );
                      },
                      child: card,
                    );
                  },
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
        ],
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
              SizedBox(
                height: _kFooterControlHeight,
                child: Row(
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
                    if (showComplete) _completeButton(c),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            left: 0,
            bottom: 0,
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

  Widget _completeButton(AppPalette c) {
    return FilledButton.icon(
      onPressed: onComplete,
      style: FilledButton.styleFrom(
        backgroundColor: c.accent,
        foregroundColor: c.surface,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
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
