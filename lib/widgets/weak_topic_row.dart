import 'package:flutter/material.dart';

import '../models/weak_topic.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import 'app_card.dart';
import 'progress_bar.dart';

/// Una riga della lista dei punti deboli.
///
/// [inGroup] dice se la riga sta dentro una card che ne contiene altre: in quel
/// caso la riga non porta bordo, ombra e raggio suoi, sennò la lista si legge
/// come una pila di card dentro una card. [rank] è il numero in testa, la
/// posizione nella lista.
class WeakTopicRow extends StatelessWidget {
  final WeakTopic weakTopic;
  final VoidCallback onTap;
  final bool inGroup;
  final int? rank;

  const WeakTopicRow({
    super.key,
    required this.weakTopic,
    required this.onTap,
    this.inGroup = false,
    this.rank,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final icon = _iconFor(weakTopic.topic.icon);
    final color = _colorFor(c, weakTopic.topic.icon);
    final ratio = weakTopic.masteredRatio;

    final row = Row(
      children: [
        if (rank != null)
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$rank',
              style: TextStyle(
                fontSize: AppText.bodyMedium,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          )
        else
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                weakTopic.topic.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: AppText.bodyLarge,
                  fontWeight: FontWeight.w500,
                  color: c.textPrimary,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '${weakTopic.level.title} · ${weakTopic.course.title}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: AppText.caption,
                  color: c.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              ProgressBar(progress: ratio, height: 4, color: c.medium),
            ],
          ),
        ),
        const SizedBox(width: 10),
        if (ratio >= 1.0)
          Icon(Icons.check_circle_rounded, size: 22, color: c.easy)
        else ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: c.medium.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${(ratio * 100).round()}%',
              style: TextStyle(
                fontSize: AppText.micro,
                fontWeight: FontWeight.w500,
                color: c.medium,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Icon(Icons.chevron_right, color: c.textSecondary, size: 20),
        ],
      ],
    );

    if (inGroup) {
      return InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: row,
        ),
      );
    }

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: row,
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
