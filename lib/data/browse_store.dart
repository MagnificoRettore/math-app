import 'package:flutter/foundation.dart';

import 'auth_store.dart';

/// La scuola che si sta guardando, quando non è quella del profilo.
///
/// È di sola lettura per la navigazione: il profilo non cambia, la home
/// continua sulla sua scuola e i progressi restano separati per livello
/// (`ProgressStore.scopedKey`). Niente persistenza, quindi chiude la app e
/// la scuola in visita sparisce: sfogliare un'altra scuola è una visita, non
/// una scelta.
///
/// La lezione aperta su un'altra scuola **non** scrive il punto di ripresa:
/// quello è uno solo e appartiene alla scuola del profilo
/// (`LessonResumeEngine`).
///
/// Da ospite [levelId] è sempre `null`: l'ospite sceglie la scuola dal foglio
/// e quella scelta resta quella finché non entra. Se la sessione si chiude
/// mentre si guarda un'altra scuola, il valore torna `null` senza scrivere
/// niente, così chi entra dopo comincia sulla propria.
class BrowseStore extends ChangeNotifier {
  static final BrowseStore instance = BrowseStore._();

  BrowseStore._();

  String? _levelId;

  /// La scuola in visita, o `null` se si guarda quella del profilo.
  ///
  /// È derivata, non un campo: se l'utente cambia scuola dal profilo e quella
  /// capita a essere proprio quella in visita, l'id salvato non è più una
  /// visita e non deve più pilotare le pagine. Per questo il confronto con il
  /// profilo sta qui e non nei chiamanti.
  String? get levelId {
    final profileLevelId = AuthStore.instance.currentUser?.schoolLevelId;
    if (profileLevelId == null || profileLevelId.isEmpty) return null;
    return _levelId == profileLevelId ? null : _levelId;
  }

  bool get isBrowsingOtherSchool => levelId != null;

  void browse(String levelId) {
    if (levelId.isEmpty || _levelId == levelId) return;
    _levelId = levelId;
    notifyListeners();
  }

  void reset() {
    if (_levelId == null) return;
    _levelId = null;
    notifyListeners();
  }

  @visibleForTesting
  void resetForTest() {
    _levelId = null;
  }
}
