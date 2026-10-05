import 'package:flutter/material.dart';

import '../models/course.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import 'app_card.dart';

/// «prima» → «Prima»: i titoli degli anni nei dati sono in minuscolo.
String yearLabel(Course course) => course.title.isEmpty
    ? course.title
    : course.title[0].toUpperCase() + course.title.substring(1);

/// Un anno della scuola scelta, nello stile della scelta della scuola.
class YearTile extends StatelessWidget {
  final Course course;
  final bool selected;
  final VoidCallback onTap;

  const YearTile({
    super.key,
    required this.course,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return AppCard(
      onTap: onTap,
      borderColor: selected ? c.accent : null,
      borderWidth: 3,
      child: Row(
        children: [
          Expanded(
            child: Text(
              yearLabel(course),
              style: TextStyle(
                fontSize: AppText.titleSmall,
                fontWeight: FontWeight.w500,
                color: c.textPrimary,
              ),
            ),
          ),
          Icon(
            selected ? Icons.radio_button_checked : Icons.radio_button_off,
            color: selected ? c.accent : c.textSecondary,
          ),
        ],
      ),
    );
  }
}
