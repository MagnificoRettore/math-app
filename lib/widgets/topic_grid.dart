import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import 'app_card.dart';
import 'completed_badge.dart';

/// Una voce della griglia di Lezioni ed Esercizi.
class TopicGridEntry {
  final Key key;
  final IconData icon;
  final Color color;
  final String title;

  /// La riga sotto il titolo: «8 lezioni · 100%».
  final String caption;
  final bool completed;
  final VoidCallback onTap;

  const TopicGridEntry({
    required this.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.caption,
    required this.onTap,
    this.completed = false,
  });
}

/// Le voci a due colonne, come una griglia ma con l'altezza che serve al testo:
/// ogni riga è alta quanto la sua card più alta, quindi un titolo su due righe
/// o un testo grande non tagliano niente.
class TopicGrid extends StatelessWidget {
  static const double gap = 12;

  final List<TopicGridEntry> entries;

  const TopicGrid({super.key, required this.entries});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < entries.length; i += 2)
          Padding(
            padding: EdgeInsets.only(bottom: i + 2 < entries.length ? gap : 0),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: _Tile(entry: entries[i])),
                  const SizedBox(width: gap),
                  Expanded(
                    child: i + 1 < entries.length
                        ? _Tile(entry: entries[i + 1])
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  final TopicGridEntry entry;

  const _Tile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final card = AppCard(
      key: entry.key,
      onTap: entry.onTap,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(entry.icon, color: entry.color, size: 28),
          const SizedBox(height: 14),
          Text(
            entry.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: AppText.headingFont,
              fontSize: AppText.titleMedium,
              fontWeight: FontWeight.w600,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            entry.caption,
            style: TextStyle(fontSize: AppText.label, color: c.textSecondary),
          ),
        ],
      ),
    );
    if (!entry.completed) return card;
    // Il segno «completata» nell'angolo in alto a destra, sopra la card.
    return Stack(children: [card, CompletedBadge.corner()]);
  }
}
