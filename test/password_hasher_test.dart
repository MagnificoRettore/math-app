import 'package:flutter_test/flutter_test.dart';
import 'package:math_app/data/password_hasher.dart';

void main() {
  group('PasswordHasher', () {
    test('il sale cambia a ogni richiesta', () {
      expect(PasswordHasher.createSalt(), isNot(PasswordHasher.createSalt()));
    });

    test('la password non compare mai nell\'hash', () {
      final salt = PasswordHasher.createSalt();
      final hash = PasswordHasher.hash('segreta1', salt);

      expect(hash, isNot(contains('segreta1')));
      expect(hash, isNotEmpty);
    });

    test('la stessa password con lo stesso sale dà lo stesso hash', () {
      final salt = PasswordHasher.createSalt();

      expect(
        PasswordHasher.hash('segreta1', salt),
        PasswordHasher.hash('segreta1', salt),
      );
    });

    test('lo stesso sale e password diverse danno hash diversi', () {
      final salt = PasswordHasher.createSalt();

      expect(
        PasswordHasher.hash('segreta1', salt),
        isNot(PasswordHasher.hash('segreta2', salt)),
      );
    });

    test('lo stesso sale diverso dà hash diversi', () {
      expect(
        PasswordHasher.hash('segreta1', 'aaaa'),
        isNot(PasswordHasher.hash('segreta1', 'bbbb')),
      );
    });

    test('verify accetta la password giusta e rifiuta le altre', () {
      final salt = PasswordHasher.createSalt();
      final hash = PasswordHasher.hash('segreta1', salt);

      expect(PasswordHasher.verify('segreta1', salt, hash), isTrue);
      expect(PasswordHasher.verify('segreta2', salt, hash), isFalse);
      expect(PasswordHasher.verify('', salt, hash), isFalse);
    });

    test('verify rifiuta un hash di lunghezza diversa senza eccezioni', () {
      expect(PasswordHasher.verify('segreta1', 'sale', 'corto'), isFalse);
    });

    test('l\'hash derivato è lungo quanto dichiarato', () {
      final hash = PasswordHasher.hash('segreta1', PasswordHasher.createSalt());

      // 32 byte in base64: 44 caratteri con l'uguale finale.
      expect(PasswordHasher.keyLengthBytes, 32);
      expect(hash.length, 44);
    });

    test('le iterazioni sono dichiarate', () {
      expect(PasswordHasher.iterations, greaterThan(1000));
    });
  });
}
