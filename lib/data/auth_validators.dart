/// Controlli sui campi di accesso e registrazione.
///
/// Logica pura: niente widget, niente store, così le regole si testano senza
/// schermate. L'unicità arriva da fuori (`taken`), perché a decidere è lo
/// store, non questa classe.
class AuthValidators {
  AuthValidators._();

  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  /// 3-20 caratteri, minuscole, numeri, punto e underscore: handle leggibile e
  /// senza spazi da scrivere a mano.
  static final _accountIdPattern = RegExp(r'^[a-z0-9_.]{3,20}$');

  static String? emailError(
    String? value, {
    Iterable<String> taken = const [],
  }) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Inserisci il tuo indirizzo email';
    if (!_emailPattern.hasMatch(v)) {
      return 'Inserisci un indirizzo email valido';
    }
    if (_containsIgnoreCase(taken, v)) return 'Questa email è già presente';
    return null;
  }

  static String? accountIdError(
    String? value, {
    Iterable<String> taken = const [],
  }) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Scegli un ID account';
    if (v.length < 3) return 'L’ID account deve avere almeno 3 caratteri';
    if (v.length > 20) return 'L’ID account può arrivare a 20 caratteri';
    if (!_accountIdPattern.hasMatch(v)) {
      return 'Solo lettere minuscole, numeri, punto e underscore';
    }
    if (_containsIgnoreCase(taken, v)) return 'Questo ID account è già in uso';
    return null;
  }

  /// Forza da 0 a 4, per il metro a quattro segmenti.
  static int passwordScore(String value) {
    var score = 0;
    if (value.length >= 8) score++;
    if (value.length >= 12) score++;
    if (_hasUpper(value) && _hasLower(value)) score++;
    if (_hasDigit(value)) score++;
    return score;
  }

  /// Etichetta del metro. `value` vuota non ha etichetta: il metro resta
  /// spento finché non si scrive.
  static String? passwordLabel(String value) {
    if (value.isEmpty) return null;
    return switch (passwordScore(value)) {
      <= 1 => 'Troppo debole',
      2 => 'Debole',
      3 => 'Buona',
      _ => 'Ottima',
    };
  }

  static String? passwordError(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Scegli una password';
    if (v.length < 8) return 'Almeno 8 caratteri';
    if (!_hasLower(v)) return 'Serve almeno una lettera minuscola';
    if (!_hasUpper(v)) return 'Serve almeno una maiuscola';
    if (!_hasDigit(v)) return 'Serve almeno un numero';
    return null;
  }

  static String? confirmError(String? value, String password) {
    if (value == null || value.isEmpty) return 'Conferma la password';
    if (value != password) return 'Le password non coincidono';
    return null;
  }

  /// ID account ricavato dall'email quando l'utente non lo sceglie: la parte
  /// prima della chiocciola, ripulita e tagliata a 20 caratteri.
  static String accountIdFromEmail(String email) {
    final local = email.split('@').first.toLowerCase();
    final cleaned = local.replaceAll(RegExp(r'[^a-z0-9_.]'), '');
    if (cleaned.length < 3) return 'studente';
    return cleaned.substring(0, cleaned.length > 20 ? 20 : cleaned.length);
  }

  static bool _hasUpper(String v) => v.contains(RegExp('[A-Z]'));
  static bool _hasLower(String v) => v.contains(RegExp('[a-z]'));
  static bool _hasDigit(String v) => v.contains(RegExp(r'\d'));

  static bool _containsIgnoreCase(Iterable<String> values, String target) {
    final needle = target.toLowerCase();
    return values.any((value) => value.toLowerCase() == needle);
  }
}
