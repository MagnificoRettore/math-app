import 'package:flutter/material.dart';

import '../data/content_repository.dart';
import '../models/level.dart';
import '../screens/course_screen.dart';
import '../screens/lesson_list_screen.dart';
import '../theme/app_colors.dart';
import 'school_level_tile.dart';

enum SchoolChoiceDestination { lessons, exercises }

Future<void> showSchoolChoiceSheet(
  BuildContext context, {
  required SchoolChoiceDestination destination,
}) async {
  final levels = ContentRepository.instance.levels;
  final isLessons = destination == SchoolChoiceDestination.lessons;
  final navigator = Navigator.of(context);
  final bottomInset = MediaQuery.of(context).padding.bottom;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      final c = AppColors.of(sheetContext);
      return SafeArea(
        child: Container(
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.fromLTRB(20, 12, 20, bottomInset + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: c.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                isLessons ? 'Lezioni per scuola' : 'Esercizi per scuola',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: c.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                isLessons
                    ? 'Scegli la tua scuola per vedere le lezioni guidate '
                        'pensate per te.'
                    : 'Scegli la tua scuola per accedere agli esercizi '
                        'organizzati per anno e argomento.',
                style: TextStyle(
                  fontSize: 13,
                  color: c.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              for (final level in levels)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SchoolLevelTile(
                    level: level,
                    selected: false,
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      _open(navigator, isLessons, level);
                    },
                  ),
                ),
              Center(
                child: Text(
                  'Se crei un profilo, la tua scuola viene ricordata e questa '
                  'scelta non ti verrà più richiesta.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: c.textSecondary,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

void _open(
  NavigatorState navigator,
  bool isLessons,
  Level level,
) {
  navigator.push(
    MaterialPageRoute(
      builder: (_) => isLessons
          ? LessonListScreen(levelId: level.id, showPill: true)
          : CourseScreen(level: level, showPill: true),
    ),
  );
}