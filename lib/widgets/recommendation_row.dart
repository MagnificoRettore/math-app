import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import 'app_card.dart';

/// La riga che sta dentro le sezioni «Per te» e «Per iniziare»: una card con
/// piastra, titolo, badge, riga di anteprima e bottone play.
///
/// È un widget suo perché le due sezioni devono avere lo stesso disegno: la
/// riga d'invito dell'ospite e quella dell'esercizio consigliato cambiano il
/// contenuto, non la geometria. Due copie della stessa riga avrebbero finito
/// per divergere al primo ritocco.
class RecommendationRow extends StatelessWidget {
  final Color plateColor;
  final IconData plateIcon;
  final String title;
  final Widget? badge;
  final String preview;
  final VoidCallback onTap;

  /// Bottone pieno a destra. Sulla Home l'azione è una sola e il bottone la
  /// dichiara; il tappo della card resta aperto a chi tocca altrove.
  final bool showPlayButton;
  final Key? playKey;

  const RecommendationRow({
    super.key,
    required this.plateColor,
    required this.plateIcon,
    required this.title,
    required this.preview,
    required this.onTap,
    this.badge,
    this.showPlayButton = false,
    this.playKey,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: plateColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(plateIcon, color: plateColor, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: AppText.bodyLarge,
                          fontWeight: FontWeight.w600,
                          color: c.textPrimary,
                        ),
                      ),
                    ),
                    ?badge,
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  preview,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: AppText.label,
                    color: c.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (showPlayButton) ...[
            const SizedBox(width: 10),
            SizedBox(
              width: 42,
              height: 42,
              child: Material(
                color: c.accent,
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  key: playKey,
                  onTap: onTap,
                  child: Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
