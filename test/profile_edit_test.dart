import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:math_app/data/auth_store.dart';
import 'package:math_app/data/content_repository.dart';
import 'package:math_app/screens/login_screen.dart';
import 'package:math_app/screens/profile_screen.dart';
import 'package:math_app/screens/school_picker_screen.dart';
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
  });

  testWidgets('salva è spento finché non si tocca qualcosa', (tester) async {
    await registerAccount();
    await pumpProfile(tester);

    FilledButton save() =>
        tester.widget<FilledButton>(find.byKey(const Key('profile-save')));
    expect(save().onPressed, isNull);

    await tester.enterText(find.byType(TextFormField).first, 'Anna Maria');
    await tester.pumpAndSettle();

    expect(save().onPressed, isNotNull);
  });

  testWidgets('il nome nuovo si salva e si vede subito', (tester) async {
    await registerAccount();
    await pumpProfile(tester);

    await tester.enterText(
      find.byType(TextFormField).first,
      'Anna Maria Rossi',
    );
    await scrollTo(tester, find.byKey(const Key('profile-save')));
    await tester.tap(find.byKey(const Key('profile-save')));
    await tester.pumpAndSettle();

    expect(find.text('Modifiche salvate'), findsOneWidget);
    expect(AuthStore.instance.currentUser!.name, 'Anna Maria Rossi');
    expect(find.text('Anna Maria Rossi'), findsWidgets);
  });

  testWidgets('un ID account di un altro viene rifiutato nel campo', (
    tester,
  ) async {
    await registerAccount();
    await AuthStore.instance.signOut();
    await AuthStore.instance.registerManual(
      name: 'Mario',
      email: 'mario@example.com',
      accountId: 'mario',
      password: 'Segreta1',
    );
    await pumpProfile(tester);

    await tester.enterText(find.byType(TextFormField).at(1), 'anna');
    await scrollTo(tester, find.byKey(const Key('profile-save')));
    await tester.tap(find.byKey(const Key('profile-save')));
    await tester.pumpAndSettle();

    expect(find.text('Questo ID account è già in uso'), findsOneWidget);
    expect(AuthStore.instance.currentUser!.accountId, 'mario');
  });

  testWidgets('il proprio ID account non è un conflitto', (tester) async {
    await registerAccount();
    await pumpProfile(tester);

    await tester.enterText(find.byType(TextFormField).at(1), 'anna');
    await tester.pumpAndSettle();

    expect(find.text('Questo ID account è già in uso'), findsNothing);
  });

  testWidgets('l\'avatar scelto si vede subito e si salva', (tester) async {
    await registerAccount();
    await pumpProfile(tester);

    await scrollTo(tester, find.byKey(const Key('profile-change-avatar')));
    await tester.tap(find.byKey(const Key('profile-change-avatar')));
    await tester.pumpAndSettle();

    final option = find.byIcon(avatarIcon('rocket_launch_rounded'));
    expect(option, findsOneWidget);
    await tester.tap(option);
    await tester.pumpAndSettle();

    await scrollTo(tester, find.byKey(const Key('profile-save')));
    await tester.tap(find.byKey(const Key('profile-save')));
    await tester.pumpAndSettle();

    expect(find.text('Modifiche salvate'), findsOneWidget);
    expect(AuthStore.instance.currentUser!.avatarId, 'rocket_launch_rounded');
  });

  testWidgets('rimuovere la foto torna alle iniziali', (tester) async {
    await registerAccount();
    await AuthStore.instance.updateProfile(avatarId: 'rocket_launch_rounded');
    await pumpProfile(tester);

    await scrollTo(tester, find.byKey(const Key('profile-change-avatar')));
    await tester.tap(find.byKey(const Key('profile-change-avatar')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Rimuovi foto, torna alle iniziali'));
    await tester.pumpAndSettle();
    await scrollTo(tester, find.byKey(const Key('profile-save')));
    await tester.tap(find.byKey(const Key('profile-save')));
    await tester.pumpAndSettle();

    expect(AuthStore.instance.currentUser!.avatarId, isEmpty);
    expect(find.text('A'), findsOneWidget);
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
    expect(find.text('Salva'), findsOneWidget);
    expect(find.text('Crea il mio profilo'), findsNothing);

    await tester.tap(find.text('Università'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Salva'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(SchoolPickerScreen), findsNothing);
    expect(find.byType(ProfileScreen), findsOneWidget);
    expect(AuthStore.instance.currentUser!.schoolLevelId, 'university');
  });
}
