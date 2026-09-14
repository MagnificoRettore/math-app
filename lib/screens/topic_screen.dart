import 'package:flutter/material.dart';

import '../data/progress_store.dart';
import '../models/course.dart';
import '../models/level.dart';
import '../models/topic.dart';
import '../theme/app_colors.dart';
import '../widgets/topic_row.dart';
import 'exercise_feed_screen.dart';

class TopicScreen extends StatelessWidget {
  final Level level;
  final Course course;

  const TopicScreen({
    super.key,
    required this.level,
    required this.course,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          course.title,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: c.textPrimary,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          if (course.subtitle.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                course.subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: c.textSecondary,
                ),
              ),
            ),
          for (final topic in course.topics)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TopicRow(
                topic: topic,
                progress: _topicProgress(topic),
                onTap: () => _openTopic(context, topic),
              ),
            ),
        ],
      ),
    );
  }

  void _openTopic(BuildContext context, Topic topic) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ExerciseFeedScreen(
          level: level,
          course: course,
          topic: topic,
        ),
      ),
    );
  }

  double _topicProgress(Topic topic) {
    final ids = topic.exercises.map((e) => e.id).toList();
    return ProgressStore.instance.completionFor(ids);
  }
}