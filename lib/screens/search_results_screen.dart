import 'package:flutter/material.dart';

import '../data/progress_store.dart';
import '../data/search_index.dart';
import '../models/exercise.dart';
import '../models/topic.dart';
import '../theme/app_colors.dart';
import '../widgets/app_card.dart';
import '../widgets/difficulty_badge.dart';
import '../widgets/lesson_card.dart';
import 'exercise_detail_screen.dart';
import 'exercise_feed_screen.dart';
import 'lesson_screen.dart';

class SearchResultsScreen extends StatelessWidget {
  final String query;
  final List<SearchResult> results;

  const SearchResultsScreen({
    super.key,
    required this.query,
    required this.results,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Risultati per "$query"',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: c.textPrimary,
          ),
        ),
      ),
      body: results.isEmpty
          ? Center(
              child: Text(
                'Nessun risultato trovato.',
                style: TextStyle(color: c.textSecondary),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: _buildSections(context),
            ),
    );
  }

  List<Widget> _buildSections(BuildContext context) {
    final topics = results.where((r) => r.type == ResultType.topic).toList();
    final exercises = results
        .where((r) => r.type == ResultType.exercise)
        .toList();
    final lessons = results.where((r) => r.type == ResultType.lesson).toList();

    final children = <Widget>[];
    if (topics.isNotEmpty) {
      children.add(_SectionHeader('Argomenti'));
      for (final result in topics) {
        children.add(_resultWithPadding(context, result));
      }
    }
    if (exercises.isNotEmpty) {
      children.add(_SectionHeader('Esercizi'));
      for (final result in exercises) {
        children.add(_resultWithPadding(context, result));
      }
    }
    if (lessons.isNotEmpty) {
      children.add(_SectionHeader('Lezioni'));
      for (final result in lessons) {
        children.add(_resultWithPadding(context, result));
      }
    }
    return children;
  }

  Widget _resultWithPadding(BuildContext context, SearchResult result) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: _buildResultCard(context, result),
    );
  }

  Widget _buildResultCard(BuildContext context, SearchResult result) {
    final c = AppColors.of(context);
    switch (result.type) {
      case ResultType.topic:
        final topic = result.topic!;
        return AppCard(
          onTap: () => _openTopic(context, result, topic),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                topic.title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: c.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${result.level!.title} · ${result.course!.title}',
                style: TextStyle(fontSize: 13, color: c.textSecondary),
              ),
              const SizedBox(height: 6),
              Text(
                '${topic.subtitle} · ${topic.exercises.length} esercizi',
                style: TextStyle(fontSize: 13, color: c.textSecondary),
              ),
            ],
          ),
        );
      case ResultType.exercise:
        final ex = result.exercise!;
        return AppCard(
          onTap: () => _openExercise(context, result, ex),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      ex.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: c.textPrimary,
                      ),
                    ),
                  ),
                  DifficultyBadge(difficulty: ex.difficulty),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                ex.tags.join(', '),
                style: TextStyle(fontSize: 13, color: c.textSecondary),
              ),
              const SizedBox(height: 4),
              Text(
                '${result.level!.title} · ${result.course!.title} · ${result.topic!.title}',
                style: TextStyle(fontSize: 12, color: c.textSecondary),
              ),
            ],
          ),
        );
      case ResultType.lesson:
        final lesson = result.lesson!;
        return LessonCard(
          lesson: lesson,
          completed: ProgressStore.instance.isLessonCompleted(lesson.id),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => LessonScreen(lesson: lesson)),
          ),
        );
    }
  }

  void _openTopic(BuildContext context, SearchResult result, Topic topic) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ExerciseFeedScreen(
          level: result.level!,
          course: result.course!,
          topic: topic,
        ),
      ),
    );
  }

  void _openExercise(
    BuildContext context,
    SearchResult result,
    Exercise exercise,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ExerciseDetailScreen(
          level: result.level!,
          course: result.course!,
          topic: result.topic!,
          exercise: exercise,
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: c.textSecondary,
        ),
      ),
    );
  }
}
