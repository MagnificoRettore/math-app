import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:math_app/data/auth_store.dart';
import 'package:math_app/data/content_repository.dart';
import 'package:math_app/screens/registration_screen.dart';
import 'package:math_app/widgets/app_button.dart';
import 'package:math_app/widgets/shake.dart';

final _avanti = find.byKey(const Key('registration-next'));
final _indietro = find.byKey(const Key('registration-back'));

/// La misura di un telefono: sullo schermo di test di default (800×600) la
/// spunta dei termini e il bottone Google restano sotto il bordo.
void _telefono(WidgetTester tester) {
  tester.view.physicalSize = const Size(400, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AuthStore.instance.resetForTest();
    await ContentRepository.instance.resetForTest();
  });

  Future<void> pumpRegistration(
    WidgetTester tester, {
    bool reduced = false,
  }) async {
    _telefono(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: reduced),
          child: const RegistrationScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Come [pumpRegistration], ma su una rotta vera: alla fine la registrazione
  /// torna alla radice, e se fosse lei la radice il test non proverebbe niente.
  Future<void> pumpRegistrationOnRoute(WidgetTester tester) async {
    _telefono(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const RegistrationScreen()),
              ),
              child: const Text('radice'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('radice'));
    await tester.pumpAndSettle();
  }

  Future<void> avanti(WidgetTester tester) async {
    await tester.tap(_avanti);
    await tester.pumpAndSettle();
  }

  /// Passo 1: l'avatar del razzo e il nome, poi avanti.
  Future<void> chiSei(WidgetTester tester, {String name = 'Anna Rossi'}) async {
    await tester.tap(
      find.byKey(const ValueKey('avatar-option-rocket_launch_rounded')),
    );
    await tester.enterText(find.byType(TextFormField).first, name);
    await avanti(tester);
  }

  /// Passo 2: email, ID, password e conferma (in quest'ordine).
  Future<void> account(
    WidgetTester tester, {
    String email = 'anna@example.com',
    String id = 'anna.rossi',
    bool termini = true,
  }) async {
    await tester.enterText(find.byType(TextFormField).at(0), email);
    await tester.enterText(find.byType(TextFormField).at(1), id);
    await tester.enterText(find.byType(TextFormField).at(2), 'Segreta1');
    await tester.enterText(find.byType(TextFormField).at(3), 'Segreta1');
    await tester.pumpAndSettle();
    if (termini) {
      await tester.tap(find.byKey(const Key('terms-checkbox')));
      await tester.pumpAndSettle();
    }
  }

  Future<void> registraMario() async {
    await AuthStore.instance.load();
    await AuthStore.instance.registerManual(
      name: 'Mario',
      email: 'mario@example.com',
      accountId: 'mario',
      password: 'Segreta1',
    );
    await AuthStore.instance.signOut();
  }

  group('testata', () {
    testWidgets('dice il passo e il titolo, e la barra avanza', (tester) async {
      await pumpRegistration(tester);
      expect(find.text('PASSO 1 DI 3'), findsOneWidget);
      expect(find.text('Chi sei?'), findsOneWidget);

      await chiSei(tester);
      expect(find.text('PASSO 2 DI 3'), findsOneWidget);
      expect(find.text('Il tuo account'), findsOneWidget);
      expect(find.text('Chi sei?'), findsNothing);
    });
  });

  group('passo 1, chi sei', () {
    testWidgets('senza nome non si va avanti e il campo lo dice', (
      tester,
    ) async {
      await pumpRegistration(tester);
      await avanti(tester);

      expect(find.text('Inserisci il tuo nome'), findsOneWidget);
      expect(find.text('PASSO 1 DI 3'), findsOneWidget);
    });

    testWidgets('il nome vuoto si scuote premendo «Continua»', (tester) async {
      await pumpRegistration(tester);
      int trigger() => tester
          .widget<ShakeWidget>(
            find.ancestor(
              of: find.byType(TextFormField).first,
              matching: find.byType(ShakeWidget),
            ),
          )
          .trigger!;
      expect(trigger(), 0);
      await avanti(tester);
      expect(trigger(), 1);
      await avanti(tester);
      expect(trigger(), 2);
    });

    testWidgets('il pulsante Google apre il dialog dimostrativo', (
      tester,
    ) async {
      await pumpRegistration(tester);
      expect(find.text('Oppure registrati con'), findsOneWidget);

      await tester.tap(find.text('Registrati con Google'));
      await tester.pumpAndSettle();
      expect(find.text('Account Google (demo)'), findsOneWidget);

      await tester.tap(find.text('Annulla'));
      await tester.pumpAndSettle();
      expect(AuthStore.instance.isSignedIn, isFalse);
    });
  });

  group('passo 2, account', () {
    testWidgets('il metro di forza segue la password scritta', (tester) async {
      await pumpRegistration(tester);
      await chiSei(tester);
      expect(find.text('Debole'), findsNothing);

      await tester.enterText(find.byType(TextFormField).at(2), 'segreta1');
      await tester.pumpAndSettle();
      expect(find.text('Debole'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField).at(2), 'Segreta123456');
      await tester.pumpAndSettle();
      expect(find.text('Ottima'), findsOneWidget);
    });

    testWidgets('l\'ID account segue l\'email finché non lo si tocca', (
      tester,
    ) async {
      await pumpRegistration(tester);
      await chiSei(tester);

      await tester.enterText(
        find.byType(TextFormField).at(0),
        'anna.rossi@x.it',
      );
      await tester.pumpAndSettle();
      expect(find.text('anna.rossi'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField).at(1), 'scelto');
      await tester.enterText(find.byType(TextFormField).at(0), 'altra@x.it');
      await tester.pumpAndSettle();
      expect(find.text('scelto'), findsOneWidget);
    });

    testWidgets('senza spunta i termini non si va avanti', (tester) async {
      await pumpRegistration(tester);
      await chiSei(tester);
      await account(tester, termini: false);
      await avanti(tester);

      expect(
        find.text('Accetta i Termini e la Privacy Policy per continuare.'),
        findsOneWidget,
      );
      expect(find.text('PASSO 2 DI 3'), findsOneWidget);
    });

    testWidgets('il foglio dei termini si apre e si chiude', (tester) async {
      await pumpRegistration(tester);
      await chiSei(tester);

      await tester.tap(find.byKey(const Key('terms-open')));
      await tester.pumpAndSettle();
      expect(find.text('Termini e Condizioni, Privacy Policy'), findsOneWidget);
      expect(find.textContaining('Testo segnaposto'), findsOneWidget);

      await tester.tapAt(const Offset(200, 80));
      await tester.pumpAndSettle();
      expect(find.text('Termini e Condizioni, Privacy Policy'), findsNothing);
    });

    testWidgets('un ID account già preso viene detto nel campo', (
      tester,
    ) async {
      await registraMario();
      await pumpRegistration(tester);
      await chiSei(tester);
      await tester.enterText(
        find.byType(TextFormField).at(0),
        'anna@example.com',
      );
      await tester.enterText(find.byType(TextFormField).at(1), 'mario');
      await tester.pumpAndSettle();

      expect(find.text('Questo ID account è già in uso'), findsOneWidget);
    });

    testWidgets('una email già presa viene detta nel campo', (tester) async {
      await registraMario();
      await pumpRegistration(tester);
      await chiSei(tester);
      await tester.enterText(
        find.byType(TextFormField).at(0),
        'mario@example.com',
      );
      await tester.pumpAndSettle();

      expect(find.text('Questa email è già presente'), findsOneWidget);
    });

    testWidgets('password diverse: la conferma lo dice subito', (tester) async {
      await pumpRegistration(tester);
      await chiSei(tester);
      await tester.enterText(find.byType(TextFormField).at(2), 'Segreta1');
      await tester.enterText(find.byType(TextFormField).at(3), 'Segreta2');
      await tester.pumpAndSettle();
      expect(find.text('Le password non coincidono'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField).at(3), 'Segreta1');
      await tester.pumpAndSettle();
      expect(find.text('Le password non coincidono'), findsNothing);
    });
  });

  group('tornare indietro', () {
    testWidgets('«Indietro» torna al passo prima e i dati restano', (
      tester,
    ) async {
      await pumpRegistration(tester);
      expect(_indietro, findsNothing);
      await chiSei(tester, name: 'Luca Bianchi');

      await tester.tap(_indietro);
      await tester.pumpAndSettle();
      expect(find.text('PASSO 1 DI 3'), findsOneWidget);
      expect(find.text('Luca Bianchi'), findsOneWidget);
    });

    testWidgets('la freccia dal passo 2 torna al passo 1, non esce', (
      tester,
    ) async {
      await pumpRegistrationOnRoute(tester);
      await chiSei(tester);

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.byType(RegistrationScreen), findsOneWidget);
      expect(find.text('PASSO 1 DI 3'), findsOneWidget);

      // Dal primo passo la freccia esce davvero.
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.byType(RegistrationScreen), findsNothing);
    });
  });

  group('passo 3, scuola', () {
    testWidgets('scelta la scuola, il profilo si crea completo e si torna '
        'alla radice', (tester) async {
      await pumpRegistrationOnRoute(tester);
      await chiSei(tester);
      await account(tester);
      await avanti(tester);
      expect(find.text('PASSO 3 DI 3'), findsOneWidget);

      AppButton crea() => tester.widget<AppButton>(_avanti);
      // Spento finché la scuola non è scelta: il tap prima sarebbe un no-op.
      expect(crea().label, 'Crea il mio profilo');
      expect(crea().onPressed, isNull);

      await tester.tap(find.text('Scuola Superiore'));
      await tester.pumpAndSettle();
      expect(crea().onPressed, isNotNull);

      await avanti(tester);
      expect(tester.takeException(), isNull);
      expect(find.byType(RegistrationScreen), findsNothing);
      expect(find.text('radice'), findsOneWidget);

      final user = AuthStore.instance.currentUser!;
      expect(user.name, 'Anna Rossi');
      expect(user.accountId, 'anna.rossi');
      expect(user.avatarId, 'rocket_launch_rounded');
      expect(user.schoolLevelId, 'high-school');
    });
  });

  group('passaggio animato', () {
    testWidgets('il passo nuovo entra con flutter_animate', (tester) async {
      await pumpRegistration(tester);
      await tester.enterText(find.byType(TextFormField).first, 'Anna Rossi');
      await tester.tap(_avanti);
      await tester.pump();

      expect(find.byType(Animate), findsOneWidget);
      // A metà strada il passo nuovo sta ancora entrando.
      await tester.pump(const Duration(milliseconds: 100));
      final entrata = tester.widget<FadeTransition>(
        find
            .ancestor(
              of: find.byKey(const ValueKey('registration-step-1')),
              matching: find.byType(FadeTransition),
            )
            .first,
      );
      expect(entrata.opacity.value, lessThan(1));
      await tester.pumpAndSettle();
    });

    testWidgets('col movimento ridotto il passo cambia e basta', (
      tester,
    ) async {
      await pumpRegistration(tester, reduced: true);
      await tester.enterText(find.byType(TextFormField).first, 'Anna Rossi');
      await tester.tap(_avanti);
      await tester.pump();

      expect(find.byType(Animate), findsNothing);
      expect(find.text('PASSO 2 DI 3'), findsOneWidget);
    });
  });
}
