import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:math_app/data/auth_store.dart';
import 'package:math_app/data/content_repository.dart';
import 'package:math_app/data/progress_store.dart';
import 'package:math_app/data/search_index.dart';
import 'package:math_app/screens/course_screen.dart';
import 'package:math_app/screens/home_screen.dart';
import 'package:math_app/screens/lesson_list_screen.dart';
import 'package:math_app/screens/profile_screen.dart';
import 'package:math_app/screens/registration_screen.dart';

Future<void> _prepare() async {
  SharedPreferences.setMockInitialValues({});
  await AuthStore.instance.resetForTest();
  await ContentRepository.instance.resetForTest();
  await ProgressStore.instance.resetForTest();
  SearchIndex.instance.build(ContentRepository.instance.levels);
}

Future<void> _register() => AuthStore.instance.registerManual(
  name: 'Anna Rossi',
  email: 'anna@example.com',
  password: 'segreta1',
  schoolLevelId: 'middle-school',
);

Future<void> _pumpHome(WidgetTester tester) async {
  await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
  await tester.pumpAndSettle();
}

/// Larghezza dello schermo in pixel logici, come la vede il layout.
double _schermo(WidgetTester tester) =>
    tester.view.physicalSize.width / tester.view.devicePixelRatio;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(_prepare);

  testWidgets('home: l\'icona profilo apre il profilo', (tester) async {
    await _register();
    await _pumpHome(tester);

    expect(find.text('Segnalibri'), findsNothing);

    await tester.tap(find.byKey(const Key('home-profile-avatar')));
    await tester.pumpAndSettle();

    expect(find.byType(ProfileScreen), findsOneWidget);
  });

  testWidgets('lezioni: l\'icona profilo apre il profilo', (tester) async {
    await _register();
    await _pumpHome(tester);

    await tester.tap(find.text('LEZIONI'));
    await tester.pumpAndSettle();
    expect(find.byType(LessonListScreen), findsOneWidget);

    await tester.tap(find.byKey(const Key('home-profile-avatar')));
    await tester.pumpAndSettle();

    expect(find.byType(ProfileScreen), findsOneWidget);
    expect(find.byType(LessonListScreen), findsNothing);
  });

  testWidgets('esercizi: l\'icona profilo apre il profilo', (tester) async {
    await _register();
    await _pumpHome(tester);

    await tester.tap(find.text('ESERCIZI'));
    await tester.pumpAndSettle();
    expect(find.byType(CourseScreen), findsOneWidget);

    await tester.tap(find.byKey(const Key('home-profile-avatar')));
    await tester.pumpAndSettle();

    expect(find.byType(ProfileScreen), findsOneWidget);
    expect(find.byType(CourseScreen), findsNothing);
  });

  testWidgets('home: l\'avatar sta a sinistra del saluto, sulla stessa riga', (
    tester,
  ) async {
    await _register();
    await _pumpHome(tester);

    final avatar = tester.getRect(find.byKey(const Key('home-profile-avatar')));
    final hello = tester.getRect(find.byKey(const Key('home-greeting-hello')));
    final name = tester.getRect(find.byKey(const Key('home-greeting-name')));

    // ordine: avatar, poi le due righe del saluto
    expect(avatar.left, lessThan(hello.left));
    expect(hello.left, closeTo(name.left, 1));
    // e stanno sulla stessa riga: l'altezza dell'header li contiene tutti e
    // tre senza dividerli in due piani
    expect((avatar.center.dy - name.center.dy).abs(), lessThan(avatar.height));
    expect(name.bottom, lessThanOrEqualTo(avatar.bottom));
  });

  testWidgets('home: l\'icona delle impostazioni sta a destra del saluto', (
    tester,
  ) async {
    await _register();
    await _pumpHome(tester);

    final name = tester.getRect(find.byKey(const Key('home-greeting-name')));
    final icon = tester.getRect(find.byKey(const Key('home-customization')));

    // in alto a destra, sulla stessa riga del saluto
    expect(icon.left, greaterThan(name.right));
    expect((icon.center.dy - name.center.dy).abs(), lessThan(icon.height));
  });

  testWidgets('ospite: l\'icona profilo porta alla creazione del profilo', (
    tester,
  ) async {
    await _pumpHome(tester);

    await tester.tap(find.byKey(const Key('profile-button-guest')));
    await tester.pumpAndSettle();

    expect(find.byType(RegistrationScreen), findsOneWidget);
  });

  testWidgets('home: la lente sta in alto a destra, prima delle impostazioni', (
    tester,
  ) async {
    await _register();
    await _pumpHome(tester);

    final lens = tester.getRect(find.byKey(const Key('header-search')));
    final tune = tester.getRect(find.byKey(const Key('home-customization')));
    final avatar = tester.getRect(find.byKey(const Key('home-profile-avatar')));

    // a destra della riga dell'avatar, e nella stessa riga: l'AppBar centra
    // verticalmente title e actions nello stesso toolbar
    expect(lens.left, greaterThan(avatar.right));
    expect((lens.center.dy - avatar.center.dy).abs(), lessThan(1));
    // e la lente sta prima dell'icona delle impostazioni
    expect(lens.right, lessThanOrEqualTo(tune.left));
    expect(_schermo(tester) - tune.right, lessThanOrEqualTo(12));
  });

  testWidgets('lezioni: la lente sta sulla stessa riga dell\'avatar', (
    tester,
  ) async {
    await _register();
    await _pumpHome(tester);

    await tester.tap(find.text('LEZIONI'));
    await tester.pumpAndSettle();

    final lens = tester.getRect(find.byKey(const Key('header-search')));
    final icon = tester.getRect(find.byKey(const Key('home-profile-avatar')));

    expect((lens.center.dy - icon.center.dy).abs(), lessThan(1));
    expect(icon.left, closeTo(30, 1));
    expect(_schermo(tester) - lens.right, lessThanOrEqualTo(12));
  });

  testWidgets('esercizi: la lente sta sulla stessa riga dell\'avatar', (
    tester,
  ) async {
    await _register();
    await _pumpHome(tester);

    await tester.tap(find.text('ESERCIZI'));
    await tester.pumpAndSettle();

    final lens = tester.getRect(find.byKey(const Key('header-search')));
    final icon = tester.getRect(find.byKey(const Key('home-profile-avatar')));

    expect((lens.center.dy - icon.center.dy).abs(), lessThan(1));
    expect(icon.left, closeTo(30, 1));
    expect(_schermo(tester) - lens.right, lessThanOrEqualTo(12));
  });
}
