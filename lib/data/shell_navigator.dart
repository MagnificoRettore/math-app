import 'package:flutter/foundation.dart';

import '../widgets/pill_nav_bar.dart';

/// Chiede alla `HomeScreen` di mostrare una delle tre pagine principali.
///
/// Le pagine stanno tutte nella `HomeScreen`, che le fa scorrere fra header e
/// barra fermi: chi sta in una sotto-pagina (l'argomento che manda agli
/// esercizi) non può costruirne una, deve chiedere alla radice di spostarsi.
/// Senza una `HomeScreen` in ascolto la richiesta si perde.
class ShellNavigator extends ChangeNotifier {
  static final ShellNavigator instance = ShellNavigator._();
  ShellNavigator._();

  PillTab? _tab;
  String? _levelId;
  String? _courseId;

  /// La pagina chiesta e, per Esercizi, la scuola e l'anno da aprire.
  PillTab? get tab => _tab;
  String? get levelId => _levelId;
  String? get courseId => _courseId;

  void show(PillTab tab, {String? levelId, String? courseId}) {
    _tab = tab;
    _levelId = levelId;
    _courseId = courseId;
    notifyListeners();
  }
}
