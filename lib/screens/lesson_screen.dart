import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

import '../data/progress_store.dart';
import '../models/lesson.dart';
import '../models/lesson_step.dart';
import '../theme/app_colors.dart';
import '../widgets/app_card.dart';
import '../widgets/math_text.dart';
import '../widgets/notes_text.dart';
import '../widgets/scientific_calculator.dart';

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
                    final card = Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 12,
                      ),
                      child: _StepCard(
                        step: widget.lesson.steps[index],
                        solved: _solved,
                        attempted: _attempted,
                        attemptId: _attemptId,
                        wrongOptions: _wrongOptions,
                        selectedOption: _selectedOption,
                        onSelectOption: _selectOption,
                        showComplete:
                            index == _total - 1 &&
                            (_step.type == LessonStepType.info || _solved),
                        onComplete: _complete,
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
          Positioned(
            right: 16,
            bottom: 16,
            child: SafeArea(
              child: Transform.scale(
                scale: 1 / 1.5,
                child: M3EToolbar(
                  expanded: false,
                  fabExpandIcon: const Icon(M3EIcons.handyman_rounded),
                  fabCollapseIcon: const Icon(M3EIcons.close_rounded),
                  actions: [
                    M3EToolbarAction(
                      icon: M3EIcons.calculate_rounded,
                      tooltip: 'Calcolatrice',
                      onPressed: () => setState(() => _calcOpen = true),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_calcOpen)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
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
  final LessonStep step;
  final bool solved;
  final bool attempted;
  final int attemptId;
  final Set<int> wrongOptions;
  final int? selectedOption;
  final ValueChanged<int> onSelectOption;
  final bool showComplete;
  final VoidCallback onComplete;

  const _StepCard({
    required this.step,
    required this.solved,
    required this.attempted,
    required this.attemptId,
    required this.wrongOptions,
    required this.selectedOption,
    required this.onSelectOption,
    required this.showComplete,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final scale = step.fontSizeMultiplier;
    return AppCard(
      padding: const EdgeInsets.all(24),
      child: Column(
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
                  else ...[
                    NotesText(step.content, fontScale: scale),
                    const SizedBox(height: 24),
                    for (var i = 0; i < step.options.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _OptionTile(
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
                          ? _FeedbackCard(
                              key: const ValueKey('correct'),
                              correct: true,
                              message: step.explanation,
                              scale: scale,
                            )
                          : attempted
                          ? _ShakeWidget(
                              key: ValueKey('wrong-$attemptId'),
                              child: _FeedbackCard(
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
          if (showComplete) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onComplete,
                style: FilledButton.styleFrom(
                  backgroundColor: c.accent,
                  foregroundColor: c.surface,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.check_circle_outline, size: 20),
                label: const Text(
                  'Completa la lezione',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  _OptionState _stateFor(int index) {
    if (solved && index == step.correctIndex) return _OptionState.correct;
    if (wrongOptions.contains(index)) return _OptionState.wrong;
    if (selectedOption == index) return _OptionState.selected;
    return _OptionState.idle;
  }
}

enum _OptionState { idle, selected, correct, wrong }

class _OptionTile extends StatelessWidget {
  final String label;
  final _OptionState state;
  final bool enabled;
  final double scale;
  final VoidCallback onTap;

  const _OptionTile({
    super.key,
    required this.label,
    required this.state,
    required this.enabled,
    required this.scale,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final (borderColor, fillColor, iconColor, check) = switch (state) {
      _OptionState.correct => (
        c.easy,
        c.easy.withValues(alpha: 0.12),
        c.easy,
        Icons.check_circle,
      ),
      _OptionState.wrong => (
        c.hard,
        c.hard.withValues(alpha: 0.10),
        c.hard,
        null,
      ),
      _OptionState.selected => (c.accent, c.accentSoft, c.accent, null),
      _OptionState.idle => (c.border, c.surface, c.textSecondary, null),
    };

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: borderColor,
          width: state == _OptionState.correct ? 1.8 : 1.2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Expanded(child: MathText(label, fontSize: 16 * scale)),
                if (check != null) ...[
                  const SizedBox(width: 10),
                  Icon(check, size: 22, color: iconColor),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FeedbackCard extends StatelessWidget {
  final bool correct;
  final String message;
  final double scale;

  const _FeedbackCard({
    super.key,
    required this.correct,
    required this.message,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final color = correct ? c.easy : c.hard;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                correct ? Icons.check_circle : Icons.cancel_outlined,
                color: color,
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                correct ? 'Corretto!' : 'Non è corretto',
                style: TextStyle(
                  fontSize: 16 * scale,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
          if (message.isNotEmpty) ...[
            const SizedBox(height: 8),
            MathText(message, fontSize: 14 * scale),
          ],
        ],
      ),
    );
  }
}

class _ShakeWidget extends StatefulWidget {
  final Widget child;

  const _ShakeWidget({super.key, required this.child});

  @override
  State<_ShakeWidget> createState() => _ShakeWidgetState();
}

class _ShakeWidgetState extends State<_ShakeWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );
  late final Animation<double> _shake = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(
        begin: 0.0,
        end: -12.0,
      ).chain(CurveTween(curve: Curves.easeOut)),
      weight: 2,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: -12.0,
        end: 12.0,
      ).chain(CurveTween(curve: Curves.easeInOut)),
      weight: 4,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: 12.0,
        end: -8.0,
      ).chain(CurveTween(curve: Curves.easeInOut)),
      weight: 3,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: -8.0,
        end: 0.0,
      ).chain(CurveTween(curve: Curves.easeOut)),
      weight: 3,
    ),
  ]).animate(_controller);

  @override
  void initState() {
    super.initState();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) =>
          Transform.translate(offset: Offset(_shake.value, 0), child: child),
      child: widget.child,
    );
  }
}
