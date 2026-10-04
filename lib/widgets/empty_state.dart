import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import 'illustration.dart';

/// Lo stato vuoto di una pagina: un'illustrazione del design, il titolo e una
/// riga di spiegazione, centrati. Di default l'albero che cresce dal libro (le
/// lezioni in arrivo); gli stati di merito («tutto assimilato») passano il
/// razzo.
class EmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final AppIllustration illustration;

  const EmptyState({
    super.key,
    required this.title,
    required this.subtitle,
    this.illustration = AppIllustration.albero,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    // Scorre se la pagina è bassa: l'illustrazione è alta, e un telefono
    // in orizzontale o con il testo grande non la conterrebbe.
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IllustrationView(illustration, width: 150),
            const SizedBox(height: 16),
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
