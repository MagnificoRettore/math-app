import 'package:flutter/services.dart';

import 'data/settings_store.dart';

/// Vibrazioni dell'app, dietro l'interruttore di Personalizzazione.
///
/// Chiude l'unico modo di spegnerle: `HapticFeedback` è di Flutter e non ha
/// un interruttore globale, quindi ogni chiamata passa da qui. Il tasto da cui
/// si cambia l'opzione usa [selectionClick] senza filtro, altrimenti spegnere
/// le vibrazioni renderebbe impossibile accorgersene.
class AppHaptics {
  AppHaptics._();

  static bool get enabled => SettingsStore.instance.hapticsEnabled;

  static void lightImpact() {
    if (enabled) HapticFeedback.lightImpact();
  }

  static void mediumImpact() {
    if (enabled) HapticFeedback.mediumImpact();
  }

  static void heavyImpact() {
    if (enabled) HapticFeedback.heavyImpact();
  }

  static void selectionClick() {
    if (enabled) HapticFeedback.selectionClick();
  }
}
