import 'package:flutter/material.dart';

import '../models/course.dart';
import '../theme/app_colors.dart';

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
                      image: course.image,
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

class _YearTab extends StatelessWidget {
  final String circleText;
  final String label;
  final String? image;
  final bool selected;
  final VoidCallback onTap;

  const _YearTab({
    required this.circleText,
    required this.label,
    this.image,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final circleImage = image;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected ? c.accent : c.surface,
              border: Border.all(
                color: selected ? c.accent : c.border,
                width: 1.5,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: c.accent.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: circleImage != null && circleImage.isNotEmpty
                ? ClipOval(
                    child: Image.asset(
                      circleImage,
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) =>
                          _CircleText(text: circleText, selected: selected),
                    ),
                  )
                : _CircleText(text: circleText, selected: selected),
          ),
          const SizedBox(height: 5),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 72),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? c.textPrimary : c.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleText extends StatelessWidget {
  final String text;
  final bool selected;

  const _CircleText({required this.text, this.selected = false});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Text(
      text,
      style: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: selected ? Colors.white : c.textSecondary,
      ),
    );
  }
}
