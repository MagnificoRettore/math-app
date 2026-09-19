import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/progress_store.dart';
import '../data/weak_topic_engine.dart';
import '../models/weak_topic.dart';
import '../theme/app_colors.dart';
import '../widgets/app_card.dart';
import '../widgets/exercise_card.dart';
import '../widgets/lesson_card.dart';
import '../widgets/progress_bar.dart';
import '../widgets/section_header.dart';
import 'exercise_detail_screen.dart';
import 'lesson_screen.dart';

class WeakTopicScreen extends StatefulWidget {
  final WeakTopic weakTopic;

  const WeakTopicScreen({super.key, required this.weakTopic});

  @override
  State<WeakTopicScreen> createState() => _WeakTopicScreenState();
}

class _WeakTopicScreenState extends State<WeakTopicScreen> {
  bool _celebrated = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: ListenableBuilder(
        listenable: ProgressStore.instance,
        builder: (context, _) {
          final current = WeakTopicEngine.weakTopicFor(
            widget.weakTopic.topic.id,
          );

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted || _celebrated) return;
            if (current == null && widget.weakTopic.needsReviewCount > 0) {
              _celebrated = true;
              HapticFeedback.mediumImpact();
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  const SnackBar(
                    content: Text('Punto debole risolto!'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
            }
          });

          if (current == null) return const _AllMasteredView();

          final lessons = WeakTopicEngine.lessonsForTopic(current.topic.id);
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              _buildBreadcrumb(current),
              const SizedBox(height: 12),
              _buildProgressCard(current),
              if (lessons.isNotEmpty) ...[
                const SizedBox(height: 8),
                SectionHeader('Ripassa'),
                for (final lesson in lessons)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: LessonCard(
                      lesson: lesson,
                      completed: false,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => LessonScreen(lesson: lesson),
                        ),
                      ),
                    ),
                  ),
              ],
              const SizedBox(height: 8),
              SectionHeader('Da ripassare'),
              for (final location in current.weakExercises)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: ExerciseCard(
                    exercise: location.exercise,
                    bookmarked: ProgressStore.instance.isBookmarked(
                      current.level.id,
                      location.exercise.id,
                    ),
                    status: ProgressStore.instance.statusOf(
                      current.level.id,
                      location.exercise.id,
                    ),
                    onToggleBookmark: (_) => ProgressStore.instance
                        .toggleBookmark(current.level.id, location.exercise.id),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ExerciseDetailScreen(
                          level: current.level,
                          course: current.course,
                          topic: current.topic,
                          exercise: location.exercise,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBreadcrumb(WeakTopic current) {
    final c = AppColors.of(context);
    return Text(
      '${current.level.title} · ${current.course.title}',
      style: TextStyle(fontSize: 13, color: c.textSecondary),
    );
  }

  Widget _buildProgressCard(WeakTopic current) {
    final c = AppColors.of(context);
    final total = current.topic.exercises.length;
    final mastered = (current.masteredRatio * total).round().clamp(0, total);
    final toReview = current.needsReviewCount;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.trending_up, color: c.medium, size: 20),
              const SizedBox(width: 8),
              Text(
                'Progresso',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: c.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                toReview == 1 ? '1 da ripassare' : '$toReview da ripassare',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: c.medium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ProgressBar(
            progress: current.masteredRatio,
            height: 6,
            color: c.medium,
          ),
          const SizedBox(height: 10),
          Text(
            '$mastered di $total assimilati',
            style: TextStyle(fontSize: 13, color: c.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _AllMasteredView extends StatelessWidget {
  const _AllMasteredView();

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.task_alt, size: 52, color: c.easy),
            const SizedBox(height: 12),
            Text(
              'Punto debole risolto!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: c.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tutti gli esercizi di questo argomento sono assimilati.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: c.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
