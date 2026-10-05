import 'dart:async';

/// Tiene lo stato «premuto» di un bottone che simula la pressione.
///
/// L'`InkWell` segnala la pressione solo quando il tocco è deciso (un tocco
/// veloce, dentro una pagina che scorre, la segnala al rilascio e subito la
/// toglie), quindi il bottone non scenderebbe mai. Qui lo stato parte alla
/// pressione del dito, letta con un `Listener`, e al rilascio resta giù
/// almeno [hold]: un tocco rapido si vede comunque.
class PressTracker {
  final void Function(bool pressed) onChanged;

  PressTracker(this.onChanged);

  DateTime? _since;
  Timer? _release;
  bool _pressed = false;

  /// Quanto resta giù al minimo; zero col movimento ridotto.
  Duration hold = Duration.zero;

  bool get pressed => _pressed;

  void down() {
    _release?.cancel();
    _since = DateTime.now();
    _set(true);
  }

  void up() {
    final since = _since;
    final left = since == null
        ? Duration.zero
        : hold - DateTime.now().difference(since);
    _release?.cancel();
    if (left <= Duration.zero) {
      _set(false);
    } else {
      _release = Timer(left, () => _set(false));
    }
  }

  void _set(bool value) {
    if (_pressed == value) return;
    _pressed = value;
    onChanged(value);
  }

  void dispose() => _release?.cancel();
}
