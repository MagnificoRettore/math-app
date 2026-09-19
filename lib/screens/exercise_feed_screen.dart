import 'package:flutter/material.dart';

import '../data/progress_store.dart';
import '../models/course.dart';
import '../models/difficulty.dart';
import '../models/exercise.dart';
import '../models/level.dart';
import '../models/topic.dart';
import '../theme/app_colors.dart';
import '../theme/topic_style.dart';
import '../widgets/exercise_card.dart';
import '../widgets/topic_background.dart';
import 'exercise_detail_screen.dart';

class ExerciseFeedScreen extends StatefulWidget {
  final Level level;
  final Course course;
  final Topic topic;

  const ExerciseFeedScreen({
    super.key,
    required this.level,
    required this.course,
    required this.topic,
  });

  @override
  State<ExerciseFeedScreen> createState() => _ExerciseFeedScreenState();
}

class _ExerciseFeedScreenState extends State<ExerciseFeedScreen> {
  Difficulty? _filter;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListenableBuilder(
        listenable: ProgressStore.instance,
        builder: (context, _) {
          final exercises = _filter == null
              ? widget.topic.exercises
              : widget.topic.exercises
                    .where((e) => e.difficulty == _filter)
                    .toList();

          return ListView(
            padding: EdgeInsets.zero,
            children: [
              TopicHeader(
                title: widget.topic.title,
                subtitle: widget.topic.subtitle.isEmpty
                    ? null
                    : widget.topic.subtitle,
                image: widget.topic.image,
                color: topicColor(c, widget.topic.icon),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFilterChips(),
                    const SizedBox(height: 12),
                    for (final exercise in exercises)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: ExerciseCard(
                          exercise: exercise,
                          bookmarked: ProgressStore.instance.isBookmarked(
                            widget.level.id,
                            exercise.id,
                          ),
                          status: ProgressStore.instance.statusOf(
                            widget.level.id,
                            exercise.id,
                          ),
                          onToggleBookmark: (val) => ProgressStore.instance
                              .toggleBookmark(widget.level.id, exercise.id),
                          onTap: () => _openExercise(exercise),
                        ),
                      ),
                  ],
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

  void _openExercise(Exercise exercise) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ExerciseDetailScreen(
          level: widget.level,
          course: widget.course,
          topic: widget.topic,
          exercise: exercise,
        ),
      ),
    );
  }
}
