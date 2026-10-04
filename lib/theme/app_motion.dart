import 'package:flutter/widgets.dart';

/// Durate e curve delle micro-interazioni, in un posto solo.
///
/// Tutte stanno fra 120 e 300 ms: sotto non si vedono, sopra rallentano chi
/// tocca. Le curve sono morbide in uscita (`easeOut`) e, per i rimbalzi,
/// `easeOutBack`, che supera di poco il punto d'arrivo e ci torna.
///
/// Chi ha chiesto al sistema di ridurre il movimento non vede animazioni:
/// [duration] restituisce zero e lo stato nuovo arriva subito, senza strada
/// in mezzo.
abstract final class AppMotion {
  /// Il tocco: un bottone che scende, un gradino che sparisce.
  static const Duration fast = Duration(milliseconds: 120);

  /// Un cambio di stato: colore, bordo, una spunta che compare.
  static const Duration medium = Duration(milliseconds: 200);

  /// Un'entrata o un rimbalzo, che hanno bisogno di un po' di strada.
  static const Duration slow = Duration(milliseconds: 300);

  /// Lo scarto fra un elemento e il successivo in un'entrata in sequenza:
  /// non è la durata di un'animazione, è quanto aspetta la prossima.
  static const Duration stagger = Duration(milliseconds: 60);

  /// La curva di quasi tutto: parte svelta e arriva piano.
  static const Curve standard = Curves.easeOut;

  /// La curva dei rimbalzi: supera di poco l'arrivo e ci torna.
  static const Curve bounce = Curves.easeOutBack;

  /// `true` se il sistema chiede di ridurre il movimento.
  static bool reduced(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  /// [base], o zero se il movimento è ridotto: lo stato cambia lo stesso,
  /// ma senza animarsi.
  static Duration duration(BuildContext context, Duration base) =>
      reduced(context) ? Duration.zero : base;
}
