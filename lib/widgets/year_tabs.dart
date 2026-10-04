import 'package:flutter/material.dart';

import '../models/course.dart';
import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import '../theme/app_text.dart';

class YearTabs extends StatelessWidget {
  final List<Course> courses;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const YearTabs({
    super.key,
    required this.courses,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.border)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (final (index, course) in courses.indexed)
                    _YearTab(
                      circleText: yearCircleText(course.title),
                      label: course.title,
                      selected: index == selectedIndex,
                      onTap: () => onSelected(index),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

String yearCircleText(String title) {
  final digit = RegExp(r'\d+').firstMatch(title);
  if (digit != null) return digit.group(0)!;

  final roman = RegExp(
    r'\b([IVXLCDM]+)\b',
    caseSensitive: false,
  ).firstMatch(title);
  if (roman != null) return roman.group(1)!.toUpperCase();

  switch (title.toLowerCase().trim()) {
    case 'prima':
      return 'I';
    case 'seconda':
      return 'II';
    case 'terza':
      return 'III';
    case 'quarta':
      return 'IV';
    case 'quinta':
      return 'V';
  }

  final words = title.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
  if (words.isEmpty) return '';
  if (words.length == 1) return words.first.substring(0, 1).toUpperCase();
  return words.take(2).map((w) => w.substring(0, 1)).join().toUpperCase();
}

/// Un anno: il quadrato della «Classe» del design, con la sua etichetta.
///
/// Scegliendolo, colore, bordo e testi passano in [AppMotion.medium] e la
/// spunta entra con un rimbalzo ([AppMotion.bounce], [AppMotion.slow]); col
/// movimento ridotto il cambio è istantaneo.
class _YearTab extends StatelessWidget {
  final String circleText;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _YearTab({
    required this.circleText,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final change = AppMotion.duration(context, AppMotion.medium);
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      // Il tocco va dichiarato qui: `excludeSemantics` nasconde anche quello
      // del `GestureDetector`, e lo screen reader non potrebbe scegliere.
      onTap: onTap,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedContainer(
                  duration: change,
                  curve: AppMotion.standard,
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  // Il quadrato arrotondato della «Classe» del design: giallo
                  // con il bordo oro l'anno scelto, bianco con il bordo lilla
                  // gli altri.
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: selected ? c.yellow : c.surface,
                    border: Border.all(
                      color: selected ? c.yellowDeep : c.border,
                      width: 3,
                    ),
                  ),
                  // Inchiostro sul giallo, indaco sul bianco.
                  child: AnimatedDefaultTextStyle(
                    duration: change,
                    curve: AppMotion.standard,
                    style: TextStyle(
                      fontFamily: AppText.headingFont,
                      fontSize: AppText.titleMedium,
                      fontWeight: FontWeight.w600,
                      color: selected ? c.textPrimary : c.accent,
                    ),
                    child: Text(circleText),
                  ),
                ),
                Positioned(
                  top: -6,
                  right: -6,
                  child: AnimatedScale(
                    key: const Key('year-tab-check'),
                    scale: selected ? 1 : 0,
                    duration: AppMotion.duration(context, AppMotion.slow),
                    curve: AppMotion.bounce,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: c.accent,
                        shape: BoxShape.circle,
                        border: Border.all(color: c.surface, width: 2),
                      ),
                      child: Icon(
                        Icons.check_rounded,
                        size: 11,
                        color: c.surface,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 72),
              child: AnimatedDefaultTextStyle(
                duration: change,
                curve: AppMotion.standard,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: AppText.micro,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? c.textPrimary : c.textSecondary,
                ),
                child: Text(label),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
