import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:math_app/data/auth_store.dart';
import 'package:math_app/data/content_repository.dart';
import 'package:math_app/data/lesson_repository.dart';
import 'package:math_app/data/progress_store.dart';
import 'package:math_app/data/search_index.dart';
import 'package:math_app/screens/course_screen.dart';
import 'package:math_app/screens/home_screen.dart';
import 'package:math_app/widgets/lesson_card.dart';

Future<void> _prepare() async {
  SharedPreferences.setMockInitialValues({});
  await AuthStore.instance.resetForTest();
  await ContentRepository.instance.resetForTest();
  await LessonRepository.instance.resetForTest();
  await ProgressStore.instance.resetForTest();
  SearchIndex.instance.build(
    ContentRepository.instance.levels,
    lessons: LessonRepository.instance.lessons,
  );
}

Future<void> _pumpHome(WidgetTester tester) async {
  await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(_prepare);

  testWidgets(
    'ospite: LEZIONI apre pop-up e mostra lezioni della scuola scelta',
    (tester) async {
      await _pumpHome(tester);

      await tester.tap(find.text('LEZIONI'));
      await tester.pumpAndSettle();

      expect(find.text('Lezioni per scuola'), findsOneWidget);
      expect(find.text('Scuola Media'), findsWidgets);

      await tester.tap(find.text('Scuola Media').last);
      await tester.pumpAndSettle();

      expect(find.text('Lezioni · Scuola Media'), findsOneWidget);
      expect(find.text('Introduzione alle frazioni'), findsOneWidget);
      expect(find.text('Equazioni di primo grado'), findsNothing);
    },
  );

  testWidgets('ospite: le lezioni sono divise per anno come gli esercizi', (
    tester,
  ) async {
    await _pumpHome(tester);

    await tester.tap(find.text('LEZIONI'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Scuola Media').last);
    await tester.pumpAndSettle();

    expect(find.text('Lezioni · Scuola Media'), findsOneWidget);
    expect(find.text('Anno 1'), findsWidgets);
    expect(find.text('Anno 3'), findsWidgets);
    expect(find.text('Introduzione alle frazioni'), findsOneWidget);
    expect(find.text('Teorema di Pitagora'), findsNothing);

    await tester.tap(find.text('Anno 2').first);
    await tester.pumpAndSettle();

    expect(find.byType(LessonCard), findsNothing);
    expect(find.text('Introduzione alle frazioni'), findsNothing);

    await tester.tap(find.text('Anno 3').first);
    await tester.pumpAndSettle();

    expect(find.text('Teorema di Pitagora'), findsOneWidget);
    expect(find.text('Introduzione alle frazioni'), findsNothing);
  });

  testWidgets(
    'loggato: ESERCIZI apre subito la pagina della scuola del profilo',
    (tester) async {
      await AuthStore.instance.registerManual(
        name: 'Anna',
        email: 'anna@example.com',
        password: 'segreta1',
        schoolLevelId: 'high-school',
      );
      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('ESERCIZI'));
      await tester.pumpAndSettle();

      expect(find.byType(CourseScreen), findsOneWidget);
      expect(find.text('Scuola Superiore'), findsOneWidget);
      expect(find.text('Lezioni per scuola'), findsNothing);
    },
  );

  testWidgets(
    'ospite: ESERCIZI da una pagina di profondità non torna alla home',
    (tester) async {
      await _pumpHome(tester);

      await tester.tap(find.text('LEZIONI'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Scuola Media').last);
      await tester.pumpAndSettle();
      expect(find.text('Lezioni · Scuola Media'), findsOneWidget);

      await tester.tap(find.text('ESERCIZI'));
      await tester.pumpAndSettle();

      expect(find.text('Esercizi per scuola'), findsOneWidget);
      expect(find.text('Lezioni · Scuola Media'), findsOneWidget);
      expect(find.text('Matematica'), findsNothing);
    },
  );

  testWidgets('segnalibri: si può tornare indietro con il pulsante back', (
    tester,
  ) async {
    await _pumpHome(tester);

    await tester.tap(find.byTooltip('Segnalibri'));
    await tester.pumpAndSettle();
    expect(find.text('Segnalibri'), findsOneWidget);
    expect(find.text('Matematica'), findsNothing);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Matematica'), findsOneWidget);
    expect(find.text('Segnalibri'), findsNothing);
  });

  testWidgets('la pillola compare solo sulle schermate principali', (
    tester,
  ) async {
    await _pumpHome(tester);

    expect(find.text('HOME'), findsOneWidget);
    expect(find.text('LEZIONI'), findsOneWidget);
    expect(find.text('ESERCIZI'), findsOneWidget);
    expect(find.text('PROFILO'), findsOneWidget);

    await tester.dragUntilVisible(
      find.text('Scuola Superiore'),
      find.byType(ListView),
      const Offset(0, -80),
    );
    await tester.tap(find.text('Scuola Superiore').last);
    await tester.pumpAndSettle();

    expect(find.byType(CourseScreen), findsOneWidget);
    expect(find.text('HOME'), findsNothing);
  });

  testWidgets('PROFILO apre il profilo e HOME ritorna alla home', (
    tester,
  ) async {
    await _pumpHome(tester);

    await tester.tap(find.text('PROFILO'));
    await tester.pumpAndSettle();

    expect(find.text('Profilo'), findsOneWidget);

    await tester.tap(find.text('HOME'));
    await tester.pumpAndSettle();

    expect(find.text('Matematica'), findsOneWidget);
  });
}
