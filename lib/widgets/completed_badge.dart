import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Il segno «completata» delle card di argomenti e lezioni: una spunta bianca
/// in un tondino verde ([AppPalette.easy]), con il bordo bianco perché si
/// legga anche sui fondi colorati del carosello. Chi lo usa lo mette
/// nell'angolo in alto a destra della card ([CompletedBadge.corner]).
class CompletedBadge extends StatelessWidget {
  const CompletedBadge({super.key});

  /// Lato del tondino, bordo compreso.
  static const double size = 26;

  /// La distanza dai bordi della card, in alto e a destra.
  static const double inset = 10;

  /// Il segno già nell'angolo in alto a destra, per lo `Stack` della card.
  static Widget corner() =>
      const Positioned(top: inset, right: inset, child: CompletedBadge());

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Semantics(
      label: 'Completata',
      child: Container(
        key: const Key('completed-badge'),
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: c.easy,
          shape: BoxShape.circle,
          border: Border.all(color: c.surface, width: 2),
        ),
        child: Icon(Icons.check_rounded, size: 16, color: c.surface),
      ),
    );
  }
}
