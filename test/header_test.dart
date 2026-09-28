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

/// Stessa riga del campo e dell'avatar, con la spaziatura minima laterale.
void _stessaRiga(WidgetTester tester) {
  final field = tester.getRect(find.byKey(const Key('header-text-field')));
  final icon = tester.getRect(find.byKey(const Key('home-profile-avatar')));

  // stessa riga: i due centri verticali coincidono
  expect((field.center.dy - icon.center.dy).abs(), lessThan(1));
  // la riga occupa il minimo di spazio laterale: 12px per lato, 6px
  // fra campo e icona
  expect(field.left, lessThanOrEqualTo(12));
  expect(_schermo(tester) - icon.right, lessThanOrEqualTo(12));
  expect(icon.left - field.right, lessThanOrEqualTo(6));
  // il campo si allarga per riempire quello che resta
  expect(field.width, greaterThan(600));
  // campo e avatar sono cresciuti insieme
  expect(field.height, greaterThanOrEqualTo(56));
  expect(icon.height, greaterThanOrEqualTo(56));
}

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

  testWidgets('ospite: l\'icona profilo porta alla creazione del profilo', (
    tester,
  ) async {
    await _pumpHome(tester);

    await tester.tap(find.byKey(const Key('profile-button-guest')));
    await tester.pumpAndSettle();

    expect(find.byType(RegistrationScreen), findsOneWidget);
  });

  testWidgets('lezioni: la barra di testo accetta di scrivere', (tester) async {
    await _register();
    await _pumpHome(tester);

    await tester.tap(find.text('LEZIONI'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('header-text-field')), 'somme');
    await tester.pumpAndSettle();

    expect(find.text('somme'), findsOneWidget);
  });

  testWidgets('lezioni: il campo sta sulla stessa riga dell\'icona profilo', (
    tester,
  ) async {
    await _register();
    await _pumpHome(tester);

    await tester.tap(find.text('LEZIONI'));
    await tester.pumpAndSettle();

    _stessaRiga(tester);
  });

  testWidgets('esercizi: il campo sta sulla stessa riga dell\'icona profilo', (
    tester,
  ) async {
    await _register();
    await _pumpHome(tester);

    await tester.tap(find.text('ESERCIZI'));
    await tester.pumpAndSettle();

    _stessaRiga(tester);
  });

  testWidgets('esercizi: la barra di testo accetta di scrivere', (
    tester,
  ) async {
    await _register();
    await _pumpHome(tester);

    await tester.tap(find.text('ESERCIZI'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('header-text-field')),
      'equazioni',
    );
    await tester.pumpAndSettle();

    expect(find.text('equazioni'), findsOneWidget);
  });
}
