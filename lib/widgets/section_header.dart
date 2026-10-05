import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final double top;

  const SectionHeader(this.title, {super.key, this.trailing, this.top = 24});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    // Nessun padding orizzontale: tutte le pagine che ospitano una testata
    // hanno già il loro, quindi i 20px di qui sommati portavano i titoli a 40px
    // mentre le card sotto stavano a 20 — disallineati e con 20px in meno per
    // il testo, che è la metà delle volte finiva con i puntini.
    return Padding(
      padding: EdgeInsets.only(top: top, bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontFamily: AppText.headingFont,
                fontSize: AppText.title,
                fontWeight: FontWeight.w600,
                color: c.textPrimary,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
