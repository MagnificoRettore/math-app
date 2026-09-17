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

  test('signout rimuove il profilo', () async {
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
  });

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
    await ContentRepository.instance.load();
    await ProgressStore.instance.load();
    await AuthStore.instance.load();

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
