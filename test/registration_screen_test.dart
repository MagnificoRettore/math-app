import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:math_app/data/auth_store.dart';
import 'package:math_app/data/content_repository.dart';
import 'package:math_app/screens/registration_screen.dart';
import 'package:math_app/screens/school_picker_screen.dart';
import 'package:math_app/widgets/app_button.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AuthStore.instance.resetForTest();
    await ContentRepository.instance.resetForTest();
  });

  Future<void> pumpRegistration(WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: RegistrationScreen()));
    await tester.pumpAndSettle();
  }

  /// Compila i campi nelle condizioni minime valide.
  Future<void> fillFields(WidgetTester tester) async {
    await tester.enterText(find.byType(TextFormField).at(0), 'Anna Rossi');
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'anna@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(2), 'anna.rossi');
    await tester.enterText(find.byType(TextFormField).at(3), 'Segreta1');
    await tester.enterText(find.byType(TextFormField).at(4), 'Segreta1');
    await tester.pumpAndSettle();
  }

  /// La lista costruisce i figli man mano: il bottone in fondo non esiste finché
  /// non si scorre.
  Future<void> scrollTo(WidgetTester tester, Finder target) async {
    await tester.scrollUntilVisible(
      target,
      200,
      scrollable: find.byType(Scrollable).first,
    );
  }

  Future<void> tapCreate(WidgetTester tester) async {
    await scrollTo(tester, find.text('Crea account'));
    await tester.tap(find.text('Crea account'));
    await tester.pumpAndSettle();
  }

  /// Come [pumpRegistration], ma su una rotta vera.
  ///
  /// Il picker chiude l'onboarding con `popUntil((route) => route.isFirst)`:
  /// se la registrazione fosse la radice non ci sarebbe niente sotto da cui
  /// tornare e il test passerebbe senza provare la navigazione.
  Future<void> pumpRegistrationOnRoute(WidgetTester tester) async {
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

  testWidgets('il metro di forza segue la password scritta', (tester) async {
    await pumpRegistration(tester);

    expect(find.text('Debole'), findsNothing);

    await tester.enterText(find.byType(TextFormField).at(3), 'segreta1');
    await tester.pumpAndSettle();
    expect(find.text('Debole'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(3), 'Segreta123456');
    await tester.pumpAndSettle();
    expect(find.text('Ottima'), findsOneWidget);
  });

  testWidgets('l\'ID account segue l\'email finché non lo si tocca', (
    tester,
  ) async {
    await pumpRegistration(tester);

    await tester.enterText(find.byType(TextFormField).at(1), 'anna.rossi@x.it');
    await tester.pumpAndSettle();
    expect(find.text('anna.rossi'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(2), 'scelto');
    await tester.enterText(find.byType(TextFormField).at(1), 'altra@x.it');
    await tester.pumpAndSettle();
    expect(find.text('scelto'), findsOneWidget);
  });

  testWidgets('senza spunta i termini l\'account non si crea', (tester) async {
    await pumpRegistration(tester);
    await fillFields(tester);

    await tapCreate(tester);

    expect(
      find.text('Accetta i Termini e la Privacy Policy per continuare.'),
      findsOneWidget,
    );
    expect(AuthStore.instance.isSignedIn, isFalse);
  });

  testWidgets('il foglio dei termini si apre e si chiude', (tester) async {
    await pumpRegistration(tester);

    await tester.tap(find.byKey(const Key('terms-open')));
    await tester.pumpAndSettle();

    expect(find.text('Termini e Condizioni, Privacy Policy'), findsOneWidget);
    expect(find.textContaining('Testo segnaposto'), findsOneWidget);

    await tester.tapAt(const Offset(200, 80));
    await tester.pumpAndSettle();
    expect(find.text('Termini e Condizioni, Privacy Policy'), findsNothing);
  });

  testWidgets('un ID account già preso viene detto nel campo', (tester) async {
    await AuthStore.instance.load();
    await AuthStore.instance.registerManual(
      name: 'Mario',
      email: 'mario@example.com',
      accountId: 'mario',
      password: 'Segreta1',
    );
    await AuthStore.instance.signOut();

    await pumpRegistration(tester);
    await tester.enterText(find.byType(TextFormField).at(0), 'Anna Rossi');
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'anna@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(2), 'mario');
    await tester.pumpAndSettle();

    expect(find.text('Questo ID account è già in uso'), findsOneWidget);
  });

  testWidgets('una email già presa viene detta nel campo', (tester) async {
    await AuthStore.instance.load();
    await AuthStore.instance.registerManual(
      name: 'Mario',
      email: 'mario@example.com',
      accountId: 'mario',
      password: 'Segreta1',
    );
    await AuthStore.instance.signOut();

    await pumpRegistration(tester);
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'mario@example.com',
    );
    await tester.pumpAndSettle();

    expect(find.text('Questa email è già presente'), findsOneWidget);
  });

  testWidgets('password diverse: la conferma lo dice subito', (tester) async {
    await pumpRegistration(tester);

    await tester.enterText(find.byType(TextFormField).at(3), 'Segreta1');
    await tester.enterText(find.byType(TextFormField).at(4), 'Segreta2');
    await tester.pumpAndSettle();

    expect(find.text('Le password non coincidono'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(4), 'Segreta1');
    await tester.pumpAndSettle();
    expect(find.text('Le password non coincidono'), findsNothing);
  });

  testWidgets(
    'con i termini accettati l\'account si crea e si sceglie la scuola',
    (tester) async {
      await pumpRegistration(tester);
      await fillFields(tester);
      await tester.tap(find.byKey(const Key('terms-checkbox')));
      await tester.pumpAndSettle();

      await tapCreate(tester);

      expect(AuthStore.instance.isSignedIn, isTrue);
      expect(AuthStore.instance.currentUser!.accountId, 'anna.rossi');
      expect(find.byType(SchoolPickerScreen), findsOneWidget);
    },
  );

  testWidgets('il pulsante Google apre il dialog dimostrativo', (tester) async {
    await pumpRegistration(tester);
    await scrollTo(tester, find.text('Registrati con Google'));

    expect(find.text('Registrati con Google'), findsOneWidget);
    expect(find.text('Oppure registrati con'), findsOneWidget);

    await tester.tap(find.text('Registrati con Google'));
    await tester.pumpAndSettle();

    expect(find.text('Account Google (demo)'), findsOneWidget);

    await tester.tap(find.text('Annulla'));
    await tester.pumpAndSettle();
    expect(AuthStore.instance.isSignedIn, isFalse);
  });

  testWidgets('scelta la scuola il bottone salva e torna alla radice', (
    tester,
  ) async {
    await pumpRegistrationOnRoute(tester);
    await fillFields(tester);
    await tester.tap(find.byKey(const Key('terms-checkbox')));
    await tester.pumpAndSettle();
    await tapCreate(tester);

    AppButton creaProfilo() => tester.widget<AppButton>(
      find.widgetWithText(AppButton, 'Crea il mio profilo'),
    );

    // Spento finché la scuola non è scelta: il tap prima sarebbe un no-op.
    expect(creaProfilo().onPressed, isNull);

    await tester.tap(find.text('Scuola Superiore'));
    await tester.pumpAndSettle();
    expect(creaProfilo().onPressed, isNotNull);

    await tester.tap(find.widgetWithText(AppButton, 'Crea il mio profilo'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(SchoolPickerScreen), findsNothing);
    expect(find.text('radice'), findsOneWidget);
    expect(AuthStore.instance.currentUser!.schoolLevelId, 'high-school');
  });
}
