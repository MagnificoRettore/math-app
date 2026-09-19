import 'package:flutter/material.dart';

import '../data/progress_store.dart';
import '../models/course.dart';
import '../models/difficulty.dart';
import '../models/exercise.dart';
import '../models/level.dart';
import '../models/topic.dart';
import '../theme/app_colors.dart';
import '../widgets/exercise_card.dart';
import 'exercise_detail_screen.dart';

class YearExercisesScreen extends StatefulWidget {
  final Level level;
  final Course course;

  const YearExercisesScreen({
    super.key,
    required this.level,
    required this.course,
  });

  @override
  State<YearExercisesScreen> createState() => _YearExercisesScreenState();
}

class _YearExercisesScreenState extends State<YearExercisesScreen> {
  Difficulty? _filter;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: ListenableBuilder(
        listenable: ProgressStore.instance,
        builder: (context, _) {
          final entries = _filter == null
              ? _allEntries()
              : _allEntries()
                    .where((e) => e.exercise.difficulty == _filter)
                    .toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              _buildFilterChips(),
              const SizedBox(height: 12),
              for (final entry in entries)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ExerciseCard(
                    exercise: entry.exercise,
                    bookmarked: ProgressStore.instance.isBookmarked(
                      widget.level.id,
                      entry.exercise.id,
                    ),
                    status: ProgressStore.instance.statusOf(
                      widget.level.id,
                      entry.exercise.id,
                    ),
                    onToggleBookmark: (val) => ProgressStore.instance
                        .toggleBookmark(widget.level.id, entry.exercise.id),
                    onTap: () => _openExercise(entry),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterChips() {
    final c = AppColors.of(context);
    return Row(
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            label: const Text('Tutti'),
            selected: _filter == null,
            onSelected: (_) => setState(() => _filter = null),
            selectedColor: c.accentSoft,
            labelStyle: TextStyle(
              color: _filter == null ? c.accent : c.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        for (final difficulty in Difficulty.values)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              avatar: null,
              label: Text(difficulty.label),
              selected: _filter == difficulty,
              onSelected: (_) => setState(() => _filter = difficulty),
              selectedColor: c.accentSoft,
              labelStyle: TextStyle(
                color: _filter == difficulty ? c.accent : c.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  List<_Entry> _allEntries() {
    return [
      for (final section in widget.course.sections)
        for (final topic in section.topics)
          for (final exercise in topic.exercises)
            _Entry(topic: topic, exercise: exercise),
    ];
  }

  void _openExercise(_Entry entry) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ExerciseDetailScreen(
          level: widget.level,
          course: widget.course,
          topic: entry.topic,
          exercise: entry.exercise,
        ),
      ),
    );
  }
}

class _Entry {
  final Topic topic;
  final Exercise exercise;

  const _Entry({required this.topic, required this.exercise});
}
