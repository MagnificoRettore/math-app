import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final Color? borderColor;

  /// Spessore del bordo, quando c'è: 3 per una card scelta, come i controlli
  /// del design.
  final double borderWidth;
  final double radius;

  /// Alone colorato nell'angolo in alto a destra, sotto il contenuto.
  final Color? glow;

  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(18),
    this.color,
    this.borderColor,
    this.borderWidth = 1,
    this.radius = kCardRadius,
    this.glow,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final shape = BorderRadius.circular(radius);
    final card = Container(
      decoration: BoxDecoration(
        color: color ?? c.surface,
        borderRadius: shape,
        // Il design non ha bordi sulle card: il bordo c'è solo quando chi
        // chiama lo chiede, per colorarla.
        border: borderColor == null
            ? null
            : Border.all(color: borderColor!, width: borderWidth),
        // Un'ombra fine e bassa, che stacca la card dal crema senza farla
        // galleggiare. Il gradino pieno resta solo dei bottoni.
        boxShadow: cardShadow(c),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: shape,
        child: InkWell(
          onTap: onTap,
          borderRadius: shape,
          child: Padding(
            padding: padding,
            child: glow == null
                ? child
                : Stack(
                    // Il taglio è morbido: l'alone esce dai bordi della card
                    // invece di essere ritagliato a quadrato.
                    clipBehavior: Clip.none,
                    children: [_Glow(glow!), child],
                  ),
          ),
        ),
      ),
    );

    if (onTap == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 0),
        child: card,
      );
    }
    return card;
  }
}

/// Raggio delle card dell'app: le card del design stanno fra 18 e 22.
const double kCardRadius = 20;

/// L'ombra delle card: una sfumatura fine sotto, indaco al 12% (`shadow`),
/// blur 10 e scostata di 3 in basso. La usano `AppCard`, la card «Traguardo»
/// e le card del carosello.
List<BoxShadow> cardShadow(AppPalette c) => [
  BoxShadow(color: c.shadow, blurRadius: 10, offset: const Offset(0, 3)),
];

/// Alone colorato nell'angolo in alto a destra di una card.
///
/// Il gradiente è dentro la sfera, non è il blur a fare lo sfumato: su un
/// contenitore di colore pieno `ImageFilter.blur` non cambia niente, perché
/// sposta pixel tutti uguali. Il blur serve a far salire la sfera fuori dai
/// bordi senza spigoli.
class _Glow extends StatelessWidget {
  const _Glow(this.color);

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: -40,
      right: -30,
      child: IgnorePointer(
        child: ImageFiltered(
          imageFilter: ui.ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  color.withValues(alpha: 0.30),
                  color.withValues(alpha: 0),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
