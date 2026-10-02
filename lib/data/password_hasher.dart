import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// Hash delle password per l'account salvato sul dispositivo.
///
/// PBKDF2-HMAC-SHA256 con sale casuale: la password non viene mai scritta in
/// chiaro nelle preferenze e ogni account ha un sale diverso.
///
/// **Non è una barriera di sicurezza.** Il profilo e le credenziali stanno in
/// `shared_preferences`, cioè `localStorage` sul web: chi ha accesso al
/// dispositivo legge e modifica i dati a piacere, hash compreso. Serve a non
/// avere la password in chiaro addosso, non a difendersi da un utente
/// ostile. La protezione vera richiede un server.
class PasswordHasher {
  PasswordHasher._();

  /// Iterazioni PBKDF2. Il valore è tarato perché l'app resti reattiva su un
  /// telefono di fascia bassa: uno store remoto ne userebbe molti di più.
  static const int iterations = 10000;

  /// Byte di chiave derivata (le raccomandazioni di PBKDF2-HMAC-SHA256
  /// parlano di 32).
  static const int keyLengthBytes = 32;

  static final _random = Random.secure();

  /// Sale nuovo, casuale, in base64.
  static String createSalt() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    return base64Encode(bytes);
  }

  /// Hash della password col sale dato, in base64.
  static String hash(String password, String salt) {
    final derived = _derive(
      utf8.encode(password),
      utf8.encode(salt),
      iterations,
      keyLengthBytes,
    );
    return base64Encode(derived);
  }

  /// Verifica la password contro l'hash salvato, senza distinzione temporale
  /// fra prefixi che coincidono e prefixi che divergono.
  static bool verify(String password, String salt, String expectedHash) {
    final actual = utf8.encode(hash(password, salt));
    final expected = utf8.encode(expectedHash);
    if (actual.length != expected.length) return false;
    var diff = 0;
    for (var i = 0; i < actual.length; i++) {
      diff |= actual[i] ^ expected[i];
    }
    return diff == 0;
  }

  /// PBKDF2 (RFC 8018) con HMAC-SHA256 come PRF.
  static Uint8List _derive(
    List<int> password,
    List<int> salt,
    int rounds,
    int keyLength,
  ) {
    final prf = Hmac(sha256, password);
    final out = <int>[];
    var block = 1;
    while (out.length < keyLength) {
      final input = <int>[
        ...salt,
        (block >> 24) & 0xff,
        (block >> 16) & 0xff,
        (block >> 8) & 0xff,
        block & 0xff,
      ];
      var u = prf.convert(input).bytes;
      final acc = List<int>.from(u);
      for (var round = 1; round < rounds; round++) {
        u = prf.convert(u).bytes;
        for (var i = 0; i < acc.length; i++) {
          acc[i] ^= u[i];
        }
      }
      out.addAll(acc);
      block++;
    }
    return Uint8List.fromList(out.sublist(0, keyLength));
  }
}
