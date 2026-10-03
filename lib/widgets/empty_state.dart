import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';

/// Lo stato vuoto di una pagina: icona, titolo e una riga di spiegazione,
/// centrati. L'icona di default è quella del libro, in grigio; gli stati di
/// merito («tutto assimilato») passano `task_alt` in `easy`.
class EmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color? iconColor;

  const EmptyState({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon = Icons.menu_book_outlined,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 52, color: iconColor ?? c.textSecondary),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppText.headingFont,
                fontSize: AppText.titleMedium,
                fontWeight: FontWeight.w600,
                color: c.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: AppText.label, color: c.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
