import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/progress_store.dart';
import '../data/study_store.dart';
import '../models/course.dart';
import '../models/exercise.dart';
import '../models/level.dart';
import '../models/progress.dart';
import '../models/topic.dart';
import '../theme/app_colors.dart';
import '../widgets/app_card.dart';
import '../widgets/difficulty_badge.dart';
import '../widgets/math_text.dart';
import '../widgets/exercise_tools_bar.dart';
import '../widgets/section_header.dart';

class ExerciseDetailScreen extends StatefulWidget {
  final Level level;
  final Course course;
  final Topic topic;
  final Exercise exercise;

  const ExerciseDetailScreen({
    super.key,
    required this.level,
    required this.course,
    required this.topic,
    required this.exercise,
  });

  @override
  State<ExerciseDetailScreen> createState() => _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends State<ExerciseDetailScreen> {
  bool _hintsExpanded = false;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Scaffold(
      appBar: AppBar(
        actions: [
          ListenableBuilder(
            listenable: ProgressStore.instance,
            builder: (context, _) {
              final bookmarked = ProgressStore.instance.isBookmarked(
                widget.level.id,
                widget.exercise.id,
              );
              return IconButton(
                icon: Icon(
                  bookmarked ? Icons.bookmark : Icons.bookmark_border,
                  color: bookmarked ? c.accent : null,
                ),
                tooltip: 'Segnalibro',
                onPressed: () => ProgressStore.instance.toggleBookmark(
                  widget.level.id,
                  widget.exercise.id,
                ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          ListenableBuilder(
            listenable: ProgressStore.instance,
            builder: (context, _) {
              final status = ProgressStore.instance.statusOf(
                widget.level.id,
                widget.exercise.id,
              );
              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 112),
                children: [
                  _buildMetaRow(),
                  const SizedBox(height: 16),
                  _buildProblem(),
                  if (widget.exercise.formulas.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _buildFormulas(),
                  ],
                  if (widget.exercise.hints.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _buildHints(),
                  ],
                  const SizedBox(height: 24),
                  _buildSolution(title: 'Soluzione'),
                  const SizedBox(height: 24),
                  _buildStatusActions(status),
                ],
              );
            },
          ),
          Positioned(left: 16, bottom: 16, child: ExerciseToolsBar()),
        ],
      ),
    );
  }

  Widget _buildMetaRow() {
    final c = AppColors.of(context);
    return Row(
      children: [
        DifficultyBadge(difficulty: widget.exercise.difficulty),
        const SizedBox(width: 12),
        Text(
          '${widget.level.title} · ${widget.course.title} · ${widget.topic.title}',
          style: TextStyle(fontSize: 13, color: c.textSecondary),
        ),
      ],
    );
  }

  Widget _buildProblem() {
    final c = AppColors.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Problema',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          MathText(widget.exercise.problem, fontSize: 17),
        ],
      ),
    );
  }

  Widget _buildFormulas() {
    final c = AppColors.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Formule chiave',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          for (final formula in widget.exercise.formulas)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: MathText(formula, fontSize: 16),
            ),
        ],
      ),
    );
  }

  Widget _buildHints() {
    final c = AppColors.of(context);
    return AppCard(
      onTap: () => setState(() => _hintsExpanded = !_hintsExpanded),
      color: c.accentSoft,
      borderColor: Colors.transparent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, color: c.accent, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Suggerimenti',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: c.textPrimary,
                  ),
                ),
              ),
              Icon(
                _hintsExpanded
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
                color: c.textSecondary,
              ),
            ],
          ),
          if (_hintsExpanded) ...[
            const SizedBox(height: 12),
            for (final hint in widget.exercise.hints)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: MathText(hint, fontSize: 14),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildSolution({required String title}) {
    final c = AppColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title),
        if (widget.exercise.steps.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Nessun passaggio disponibile.',
              style: TextStyle(color: c.textSecondary),
            ),
          )
        else
          for (final (index, step) in widget.exercise.steps.indexed)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AppCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: c.accentSoft,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: c.accent,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: MathText(
                        step,
                        fontSize: 15,
                        textAlign: TextAlign.left,
                      ),
                    ),
                  ],
                ),
              ),
            ),
      ],
    );
  }

  Widget _buildStatusActions(ExerciseStatus status) {
    final c = AppColors.of(context);
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _StatusButton(
              icon: Icons.check_circle_outline,
              label: 'Assimilato',
              selected: status == ExerciseStatus.mastered,
              selectedColor: c.easy,
              onTap: () => _markStatus(ExerciseStatus.mastered),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatusButton(
              icon: Icons.autorenew,
              label: 'Da ripassare',
              selected: status == ExerciseStatus.needsReview,
              selectedColor: c.medium,
              onTap: () => _markStatus(ExerciseStatus.needsReview),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _markStatus(ExerciseStatus status) async {
    HapticFeedback.selectionClick();
    ProgressStore.instance.setStatus(
      widget.level.id,
      widget.exercise.id,
      status,
    );
    final goalReached = status == ExerciseStatus.mastered
        ? await StudyStore.instance.recordExerciseCompleted(widget.exercise.id)
        : false;
    if (goalReached && mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Obiettivo di oggi raggiunto: 5 esercizi!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }
}

class _StatusButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final Color selectedColor;
  final VoidCallback onTap;

  const _StatusButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.selectedColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final color = selected ? selectedColor : c.textSecondary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? color.withValues(alpha: 0.4) : c.border,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
