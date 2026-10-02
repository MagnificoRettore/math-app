import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:math_app/data/auth_store.dart';
import 'package:math_app/data/content_repository.dart';
import 'package:math_app/data/progress_store.dart';
import 'package:math_app/models/user_profile.dart';
import 'package:math_app/screens/home_screen.dart';
import 'package:math_app/screens/welcome_screen.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AuthStore.instance.resetForTest();
    await ContentRepository.instance.resetForTest();
    await ProgressStore.instance.resetForTest();
  });

  test('registrazione manuale crea e persiste il profilo', () async {
    await AuthStore.instance.load();
    await AuthStore.instance.registerManual(
      name: 'Anna Rossi',
      email: 'anna@example.com',
      password: 'segreta1',
      schoolLevelId: 'high-school',
    );

    expect(AuthStore.instance.isSignedIn, isTrue);
    final user = AuthStore.instance.currentUser!;
    expect(user.name, 'Anna Rossi');
    expect(user.email, 'anna@example.com');
    expect(user.authMethod, AuthMethod.manual);
    expect(user.schoolLevelId, 'high-school');

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('user_profile_v1')!;
    expect(raw, contains('Anna Rossi'));
    expect(raw, contains('anna@example.com'));
    expect(
      raw,
      isNot(contains('segreta1')),
      reason: 'la password non deve essere persistita in chiaro',
    );
  });

  test('iscrizione con Google simulato imposta authMethod google', () async {
    await AuthStore.instance.load();
    await AuthStore.instance.signUpWithGoogle(
      name: 'Mario Bianchi',
      email: 'mario.bianchi@gmail.com',
      schoolLevelId: 'middle-school',
    );

    final user = AuthStore.instance.currentUser!;
    expect(user.authMethod, AuthMethod.google);
    expect(user.email, 'mario.bianchi@gmail.com');
  });

  test('updateSchool aggiorna e persiste la scuola', () async {
    await AuthStore.instance.load();
    await AuthStore.instance.registerManual(
      name: 'Anna',
      email: 'anna@example.com',
      password: 'segreta1',
      schoolLevelId: '',
    );
    await AuthStore.instance.updateSchool('university');

    expect(AuthStore.instance.currentUser!.schoolLevelId, 'university');

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('user_profile_v1')!;
    expect(raw, contains('university'));
  });

  test('signout chiude la sessione e tiene l\'account', () async {
    await AuthStore.instance.load();
    await AuthStore.instance.registerManual(
      name: 'Anna',
      email: 'anna@example.com',
      password: 'segreta1',
      schoolLevelId: 'middle-school',
    );
    await AuthStore.instance.signOut();

    expect(AuthStore.instance.isSignedIn, isFalse);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('user_profile_v1'), isNull);
    expect(prefs.getString('accounts_v1'), isNotNull);
  });

  test('la registrazione salva l\'account con la password derivata', () async {
    await AuthStore.instance.load();
    await AuthStore.instance.registerManual(
      name: 'Anna Rossi',
      email: 'anna@example.com',
      password: 'Segreta1',
    );

    final account = AuthStore.instance.accounts.single;
    expect(account.profile.accountId, 'anna');
    expect(account.hasPassword, isTrue);

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('accounts_v1')!;
    expect(raw, contains('anna'));
    expect(
      raw,
      isNot(contains('Segreta1')),
      reason: 'la password non deve essere persistita in chiaro',
    );
  });

  test('l\'ID account si può scegliere in registrazione', () async {
    await AuthStore.instance.load();
    await AuthStore.instance.registerManual(
      name: 'Anna',
      email: 'anna@example.com',
      accountId: 'anna.rossi',
      password: 'Segreta1',
    );

    expect(AuthStore.instance.currentUser!.accountId, 'anna.rossi');
  });

  test('un ID derivato già preso prende un suffisso', () async {
    await AuthStore.instance.load();
    await AuthStore.instance.registerManual(
      name: 'Anna',
      email: 'anna@example.com',
      password: 'Segreta1',
    );
    await AuthStore.instance.signOut();
    await AuthStore.instance.registerManual(
      name: 'Anna',
      email: 'anna@altra.it',
      password: 'Segreta1',
    );

    expect(AuthStore.instance.currentUser!.accountId, 'anna2');
  });

  test('email e ID account già presi vengono respinti', () async {
    await AuthStore.instance.load();
    await AuthStore.instance.registerManual(
      name: 'Anna',
      email: 'anna@example.com',
      accountId: 'anna',
      password: 'Segreta1',
    );
    await AuthStore.instance.signOut();

    expect(
      () => AuthStore.instance.registerManual(
        name: 'Mario',
        email: 'anna@example.com',
        accountId: 'mario',
        password: 'Segreta1',
      ),
      throwsA(
        isA<AuthException>().having(
          (e) => e.message,
          'message',
          'Questa email è già presente',
        ),
      ),
    );
    expect(
      () => AuthStore.instance.registerManual(
        name: 'Mario',
        email: 'mario@example.com',
        accountId: 'anna',
        password: 'Segreta1',
      ),
      throwsA(
        isA<AuthException>().having(
          (e) => e.message,
          'message',
          'Questo ID account è già in uso',
        ),
      ),
    );
  });

  test('accesso con ID account e password giusta', () async {
    await AuthStore.instance.load();
    await AuthStore.instance.registerManual(
      name: 'Anna',
      email: 'anna@example.com',
      accountId: 'anna',
      password: 'Segreta1',
      schoolLevelId: 'high-school',
    );
    await AuthStore.instance.signOut();

    final result = await AuthStore.instance.signIn(
      identifier: 'anna',
      password: 'Segreta1',
    );

    expect(result, SignInResult.success);
    expect(AuthStore.instance.isSignedIn, isTrue);
    expect(AuthStore.instance.currentUser!.schoolLevelId, 'high-school');
  });

  test('accesso anche con l\'email, e in maiuscolo', () async {
    await AuthStore.instance.load();
    await AuthStore.instance.registerManual(
      name: 'Anna',
      email: 'anna@example.com',
      accountId: 'anna',
      password: 'Segreta1',
    );
    await AuthStore.instance.signOut();

    final result = await AuthStore.instance.signIn(
      identifier: 'Anna@Example.com',
      password: 'Segreta1',
    );

    expect(result, SignInResult.success);
  });

  test('accesso: password sbagliata, account ignoto, campo vuoto', () async {
    await AuthStore.instance.load();
    await AuthStore.instance.registerManual(
      name: 'Anna',
      email: 'anna@example.com',
      password: 'Segreta1',
    );
    await AuthStore.instance.signOut();

    expect(
      await AuthStore.instance.signIn(
        identifier: 'anna',
        password: 'Sbagliata1',
      ),
      SignInResult.wrongPassword,
    );
    expect(
      await AuthStore.instance.signIn(
        identifier: 'nessuno',
        password: 'Segreta1',
      ),
      SignInResult.unknownAccount,
    );
    expect(
      await AuthStore.instance.signIn(identifier: '  ', password: 'Segreta1'),
      SignInResult.emptyIdentifier,
    );
    expect(AuthStore.instance.isSignedIn, isFalse);
  });

  test('un account Google non si accede con la password', () async {
    await AuthStore.instance.load();
    await AuthStore.instance.signUpWithGoogle(
      name: 'Mario',
      email: 'mario@gmail.com',
    );
    await AuthStore.instance.signOut();

    expect(
      await AuthStore.instance.signIn(
        identifier: 'mario',
        password: 'qualsiasi',
      ),
      SignInResult.googleOnly,
    );
  });

  test('dopo il logout si rientra con la password', () async {
    await AuthStore.instance.load();
    await AuthStore.instance.registerManual(
      name: 'Anna',
      email: 'anna@example.com',
      password: 'Segreta1',
    );
    await AuthStore.instance.signOut();

    expect(AuthStore.instance.isSignedIn, isFalse);
    expect(AuthStore.instance.accounts, hasLength(1));

    final result = await AuthStore.instance.signIn(
      identifier: 'anna',
      password: 'Segreta1',
    );

    expect(result, SignInResult.success);
    expect(AuthStore.instance.currentUser!.name, 'Anna');
  });

  test('la sessione sopravvive al riavvio dell\'app', () async {
    SharedPreferences.setMockInitialValues({});
    await AuthStore.instance.resetForTest();
    await AuthStore.instance.registerManual(
      name: 'Anna',
      email: 'anna@example.com',
      accountId: 'anna',
      password: 'Segreta1',
    );

    await AuthStore.instance.reload();

    expect(AuthStore.instance.isSignedIn, isTrue);
    expect(AuthStore.instance.currentUser!.accountId, 'anna');
    expect(
      await AuthStore.instance.signIn(identifier: 'anna', password: 'Segreta1'),
      SignInResult.success,
    );
  });

  test('un profilo salvato prima degli account diventa account', () async {
    SharedPreferences.setMockInitialValues({
      'user_profile_v1': jsonEncode({
        'name': 'Anna',
        'email': 'anna@example.com',
        'authMethod': 'manual',
        'schoolLevelId': 'high-school',
        'createdAt': '2024-01-01T00:00:00.000',
      }),
    });
    await AuthStore.instance.resetForTest();

    expect(AuthStore.instance.isSignedIn, isTrue);
    final account = AuthStore.instance.accounts.single;
    expect(account.profile.accountId, 'anna');
    expect(account.hasPassword, isFalse);
    expect(
      await AuthStore.instance.signIn(identifier: 'anna', password: 'Segreta1'),
      SignInResult.noPassword,
      reason: 'un profilo senza credenziale non si riapre col login',
    );
  });

  test('gli ID e le email in uso escludono l\'account in uso', () async {
    await AuthStore.instance.load();
    await AuthStore.instance.registerManual(
      name: 'Anna',
      email: 'anna@example.com',
      accountId: 'anna',
      password: 'Segreta1',
    );

    expect(AuthStore.instance.accountIdsInUse(), ['anna']);
    expect(
      AuthStore.instance.accountIdsInUse(exceptAccountId: 'anna'),
      isEmpty,
    );
    expect(AuthStore.instance.emailsInUse(exceptAccountId: 'anna'), isEmpty);
  });

  test('il profilo cambia nome, ID account e avatar', () async {
    await AuthStore.instance.load();
    await AuthStore.instance.registerManual(
      name: 'Anna',
      email: 'anna@example.com',
      accountId: 'anna',
      password: 'Segreta1',
    );

    final updated = await AuthStore.instance.updateProfile(
      name: 'Anna Maria Rossi',
      accountId: 'anna.rossi',
      avatarId: 'rocket_launch_rounded',
    );

    expect(updated!.name, 'Anna Maria Rossi');
    expect(updated.email, 'anna@example.com');
    expect(updated.accountId, 'anna.rossi');
    expect(updated.avatarId, 'rocket_launch_rounded');
    expect(AuthStore.instance.accounts.single.profile.accountId, 'anna.rossi');

    await AuthStore.instance.reload();
    expect(AuthStore.instance.currentUser!.accountId, 'anna.rossi');
    expect(AuthStore.instance.currentUser!.avatarId, 'rocket_launch_rounded');
  });

  test('il profilo non prende un ID account di un altro account', () async {
    await AuthStore.instance.load();
    await AuthStore.instance.registerManual(
      name: 'Anna',
      email: 'anna@example.com',
      accountId: 'anna',
      password: 'Segreta1',
    );
    await AuthStore.instance.signOut();
    await AuthStore.instance.registerManual(
      name: 'Mario',
      email: 'mario@example.com',
      accountId: 'mario',
      password: 'Segreta1',
    );

    expect(
      () => AuthStore.instance.updateProfile(accountId: 'anna'),
      throwsA(
        isA<AuthException>().having(
          (e) => e.message,
          'message',
          'Questo ID account è già in uso',
        ),
      ),
    );
    expect(AuthStore.instance.currentUser!.accountId, 'mario');
  });

  test('il profilo non si modifica senza sessione', () async {
    await AuthStore.instance.load();

    expect(await AuthStore.instance.updateProfile(name: 'Chiunque'), isNull);
  });

  test('la scelta della scuola resta nel profilo salvato', () async {
    await AuthStore.instance.load();
    await AuthStore.instance.signUpWithGoogle(
      name: 'Mario',
      email: 'mario@gmail.com',
      schoolLevelId: '',
    );

    await AuthStore.instance.updateSchool('university');

    expect(AuthStore.instance.currentUser!.schoolLevelId, 'university');
    expect(
      AuthStore.instance.accounts.single.profile.schoolLevelId,
      'university',
    );
  });

  test(
    'Google riprende l\'account già esistente invece di duplicarlo',
    () async {
      await AuthStore.instance.load();
      await AuthStore.instance.signUpWithGoogle(
        name: 'Mario',
        email: 'mario@gmail.com',
      );
      await AuthStore.instance.signOut();

      await AuthStore.instance.signUpWithGoogle(
        name: 'Mario Bianchi',
        email: 'Mario@Gmail.com',
      );

      expect(AuthStore.instance.accounts, hasLength(1));
      expect(AuthStore.instance.currentUser!.name, 'Mario');
    },
  );

  testWidgets('welcome screen mostra le opzioni di registrazione', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: WelcomeScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Continua con Google'), findsOneWidget);
    expect(find.text('Registrati con email'), findsOneWidget);
    expect(find.text('Scopri come ospite'), findsOneWidget);
  });

  testWidgets('home mostra la card ospite e poi i consigli per la scuola', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pumpAndSettle();

    final listView = find.byType(ListView);
    await tester.dragUntilVisible(
      find.textContaining('Crea il tuo profilo'),
      listView,
      const Offset(0, -80),
    );
    expect(find.textContaining('Crea il tuo profilo'), findsOneWidget);
    expect(find.text('Per te'), findsNothing);

    await AuthStore.instance.registerManual(
      name: 'Anna',
      email: 'anna@example.com',
      password: 'segreta1',
      schoolLevelId: 'high-school',
    );
    await tester.pumpAndSettle();

    await tester.dragUntilVisible(
      find.text('Per te · Scuola Superiore'),
      listView,
      const Offset(0, -80),
    );
    expect(find.text('Per te · Scuola Superiore'), findsOneWidget);
  });
}
