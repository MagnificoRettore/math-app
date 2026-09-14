import 'package:flutter/material.dart';

import '../models/topic.dart';
import '../theme/app_colors.dart';
import 'app_card.dart';
import 'progress_bar.dart';

class TopicRow extends StatelessWidget {
  final Topic topic;
  final VoidCallback onTap;
  final double progress;

  const TopicRow({
    super.key,
    required this.topic,
    required this.onTap,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final icon = _iconFor(topic.icon);
    final color = _colorFor(c, topic.icon);

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        topic.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: c.textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      '${topic.exercises.length}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: c.textSecondary,
                      ),
                    ),
                  ],
                ),
                if (topic.subtitle.isNotEmpty) ...[
                  const SizedBox(height: 1),
                  Text(
                    topic.subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: c.textSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                ProgressBar(progress: progress, height: 4, color: c.accent),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Icon(Icons.chevron_right,
              color: c.textSecondary, size: 20),
        ],
      ),
    );
  }

  IconData _iconFor(String name) {
    switch (name) {
      case 'pie_chart':
        return Icons.pie_chart_outline;
      case 'functions':
        return Icons.functions;
      case 'tag':
        return Icons.tag;
      case 'trending_up':
        return Icons.trending_up;
      case 'show_chart':
        return Icons.show_chart;
      case 'calculate':
        return Icons.calculate_outlined;
      case 'grid_on':
        return Icons.grid_on_outlined;
      case 'casino':
        return Icons.casino_outlined;
      case 'account_tree':
        return Icons.account_tree_outlined;
      default:
        return Icons.menu_book_outlined;
    }
  }

  Color _colorFor(AppPalette c, String name) {
    switch (name) {
      case 'pie_chart':
        return c.pink;
      case 'functions':
        return c.accent;
      case 'tag':
        return c.medium;
      case 'trending_up':
        return c.easy;
      case 'show_chart':
        return c.teal;
      case 'calculate':
        return c.purple;
      case 'grid_on':
        return c.indigo;
      case 'casino':
        return c.pink;
      case 'account_tree':
        return c.teal;
      default:
        return c.accent;
    }
  }
}