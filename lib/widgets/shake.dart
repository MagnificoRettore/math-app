import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_motion.dart';

/// Scuotimento orizzontale: quattro oscillazioni di 10 px che si smorzano, in
/// [AppMotion.slow]. Col movimento ridotto niente scossa: l'errore si legge
/// già nel messaggio e nel colore.
///
/// Due modi:
/// - senza [trigger] si scuote una volta, quando compare (la card «Non è
///   corretto», che ha una chiave nuova a ogni tentativo);
/// - con [trigger] si scuote ogni volta che il numero cresce, **senza
///   ricreare il figlio**: un campo di testo tiene fuoco ed errore.
///
/// È un'animazione implicita (`TweenAnimationBuilder`) e non `flutter_animate`:
/// ogni `Animate` crea un timer al montaggio, e i campi di un modulo ci sono
/// sempre.
class ShakeWidget extends StatelessWidget {
  final Widget child;
  final int? trigger;

  const ShakeWidget({super.key, required this.child, this.trigger});

  /// Ampiezza della prima oscillazione, in pixel.
  static const double _amount = 10;

  /// Oscillazioni nella durata della scossa.
  static const int _swings = 4;

  @override
  Widget build(BuildContext context) {
    if (AppMotion.reduced(context)) return child;
    final trigger = this.trigger;
    // Il valore va da un intero al successivo: la parte frazionaria è il tempo
    // della scossa, e sugli interi la scossa è ferma. Senza trigger parte da
    // -1 e arriva a 0 al montaggio; con il trigger parte fermo e si muove
    // quando il numero cresce.
    final tween = trigger == null
        ? Tween<double>(begin: -1, end: 0)
        : Tween<double>(end: trigger.toDouble());
    return TweenAnimationBuilder<double>(
      tween: tween,
      duration: AppMotion.slow,
      builder: (context, value, child) {
        final t = value - value.floorToDouble();
        final dx = _amount * math.sin(t * 2 * math.pi * _swings) * (1 - t);
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: child,
    );
  }
}

/// I contatori dello shake dei campi obbligatori di un modulo: uno per campo,
/// letti da [ShakeWidget.trigger].
class FieldShakes {
  final _counts = <TextEditingController, int>{};

  int of(TextEditingController controller) => _counts[controller] ?? 0;

  /// Fa scuotere i campi vuoti fra [required]. Chi chiama fa `setState`.
  void shakeEmpty(Iterable<TextEditingController> required) {
    for (final controller in required) {
      if (controller.text.trim().isEmpty) {
        _counts[controller] = of(controller) + 1;
      }
    }
  }
}
