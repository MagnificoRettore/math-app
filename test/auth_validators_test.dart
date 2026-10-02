import 'package:flutter_test/flutter_test.dart';
import 'package:math_app/data/auth_validators.dart';

void main() {
  group('email', () {
    test('accetta un indirizzo normale', () {
      expect(AuthValidators.emailError('anna.rossi@example.com'), isNull);
    });

    test('rifiuta il campo vuoto', () {
      expect(AuthValidators.emailError(''), 'Inserisci il tuo indirizzo email');
      expect(AuthValidators.emailError(null), isNotNull);
    });

    test('rifiuta ciò che non è un indirizzo', () {
      expect(AuthValidators.emailError('anna'), isNotNull);
      expect(AuthValidators.emailError('anna@'), isNotNull);
      expect(AuthValidators.emailError('anna@example'), isNotNull);
      expect(AuthValidators.emailError('a b@example.com'), isNotNull);
    });

    test('rifiuta un indirizzo già presente', () {
      expect(
        AuthValidators.emailError(
          'anna@example.com',
          taken: ['anna@example.com'],
        ),
        'Questa email è già presente',
      );
    });

    test('l\'email già presente si riconosce anche in maiuscolo', () {
      expect(
        AuthValidators.emailError(
          'Anna@Example.com',
          taken: ['anna@example.com'],
        ),
        isNotNull,
      );
    });
  });

  group('ID account', () {
    test('accetta minuscole, numeri, punto e underscore', () {
      expect(AuthValidators.accountIdError('anna.rossi_1'), isNull);
    });

    test('rifiuta il campo vuoto e le lunghezze fuori range', () {
      expect(AuthValidators.accountIdError(''), 'Scegli un ID account');
      expect(AuthValidators.accountIdError('ab'), isNotNull);
      expect(AuthValidators.accountIdError('a' * 21), isNotNull);
    });

    test('accetta i due estremi della lunghezza', () {
      expect(AuthValidators.accountIdError('abc'), isNull);
      expect(AuthValidators.accountIdError('a' * 20), isNull);
    });

    test('rifiuta maiuscole, spazi e caratteri strani', () {
      expect(AuthValidators.accountIdError('Anna'), isNotNull);
      expect(AuthValidators.accountIdError('anna rossi'), isNotNull);
      expect(AuthValidators.accountIdError('anna@'), isNotNull);
      expect(AuthValidators.accountIdError('annarossi!'), isNotNull);
    });

    test('rifiuta un ID già in uso', () {
      expect(
        AuthValidators.accountIdError('anna', taken: ['anna']),
        'Questo ID account è già in uso',
      );
    });

    test(
      'l\'ID deriva dall\'email ripulendo la parte prima della chiocciola',
      () {
        expect(
          AuthValidators.accountIdFromEmail('Anna.Rossi+scuola@Example.com'),
          'anna.rossiscuola',
          reason: 'il punto resta, il più viene ripulito',
        );
        expect(
          AuthValidators.accountIdFromEmail('anna.rossi@example.com'),
          'anna.rossi',
        );
      },
    );

    test('un ID derivato troppo corto ripiega su studente', () {
      expect(AuthValidators.accountIdFromEmail('ab@x.it'), 'studente');
    });

    test('un ID derivato troppo lungo viene tagliato a 20 caratteri', () {
      final long = '${'a' * 40}@example.com';

      expect(AuthValidators.accountIdFromEmail(long).length, 20);
    });
  });

  group('forza della password', () {
    test('il punteggio cresce con lunghezza, maiuscole e numeri', () {
      expect(AuthValidators.passwordScore(''), 0);
      expect(AuthValidators.passwordScore('abc'), 0);
      expect(AuthValidators.passwordScore('segreta1'), 2);
      expect(AuthValidators.passwordScore('Segreta1'), 3);
      expect(AuthValidators.passwordScore('Segreta123456'), 4);
    });

    test('l\'etichetta segue il punteggio', () {
      expect(AuthValidators.passwordLabel(''), isNull);
      expect(AuthValidators.passwordLabel('abc'), 'Troppo debole');
      expect(AuthValidators.passwordLabel('segreta1'), 'Debole');
      expect(AuthValidators.passwordLabel('Segreta1'), 'Buona');
      expect(AuthValidators.passwordLabel('Segreta123456'), 'Ottima');
    });

    test(
      'i criteri minimi sono 8 caratteri, minuscola, maiuscola e numero',
      () {
        expect(AuthValidators.passwordError(''), 'Scegli una password');
        expect(AuthValidators.passwordError('Ab1'), 'Almeno 8 caratteri');
        expect(
          AuthValidators.passwordError('ABCDEFGH1'),
          'Serve almeno una lettera minuscola',
        );
        expect(
          AuthValidators.passwordError('abcdefgh1'),
          'Serve almeno una maiuscola',
        );
        expect(
          AuthValidators.passwordError('Abcdefgh'),
          'Serve almeno un numero',
        );
        expect(AuthValidators.passwordError('Segreta1'), isNull);
      },
    );
  });

  group('conferma password', () {
    test('chiede la conferma quando il campo è vuoto', () {
      expect(
        AuthValidators.confirmError('', 'Segreta1'),
        'Conferma la password',
      );
      expect(AuthValidators.confirmError(null, 'Segreta1'), isNotNull);
    });

    test('segnala le password diverse', () {
      expect(
        AuthValidators.confirmError('Segreta2', 'Segreta1'),
        'Le password non coincidono',
      );
    });

    test('accetta le password uguali', () {
      expect(AuthValidators.confirmError('Segreta1', 'Segreta1'), isNull);
    });
  });
}
