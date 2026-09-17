import 'package:flutter/material.dart';

import '../data/auth_store.dart';
import '../data/content_repository.dart';
import '../screens/course_screen.dart';
import '../screens/lesson_list_screen.dart';
import '../screens/profile_screen.dart';
import '../theme/app_colors.dart';
import 'school_choice_sheet.dart';

enum PillTab { home, lessons, exercises, profile }

void navigateToTab(BuildContext context, PillTab tab) {
  final navigator = Navigator.of(context);
  final user = AuthStore.instance.currentUser;

  switch (tab) {
    case PillTab.home:
      navigator.popUntil((route) => route.isFirst);
    case PillTab.profile:
      navigator.popUntil((route) => route.isFirst);
      navigator.push(MaterialPageRoute(builder: (_) => const ProfileScreen()));
    case PillTab.lessons:
      if (user != null && user.schoolLevelId.isNotEmpty) {
        navigator.popUntil((route) => route.isFirst);
        navigator.push(
          MaterialPageRoute(
            builder: (_) =>
                LessonListScreen(levelId: user.schoolLevelId, showPill: true),
          ),
        );
      } else {
        showSchoolChoiceSheet(
          context,
          destination: SchoolChoiceDestination.lessons,
        );
      }
    case PillTab.exercises:
      if (user != null && user.schoolLevelId.isNotEmpty) {
        final level = ContentRepository.instance.levelById(user.schoolLevelId);
        if (level != null) {
          navigator.popUntil((route) => route.isFirst);
          navigator.push(
            MaterialPageRoute(
              builder: (_) => CourseScreen(level: level, showPill: true),
            ),
          );
          return;
        }
      }
      showSchoolChoiceSheet(
        context,
        destination: SchoolChoiceDestination.exercises,
      );
  }
}

class PillNavBar extends StatelessWidget {
  final PillTab selected;

  const PillNavBar({super.key, required this.selected});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(24, 0, 24, 12),
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: c.border),
          boxShadow: [
            BoxShadow(
              color: c.shadow,
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        child: Row(
          children: [
            for (final tab in PillTab.values)
              Expanded(
                child: _PillButton(
                  tab: tab,
                  selected: tab == selected,
                  onTap: () => navigateToTab(context, tab),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  final PillTab tab;
  final bool selected;
  final VoidCallback onTap;

  const _PillButton({
    required this.tab,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: selected ? c.accentSoft : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                selected ? _filledIcon : _outlinedIcon,
                size: 20,
                color: selected ? c.accent : c.textSecondary,
              ),
              const SizedBox(height: 2),
              Text(
                _label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? c.accent : c.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String get _label {
    switch (tab) {
      case PillTab.home:
        return 'HOME';
      case PillTab.lessons:
        return 'LEZIONI';
      case PillTab.exercises:
        return 'ESERCIZI';
      case PillTab.profile:
        return 'PROFILO';
    }
  }

  IconData get _outlinedIcon {
    switch (tab) {
      case PillTab.home:
        return Icons.home_outlined;
      case PillTab.lessons:
        return Icons.menu_book_outlined;
      case PillTab.exercises:
        return Icons.calculate_outlined;
      case PillTab.profile:
        return Icons.person_outline;
    }
  }

  IconData get _filledIcon {
    switch (tab) {
      case PillTab.home:
        return Icons.home;
      case PillTab.lessons:
        return Icons.menu_book;
      case PillTab.exercises:
        return Icons.calculate;
      case PillTab.profile:
        return Icons.person;
    }
  }
}
