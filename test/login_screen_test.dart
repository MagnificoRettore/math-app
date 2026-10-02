import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:math_app/data/auth_store.dart';
import 'package:math_app/data/content_repository.dart';
import 'package:math_app/screens/login_screen.dart';
import 'package:math_app/screens/registration_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AuthStore.instance.resetForTest();
    await ContentRepository.instance.resetForTest();
  });

  /// Il login va spinto su una rotta: altrimenti il `pop` dell'accesso
  /// riuscito chiuderebbe la radice e non ci sarebbe più schermo sotto.
  Future<void> pumpLogin(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => const LoginScreen())),
              child: const Text('apri'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('apri'));
    await tester.pumpAndSettle();
  }

  Future<void> registerAccount() async {
    await AuthStore.instance.load();
    await AuthStore.instance.registerManual(
      name: 'Anna',
      email: 'anna@example.com',
      accountId: 'anna',
      password: 'Segreta1',
    );
    await AuthStore.instance.signOut();
  }

  testWidgets('i campi vuoti non lasciano nemmeno tentare', (tester) async {
    await pumpLogin(tester);

    await tester.tap(find.text('Accedi'));
    await tester.pumpAndSettle();

    expect(
      find.text('Scrivi il tuo ID account o la tua email'),
      findsOneWidget,
    );
    expect(find.text('Scrivi la password'), findsOneWidget);
    expect(AuthStore.instance.isSignedIn, isFalse);
  });

  testWidgets('password sbagliata: il messaggio resta nella card', (
    tester,
  ) async {
    await registerAccount();
    await pumpLogin(tester);

    await tester.enterText(find.byType(TextFormField).first, 'anna');
    await tester.enterText(find.byType(TextFormField).last, 'Sbagliata1');
    await tester.tap(find.text('Accedi'));
    await tester.pumpAndSettle();

    expect(find.text('Password errata'), findsOneWidget);
    expect(AuthStore.instance.isSignedIn, isFalse);
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('password giusta: la sessione si apre e si torna indietro', (
    tester,
  ) async {
    await registerAccount();
    await pumpLogin(tester);

    await tester.enterText(find.byType(TextFormField).first, 'anna');
    await tester.enterText(find.byType(TextFormField).last, 'Segreta1');
    await tester.tap(find.text('Accedi'));
    await tester.pumpAndSettle();

    expect(AuthStore.instance.isSignedIn, isTrue);
    expect(find.byType(LoginScreen), findsNothing);
    expect(find.text('apri'), findsOneWidget);
  });

  testWidgets('l\'occhio mostra e nasconde la password', (tester) async {
    await pumpLogin(tester);

    EditableText password() =>
        tester.widget<EditableText>(find.byType(EditableText).last);
    expect(password().obscureText, isTrue);

    await tester.tap(find.byIcon(Icons.visibility_off_outlined));
    await tester.pumpAndSettle();

    expect(password().obscureText, isFalse);
  });

  testWidgets('password dimenticata: il dialog dice che il recupero non c\'è', (
    tester,
  ) async {
    await pumpLogin(tester);

    await tester.tap(find.text('Password dimenticata?'));
    await tester.pumpAndSettle();

    expect(find.text('Password dimenticata'), findsOneWidget);
    expect(find.textContaining('non c\'è un server'), findsOneWidget);

    await tester.tap(find.text('Ho capito'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('il pulsante Google apre il dialog dimostrativo', (tester) async {
    await pumpLogin(tester);

    expect(find.text('Accedi con Google'), findsOneWidget);
    expect(find.text('Oppure accedi con'), findsOneWidget);

    await tester.tap(find.text('Accedi con Google'));
    await tester.pumpAndSettle();

    expect(find.text('Account Google (demo)'), findsOneWidget);

    await tester.tap(find.text('Annulla'));
    await tester.pumpAndSettle();
    expect(AuthStore.instance.isSignedIn, isFalse);
  });

  testWidgets('il link Registrati apre la registrazione', (tester) async {
    await pumpLogin(tester);

    // il testo dell'invito è un Text.rich con WidgetSpan: si cerca la parola
    // cliccabile, non l'intera frase.
    expect(find.text('Registrati'), findsOneWidget);

    await tester.tap(find.text('Registrati'));
    await tester.pumpAndSettle();

    expect(find.byType(RegistrationScreen), findsOneWidget);
  });
}
