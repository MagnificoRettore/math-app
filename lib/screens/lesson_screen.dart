import 'package:material_3_expressive/material_3_expressive.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

import '../data/progress_store.dart';
import '../data/study_store.dart';
import '../models/lesson.dart';
import '../models/lesson_step.dart';
import '../theme/app_colors.dart';
import '../widgets/animated_fraction_pie.dart';
import '../widgets/animated_number_line.dart';
import '../widgets/app_card.dart';
import '../widgets/math_text.dart';

class LessonScreen extends StatefulWidget {
  final Lesson lesson;

  const LessonScreen({super.key, required this.lesson});

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  int _stepIndex = 0;
  bool _solved = false;
  bool _attempted = false;
  int _attemptId = 0;

  int? _selectedOption;
  final Set<int> _wrongOptions = {};
  final TextEditingController _inputController = TextEditingController();

  bool _completed = false;

  LessonStep get _step => widget.lesson.steps[_stepIndex];

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  void _selectOption(int index) {
    if (_solved) return;
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

  void _submitInput() {
    setState(() {
      _attempted = true;
      _solved = _step.checkAnswer(_inputController.text);
      if (_solved) {
        HapticFeedback.lightImpact();
      } else {
        _attemptId++;
        HapticFeedback.heavyImpact();
      }
    });
  }

  void _continue() {
    if (_stepIndex >= widget.lesson.steps.length - 1) {
      setState(() => _completed = true);
      ProgressStore.instance.completeLesson(
        widget.lesson.levelId,
        widget.lesson.id,
      );
      StudyStore.instance.recordLessonCompleted();
      HapticFeedback.mediumImpact();
      return;
    }
    setState(() {
      _stepIndex++;
      _solved = false;
      _attempted = false;
      _selectedOption = null;
      _wrongOptions.clear();
      _inputController.clear();
    });
  }

  void _restart() {
    setState(() {
      _stepIndex = 0;
      _solved = false;
      _attempted = false;
      _selectedOption = null;
      _wrongOptions.clear();
      _inputController.clear();
      _completed = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: _completed
          ? _CompletedView(
              lesson: widget.lesson,
              onRestart: _restart,
              onClose: () => Navigator.of(context).pop(),
            )
          : _buildLesson(),
    );
  }

  bool get _isLastStep => _stepIndex >= widget.lesson.steps.length - 1;

  bool get _showFloatingContinue {
    final isInfoStep = _step.type == LessonStepType.info;
    return !_completed && (isInfoStep || _solved);
  }

  Widget _buildLesson() {
    final c = AppColors.of(context);
    final total = widget.lesson.steps.length;
    final isInfoStep = _step.type == LessonStepType.info;
    final progress = (_stepIndex + (_solved || isInfoStep ? 1 : 0)) / total;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        if (widget.lesson.animation != LessonAnimation.none) ...[
          _buildAnimationCard(),
          const SizedBox(height: 20),
        ],
        if (_stepIndex == 0 &&
            widget.lesson.introduction.isNotEmpty &&
            _step.type != LessonStepType.info) ...[
          _buildIntroduction(),
          const SizedBox(height: 20),
        ],
        Row(
          children: [
            Expanded(
              child: Text(
                'Passaggio',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: c.textPrimary,
                ),
              ),
            ),
            Text(
              'Passo ${_stepIndex + 1} di $total · ${(progress * 100).round()}%',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: c.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        M3ESlider.wavy(
          value: progress.clamp(0.0, 1.0),
          enabled: true,
          trackThickness: 16,
          onChanged: (double v) {},
        ),
        const SizedBox(height: 20),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(0.06, 0.08),
                    end: Offset.zero,
                  ).animate(
                    animation.drive(CurveTween(curve: Curves.easeOutCubic)),
                  ),
              child: child,
            ),
          ),
          child: _StepCard(
            key: ValueKey(_stepIndex),
            step: _step,
            solved: _solved,
            attempted: _attempted,
            attemptId: _attemptId,
            wrongOptions: _wrongOptions,
            selectedOption: _selectedOption,
            inputController: _inputController,
            onSelectOption: _selectOption,
            onSubmitInput: _submitInput,
          ),
        ),
      ],
    );
  }

  Widget _buildAnimationCard() {
    final c = AppColors.of(context);
    return AppCard(
      color: c.accentSoft,
      borderColor: Colors.transparent,
      child: Column(
        children: [
          if (widget.lesson.animation == LessonAnimation.pie)
            const AnimatedFractionPie()
          else
            const AnimatedNumberLine(),
          const SizedBox(height: 8),
          Text(
            'Animazione interattiva',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: c.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntroduction() {
    final c = AppColors.of(context);
    final image = widget.lesson.image;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: c.accentSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.lightbulb_outline, color: c.accent, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  widget.lesson.introduction,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: c.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          if (image != null && image.isNotEmpty) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                image,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

enum _OptionState { idle, selected, correct, wrong }

class _StepCard extends StatelessWidget {
  final LessonStep step;
  final bool solved;
  final bool attempted;
  final int attemptId;
  final Set<int> wrongOptions;
  final int? selectedOption;
  final TextEditingController inputController;
  final ValueChanged<int> onSelectOption;
  final VoidCallback onSubmitInput;

  const _StepCard({
    super.key,
    required this.step,
    required this.solved,
    required this.attempted,
    required this.attemptId,
    required this.wrongOptions,
    required this.selectedOption,
    required this.inputController,
    required this.onSelectOption,
    required this.onSubmitInput,
  });

  @override
  Widget build(BuildContext context) {
    if (step.type == LessonStepType.info) {
      return _InfoContent(step: step);
    }
    final c = AppColors.of(context);
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Risolvi',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: c.accent,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 8),
          MathText(step.prompt, fontSize: 18),
          const SizedBox(height: 20),
          if (step.type == LessonStepType.multipleChoice)
            _buildOptions()
          else
            _buildInput(c),
          const SizedBox(height: 16),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            transitionBuilder: (child, animation) =>
                FadeTransition(opacity: animation, child: child),
            child: solved
                ? _FeedbackCard(
                    key: const ValueKey('correct'),
                    correct: true,
                    message: step.explanation,
                  )
                : attempted
                ? _ShakeWidget(
                    key: ValueKey('wrong-$attemptId'),
                    child: _FeedbackCard(
                      correct: false,
                      message: 'Non è corretto. Riprova!',
                    ),
                  )
                : const SizedBox.shrink(key: ValueKey('idle')),
          ),
        ],
      ),
    );
  }

  Widget _buildOptions() {
    return Column(
      children: [
        for (var i = 0; i < step.options.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _OptionTile(
              key: ValueKey('option_$i'),
              label: step.options[i],
              state: _stateFor(i),
              enabled: !solved,
              onTap: () => onSelectOption(i),
            ),
          ),
      ],
    );
  }

  _OptionState _stateFor(int index) {
    if (solved && index == step.correctIndex) return _OptionState.correct;
    if (wrongOptions.contains(index)) return _OptionState.wrong;
    if (selectedOption == index) return _OptionState.selected;
    return _OptionState.idle;
  }

  Widget _buildInput(AppPalette c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: inputController,
          keyboardType: step.type == LessonStepType.numeric
              ? const TextInputType.numberWithOptions(decimal: true)
              : TextInputType.text,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => onSubmitInput(),
          style: TextStyle(fontSize: 17, color: c.textPrimary),
          decoration: InputDecoration(
            hintText: step.type == LessonStepType.numeric
                ? 'Inserisci un numero'
                : 'Scrivi la risposta',
            hintStyle: TextStyle(color: c.textSecondary, fontSize: 15),
            filled: true,
            fillColor: c.surface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: c.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: c.accent, width: 1.6),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: c.accent,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: onSubmitInput,
            child: const Text(
              'Controlla',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoContent extends StatelessWidget {
  final LessonStep step;

  const _InfoContent({required this.step});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: c.accentSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.lightbulb_outline, color: c.accent, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Definizione',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: c.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          MathText(step.prompt, fontSize: 16),
          if (step.numberLine != null) ...[
            const SizedBox(height: 20),
            _ModuloNumberLine(spec: step.numberLine!),
          ],
          if (step.formula.isNotEmpty) ...[
            const SizedBox(height: 20),
            _FormulaCallout(formula: step.formula),
          ],
          if (step.examples.isNotEmpty) ...[
            const SizedBox(height: 20),
            Row(
              children: [
                for (final (i, example) in step.examples.indexed) ...[
                  if (i > 0) const SizedBox(width: 12),
                  Expanded(child: _ExampleCard(example: example)),
                ],
              ],
            ),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _FormulaCallout extends StatelessWidget {
  final String formula;

  const _FormulaCallout({required this.formula});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: c.accentSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.accent.withValues(alpha: 0.25)),
      ),
      child: Center(child: MathText(formula, fontSize: 17)),
    );
  }
}

class _ExampleCard extends StatelessWidget {
  final LessonExample example;

  const _ExampleCard({required this.example});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final color = example.positive ? c.easy : c.medium;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: MathText(example.expression, fontSize: 17),
          ),
          if (example.note.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              example.note,
              style: TextStyle(
                fontSize: 12,
                height: 1.35,
                color: c.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ModuloNumberLine extends StatelessWidget {
  final NumberLineSpec spec;

  const _ModuloNumberLine({required this.spec});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return SizedBox(
      height: 100,
      width: double.infinity,
      child: CustomPaint(
        painter: _ModuloLinePainter(
          spec: spec,
          axisColor: c.border,
          textColor: c.textSecondary,
          highlight: c.accent,
        ),
      ),
    );
  }
}

class _ModuloLinePainter extends CustomPainter {
  final NumberLineSpec spec;
  final Color axisColor;
  final Color textColor;
  final Color highlight;

  _ModuloLinePainter({
    required this.spec,
    required this.axisColor,
    required this.textColor,
    required this.highlight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final left = 16.0;
    final right = size.width - 16;
    final axisY = size.height * 0.72;
    double xFor(double v) =>
        left + (v - spec.min) / (spec.max - spec.min) * (right - left);

    final axis = Paint()
      ..color = axisColor
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(left, axisY), Offset(right, axisY), axis);

    final tick = Paint()
      ..color = axisColor
      ..strokeWidth = 1.4;
    for (var v = spec.min; v <= spec.max; v++) {
      final x = xFor(v.toDouble());
      canvas.drawLine(Offset(x, axisY - 4), Offset(x, axisY + 4), tick);
    }

    final zeroX = xFor(0);
    _label(canvas, '0', Offset(zeroX, axisY + 8), textColor, fontSize: 11);

    final segment = Paint()
      ..color = highlight.withValues(alpha: 0.30)
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    final dot = Paint()..color = highlight;

    for (final v in spec.values) {
      final x = xFor(v.toDouble());
      canvas.drawLine(Offset(zeroX, axisY), Offset(x, axisY), segment);
      canvas.drawCircle(Offset(x, axisY), 5, dot);
      _label(
        canvas,
        v.abs().toString(),
        Offset((zeroX + x) / 2, axisY - 34),
        highlight,
        fontSize: 14,
        bold: true,
      );
      _label(
        canvas,
        v < 0 ? '−${v.abs()}' : '$v',
        Offset(x, axisY + 8),
        textColor,
        fontSize: 11,
      );
    }
  }

  void _label(
    Canvas canvas,
    String text,
    Offset anchor,
    Color color, {
    double fontSize = 11,
    bool bold = false,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: fontSize,
          color: color,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      Offset(anchor.dx - painter.width / 2, anchor.dy),
    );
  }

  @override
  bool shouldRepaint(_ModuloLinePainter old) =>
      old.spec.min != spec.min ||
      old.spec.max != spec.max ||
      old.spec.values != spec.values ||
      old.axisColor != axisColor ||
      old.textColor != textColor ||
      old.highlight != highlight;
}

class _OptionTile extends StatelessWidget {
  final String label;
  final _OptionState state;
  final bool enabled;
  final VoidCallback onTap;

  const _OptionTile({
    super.key,
    required this.label,
    required this.state,
    required this.enabled,
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
                Expanded(child: MathText(label, fontSize: 15)),
                if (check != null) ...[
                  const SizedBox(width: 10),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    transitionBuilder: (child, animation) =>
                        ScaleTransition(scale: animation, child: child),
                    child: Icon(
                      check,
                      key: ValueKey(check),
                      size: 22,
                      color: iconColor,
                    ),
                  ),
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

  const _FeedbackCard({
    super.key,
    required this.correct,
    required this.message,
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
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(fontSize: 14, height: 1.4, color: c.textPrimary),
          ),
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

class _CompletedView extends StatelessWidget {
  final Lesson lesson;
  final VoidCallback onRestart;
  final VoidCallback onClose;

  const _CompletedView({
    required this.lesson,
    required this.onRestart,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const SizedBox(height: 24),
            const _Celebration(),
            const SizedBox(height: 28),
            Text(
              'Lezione completata!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: c.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              lesson.completionMessage.isEmpty
                  ? 'Ottimo lavoro!'
                  : lesson.completionMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                height: 1.45,
                color: c.textSecondary,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: c.accent,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: onClose,
                icon: const Icon(Icons.menu_book_outlined, size: 20),
                label: const Text(
                  'Torna alle lezioni',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: onRestart,
              child: Text(
                'Ripeti la lezione',
                style: TextStyle(color: c.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Celebration extends StatelessWidget {
  const _Celebration();

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        const _ConfettiBurst(),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          curve: Curves.elasticOut,
          duration: const Duration(milliseconds: 700),
          builder: (context, value, child) =>
              Transform.scale(scale: value, child: child),
          child: Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: c.accentSoft,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.emoji_events_outlined, color: c.accent, size: 52),
          ),
        ),
      ],
    );
  }
}

class _ConfettiBurst extends StatefulWidget {
  const _ConfettiBurst();

  @override
  State<_ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends State<_ConfettiBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..forward();

  static const _positions = [
    (dx: -0.42, dy: 0.16),
    (dx: 0.40, dy: 0.12),
    (dx: -0.30, dy: -0.10),
    (dx: 0.32, dy: -0.14),
    (dx: -0.12, dy: -0.24),
    (dx: 0.14, dy: -0.28),
    (dx: -0.48, dy: 0.02),
    (dx: 0.46, dy: 0.02),
    (dx: 0.0, dy: -0.30),
    (dx: -0.20, dy: 0.22),
    (dx: 0.22, dy: 0.22),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      height: 260,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => Stack(
          alignment: Alignment.center,
          children: [
            for (final (i, pos) in _positions.indexed) _dot(i, pos.dx, pos.dy),
          ],
        ),
      ),
    );
  }

  Widget _dot(int index, double dx, double dy) {
    final c = AppColors.of(context);
    final t = CurvedAnimation(
      parent: _controller,
      curve: Interval(
        index * 0.045,
        0.55 + index * 0.04,
        curve: Curves.easeOutCubic,
      ),
    ).value;
    final travel = 84.0 * t + 26.0;
    final color = c.iconPalette[index % c.iconPalette.length];
    return Positioned(
      left: 130 + dx * 260,
      top: 130 + dy * 260 - travel,
      child: Opacity(
        opacity: (1 - t).clamp(0.0, 1.0),
        child: Transform.rotate(
          angle: t * 6.28 * (index.isEven ? 1 : -1),
          child: Container(
            width: 10,
            height: 18,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
      ),
    );
  }
}
