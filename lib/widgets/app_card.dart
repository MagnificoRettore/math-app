import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final Color? borderColor;
  final double radius;
  final bool flat;

  /// Alone colorato nell'angolo in alto a destra, sotto il contenuto.
  final Color? glow;

  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(18),
    this.color,
    this.borderColor,
    this.radius = kCardRadius,
    this.flat = false,
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
        border: Border.all(color: borderColor ?? c.border),
        boxShadow: flat
            ? const []
            : [
                // Due strati: quello stretto definisce il bordo, quello largo
                // stende l'ombra morbida sotto la card. Una ombra sola,
                // stretta, fa la plastica lucida.
                BoxShadow(
                  color: c.shadow,
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: c.shadow.withValues(alpha: 0.06),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
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

/// Raggio delle card dell'app. È alto per scelta: le superfici morbide stanno
/// bene arrotondate, e `Material` su iOS arrotondava già i fogli.
const double kCardRadius = 24;

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
