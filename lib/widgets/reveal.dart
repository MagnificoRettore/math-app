import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_motion.dart';

/// Il centro del widget di [context] in coordinate di schermo: il punto da
/// cui una pagina si espande.
Offset revealOrigin(BuildContext context) {
  final box = context.findRenderObject() as RenderBox;
  return box.localToGlobal(box.size.center(Offset.zero));
}

/// Un cerchio che cresce da [origin] fino a coprire tutto il riquadro:
/// [fraction] 0 è un punto, 1 lo schermo intero.
class _RevealClipper extends CustomClipper<Path> {
  final Offset origin;
  final double fraction;

  const _RevealClipper({required this.origin, required this.fraction});

  @override
  Path getClip(Size size) {
    // Il raggio che arriva all'angolo più lontano: a 1 il cerchio copre tutto.
    final reach = [
      Offset.zero,
      Offset(size.width, 0),
      Offset(0, size.height),
      Offset(size.width, size.height),
    ].map((corner) => (corner - origin).distance).reduce(math.max);
    return Path()
      ..addOval(Rect.fromCircle(center: origin, radius: reach * fraction));
  }

  @override
  bool shouldReclip(_RevealClipper old) =>
      old.origin != origin || old.fraction != fraction;
}

/// La transizione: la pagina si espande dal pulsante e, tornando indietro, si
/// ritira dentro di lui.
Widget revealTransition(
  Animation<double> animation,
  Offset origin,
  Widget child,
) {
  final curved = CurvedAnimation(
    parent: animation,
    curve: AppMotion.standard,
    reverseCurve: AppMotion.standard,
  );
  return AnimatedBuilder(
    animation: curved,
    child: child,
    builder: (context, child) => ClipPath(
      clipper: _RevealClipper(origin: origin, fraction: curved.value),
      child: child,
    ),
  );
}

/// Apre una pagina che si espande dal widget di [context], per i pulsanti
/// dell'header (profilo, personalizzazione). Col movimento ridotto la pagina
/// compare e basta.
Future<T?> pushRevealed<T>(BuildContext context, WidgetBuilder builder) {
  final origin = revealOrigin(context);
  final duration = AppMotion.duration(context, AppMotion.slow);
  return Navigator.of(context).push(
    PageRouteBuilder<T>(
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      pageBuilder: (context, _, _) => builder(context),
      transitionsBuilder: (context, animation, _, child) =>
          revealTransition(animation, origin, child),
    ),
  );
}
