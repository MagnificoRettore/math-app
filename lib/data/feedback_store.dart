import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Il tipo di messaggio che l'utente lascia dalla pagina di feedback.
enum FeedbackKind {
  idea,
  problem,
  other;

  String get label => switch (this) {
    FeedbackKind.idea => 'Un\'idea',
    FeedbackKind.problem => 'Un problema',
    FeedbackKind.other => 'Altro',
  };
}

/// I feedback lasciati dall'utente.
///
/// **Non c'è un server**: il messaggio resta salvato su questo dispositivo
/// (`feedback_v1`) e non va da nessuna parte. La pagina lo dice, perché
/// promettere un invio che non c'è sarebbe falso.
class FeedbackStore extends ChangeNotifier {
  static final FeedbackStore instance = FeedbackStore._();
  FeedbackStore._();

  static const _key = 'feedback_v1';

  /// Sotto questa lunghezza un messaggio non dice niente.
  static const int minLength = 10;

  final List<Map<String, dynamic>> _entries = [];
  bool _loaded = false;

  /// Quanti messaggi sono stati lasciati.
  int get count => _entries.length;

  Future<void> load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null) {
      try {
        _entries.addAll(
          (jsonDecode(raw) as List<dynamic>).cast<Map<String, dynamic>>(),
        );
      } catch (_) {
        // dati corrotti: si riparte da zero.
      }
    }
    _loaded = true;
  }

  /// Errore da mostrare nel campo, o `null` se il messaggio va bene.
  static String? messageError(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Scrivi il tuo messaggio';
    if (text.length < minLength) {
      return 'Scrivi almeno $minLength caratteri';
    }
    return null;
  }

  Future<void> add(FeedbackKind kind, String message) async {
    await load();
    _entries.add({
      'kind': kind.name,
      'message': message.trim(),
      'at': DateTime.now().toIso8601String(),
    });
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(_entries));
  }

  @visibleForTesting
  Future<void> resetForTest() async {
    _entries.clear();
    _loaded = false;
    await load();
  }
}
