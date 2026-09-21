import 'package:flutter/material.dart';

import '../models/topic.dart';
import '../theme/app_colors.dart';
import '../theme/topic_style.dart';
import 'topic_image_card.dart';

class TopicRow extends StatelessWidget {
  final Topic topic;
  final VoidCallback onTap;

  const TopicRow({super.key, required this.topic, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return TopicImageCard(
      title: topic.title,
      image: topic.image,
      color: topicColor(AppColors.of(context), topic.icon),
      onTap: onTap,
    );
  }
}
