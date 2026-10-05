import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:math_app/data/auth_store.dart';
import 'package:math_app/data/content_repository.dart';
import 'package:math_app/screens/login_screen.dart';
import 'package:math_app/screens/profile_screen.dart';
import 'package:math_app/screens/school_picker_screen.dart';
import 'package:math_app/widgets/app_button.dart';
import 'package:math_app/widgets/profile_avatar.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AuthStore.instance.resetForTest();
    await ContentRepository.instance.resetForTest();
  });

  Future<void> registerAccount() async {
    await AuthStore.instance.load();
    await AuthStore.instance.registerManual(
      name: 'Anna',
      email: 'anna@example.com',
      accountId: 'anna',
      password: 'Segreta1',
      schoolLevelId: 'high-school',
    );
  }

  Future<void> pumpProfile(WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: ProfileScreen()));
    await tester.pumpAndSettle();
  }

  Future<void> scrollTo(WidgetTester tester, Finder target) async {
    await tester.dragUntilVisible(
      target,
      find.byType(ListView),
      const Offset(0, -120),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('da ospite ci sono Accedi e Registrati', (tester) async {
    await pumpProfile(tester);

    expect(find.text('Nessun profilo'), findsOneWidget);

    await tester.tap(find.byKey(const Key('profile-guest-login')));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('il profilo mostra handle, email e livello', (tester) async {
    await registerAccount();
    await pumpProfile(tester);

    expect(find.text('@anna'), findsOneWidget);
    expect(find.text('anna@example.com'), findsWidgets);
    expect(find.text('Modifica profilo'), findsOneWidget);
    // La foto si cambia toccando l'avatar in testata: sotto l'email non c'è più
    // né la riga con l'anteprima né il bottone «Cambia foto».
    expect(find.text('Cambia foto'), findsNothing);
    expect(find.textContaining('Foto profilo:'), findsNothing);
  });

  /// Il profilo su una rotta vera: il salvataggio parte quando si torna
  /// indietro, quindi serve qualcosa sotto da cui tornare.
  Future<void> pumpPushedProfile(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const ProfileScreen())),
              child: const Text('apri'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('apri'));
    await tester.pumpAndSettle();
  }

  Future<void> goBack(WidgetTester tester) async {
    await tester.pageBack();
    await tester.pumpAndSettle();
  }

  testWidgets('non c\'è «Salva modifiche»', (tester) async {
    await registerAccount();
    await pumpProfile(tester);

    expect(find.text('Salva modifiche'), findsNothing);
    expect(find.byKey(const Key('profile-save')), findsNothing);
  });

  testWidgets('il nome nuovo si salva tornando indietro', (tester) async {
    await registerAccount();
    await pumpPushedProfile(tester);

    await tester.enterText(
      find.byType(TextFormField).first,
      'Anna Maria Rossi',
    );
    await tester.pumpAndSettle();
    // Finché si è nella pagina niente è salvato.
    expect(AuthStore.instance.currentUser!.name, 'Anna');

    await goBack(tester);

    expect(AuthStore.instance.currentUser!.name, 'Anna Maria Rossi');
  });

  testWidgets('un nome non valido non si salva', (tester) async {
    await registerAccount();
    await pumpPushedProfile(tester);

    await tester.enterText(find.byType(TextFormField).first, '');
    await tester.pumpAndSettle();
    await goBack(tester);

    expect(AuthStore.instance.currentUser!.name, 'Anna');
  });

  testWidgets('l\'ID account non si modifica', (tester) async {
    await registerAccount();
    await pumpProfile(tester);

    // Un solo campo di testo (il nome): ID ed email sono in sola lettura.
    expect(find.byType(TextFormField), findsOneWidget);
    expect(find.text('Il tuo nickname, non si modifica'), findsOneWidget);
    expect(AuthStore.instance.currentUser!.accountId, 'anna');
  });

  testWidgets('l\'avatar scelto si vede subito e si salva tornando indietro', (
    tester,
  ) async {
    await registerAccount();
    await pumpPushedProfile(tester);

    await scrollTo(tester, find.byKey(const Key('profile-change-avatar')));
    await tester.tap(find.byKey(const Key('profile-change-avatar')));
    await tester.pumpAndSettle();

    final option = find.byIcon(avatarIcon('rocket_launch_rounded'));
    expect(option, findsOneWidget);
    await tester.tap(option);
    // Il foglio resta aperto il tempo del rimbalzo, così la scelta si vede.
    await tester.pump(const Duration(milliseconds: 150));
    expect(find.text('Scegli la foto profilo'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('Scegli la foto profilo'), findsNothing);

    await goBack(tester);

    expect(AuthStore.instance.currentUser!.avatarId, 'rocket_launch_rounded');
  });

  testWidgets('uscire chiude la sessione e il profilo torna ospite', (
    tester,
  ) async {
    await registerAccount();
    await pumpProfile(tester);

    await scrollTo(tester, find.text('Esci'));
    await tester.tap(find.text('Esci'));
    await tester.pumpAndSettle();

    expect(AuthStore.instance.isSignedIn, isFalse);
    expect(AuthStore.instance.accounts, hasLength(1));
    expect(find.text('Nessun profilo'), findsOneWidget);
  });

  testWidgets('dal profilo la scuola si cambia e si torna indietro', (
    tester,
  ) async {
    await registerAccount();
    await pumpProfile(tester);

    await scrollTo(tester, find.text('Cambia la tua scuola'));
    await tester.tap(find.text('Cambia la tua scuola'));
    await tester.pumpAndSettle();

    // Dal profilo non è onboarding: il bottone dice «Salva» e torna indietro.
    await scrollTo(tester, find.text('Salva'));
    expect(find.text('Salva'), findsOneWidget);
    expect(find.text('Crea il mio profilo'), findsNothing);

    await tester.ensureVisible(find.text('Università'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Università'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.widgetWithText(AppButton, 'Salva'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(AppButton, 'Salva'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(SchoolPickerScreen), findsNothing);
    expect(find.byType(ProfileScreen), findsOneWidget);
    expect(AuthStore.instance.currentUser!.schoolLevelId, 'university');
  });

  testWidgets('cambiando scuola alle superiori si sceglie anche l\'anno', (
    tester,
  ) async {
    await AuthStore.instance.load();
    await AuthStore.instance.registerManual(
      name: 'Anna',
      email: 'anna@example.com',
      accountId: 'anna',
      password: 'Segreta1',
      schoolLevelId: 'university',
    );
    await pumpProfile(tester);

    await scrollTo(tester, find.text('Cambia la tua scuola'));
    await tester.tap(find.text('Cambia la tua scuola'));
    await tester.pumpAndSettle();
    // All'università l'anno non c'è.
    expect(find.text('Che anno frequenti?'), findsNothing);

    await tester.tap(find.text('Scuola Superiore'));
    await tester.pumpAndSettle();
    expect(find.text('Che anno frequenti?'), findsOneWidget);

    // Senza l'anno il bottone è spento.
    await scrollTo(tester, find.widgetWithText(AppButton, 'Salva'));
    expect(
      tester
          .widget<AppButton>(find.widgetWithText(AppButton, 'Salva'))
          .onPressed,
      isNull,
    );

    await tester.tap(find.byKey(const Key('year-year2')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(AppButton, 'Salva'));
    await tester.pumpAndSettle();

    final user = AuthStore.instance.currentUser!;
    expect(user.schoolLevelId, 'high-school');
    expect(user.courseId, 'year2');
  });
}
