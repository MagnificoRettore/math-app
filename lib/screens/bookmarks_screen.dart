import 'package:flutter/material.dart';

import '../data/content_repository.dart';
import '../data/progress_store.dart';
import '../models/course.dart';
import '../models/exercise.dart';
import '../models/level.dart';
import '../models/topic.dart';
import '../theme/app_colors.dart';
import '../widgets/exercise_card.dart';
import 'exercise_detail_screen.dart';

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: ListenableBuilder(
        listenable: ProgressStore.instance,
        builder: (context, _) {
          final bookmarked = _collectBookmarked();
          if (bookmarked.isEmpty) {
            return const _EmptyBookmarks();
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              for (final entry in bookmarked)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ExerciseCard(
                    exercise: entry.exercise,
                    bookmarked: true,
                    status: ProgressStore.instance.statusOf(entry.exercise.id),
                    onToggleBookmark: (_) => ProgressStore.instance
                        .toggleBookmark(entry.exercise.id),
                    onTap: () => _openExercise(entry),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  List<({Level level, Course course, Topic topic, Exercise exercise})>
  _collectBookmarked() {
    final results =
        <({Level level, Course course, Topic topic, Exercise exercise})>[];
    for (final level in ContentRepository.instance.levels) {
      for (final course in level.courses) {
        for (final topic in course.topics) {
          for (final ex in topic.exercises) {
            if (ProgressStore.instance.isBookmarked(ex.id)) {
              results.add((
                level: level,
                course: course,
                topic: topic,
                exercise: ex,
              ));
            }
          }
        }
      }
    }
    return results;
  }

  void _openExercise(
    ({Level level, Course course, Topic topic, Exercise exercise}) entry,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ExerciseDetailScreen(
          level: entry.level,
          course: entry.course,
          topic: entry.topic,
          exercise: entry.exercise,
        ),
      ),
    );
  }
}

class _EmptyBookmarks extends StatelessWidget {
  const _EmptyBookmarks();

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bookmark_border, size: 56, color: c.textSecondary),
          const SizedBox(height: 12),
          Text(
            'Nessun segnalibro',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Salva gli esercizi per ritrovarli qui.',
            style: TextStyle(fontSize: 13, color: c.textSecondary),
          ),
        ],
      ),
    );
  }
}
