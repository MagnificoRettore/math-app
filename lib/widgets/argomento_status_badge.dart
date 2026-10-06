import 'package:flutter/material.dart';

import '../models/argomento_status.dart';
import '../theme/app_colors.dart';
import 'completed_badge.dart';

/// Il badge di stato dell'argomento, nell'angolo in alto a destra della sua
/// card: un tondino da [CompletedBadge.size] con un'icona per stato, così si
/// distinguono anche senza il colore. «Superato» è la spunta verde di sempre
/// ([CompletedBadge]); gli altri tre hanno lo stesso ingombro.
///
/// Sta in uno `Positioned` sopra la card ([corner]) e non entra nel layout: la
/// card ha la stessa dimensione con qualunque stato.
class ArgomentoStatusBadge extends StatelessWidget {
  final ArgomentoStatus status;

  const ArgomentoStatusBadge({super.key, required this.status});

  /// Il badge già nell'angolo in alto a destra, per lo `Stack` della card.
  static Widget corner(ArgomentoStatus status) => Positioned(
    top: CompletedBadge.inset,
    right: CompletedBadge.inset,
    child: ArgomentoStatusBadge(status: status),
  );

  @override
  Widget build(BuildContext context) {
    if (status == ArgomentoStatus.passed) return const CompletedBadge();
    final c = AppColors.of(context);
    final (fill, ink, icon) = switch (status) {
      ArgomentoStatus.notStarted => (
        c.surface,
        c.textSecondary,
        Icons.radio_button_unchecked_rounded,
      ),
      ArgomentoStatus.started => (
        c.yellow,
        c.textPrimary,
        Icons.hourglass_top_rounded,
      ),
      _ => (c.hard, c.surface, Icons.close_rounded),
    };
    return Semantics(
      label: status.label,
      excludeSemantics: true,
      child: Container(
        key: Key('status-badge-${status.name}'),
        width: CompletedBadge.size,
        height: CompletedBadge.size,
        decoration: BoxDecoration(
          color: fill,
          shape: BoxShape.circle,
          border: Border.all(color: c.surface, width: 2),
        ),
        child: Icon(icon, size: 16, color: ink),
      ),
    );
  }
}
