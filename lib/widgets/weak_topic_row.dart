import 'package:flutter/material.dart';

import '../models/weak_topic.dart';
import '../theme/app_colors.dart';
import 'app_card.dart';
import 'progress_bar.dart';

class WeakTopicRow extends StatelessWidget {
  final WeakTopic weakTopic;
  final VoidCallback onTap;

  const WeakTopicRow({super.key, required this.weakTopic, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final icon = _iconFor(weakTopic.topic.icon);
    final color = _colorFor(c, weakTopic.topic.icon);
    final count = weakTopic.needsReviewCount;

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
                        weakTopic.topic.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: c.textPrimary,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: c.medium.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.autorenew, size: 13, color: c.medium),
                          const SizedBox(width: 4),
                          Text(
                            count == 1
                                ? '1 da ripassare'
                                : '$count da ripassare',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: c.medium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '${weakTopic.level.title} · ${weakTopic.course.title}',
                  style: TextStyle(fontSize: 12, color: c.textSecondary),
                ),
                const SizedBox(height: 8),
                ProgressBar(
                  progress: weakTopic.masteredRatio,
                  height: 4,
                  color: c.medium,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Icon(Icons.chevron_right, color: c.textSecondary, size: 20),
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
