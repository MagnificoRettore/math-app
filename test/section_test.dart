import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:math_app/data/auth_store.dart';
import 'package:math_app/data/content_repository.dart';
import 'package:math_app/data/progress_store.dart';
import 'package:math_app/data/search_index.dart';
import 'package:math_app/models/course.dart';
import 'package:math_app/screens/course_screen.dart';
import 'package:math_app/screens/exercise_feed_screen.dart';
import 'package:math_app/screens/year_exercises_screen.dart';
import 'package:math_app/widgets/year_tabs.dart';

Future<void> _prepare() async {
  SharedPreferences.setMockInitialValues({});
  await AuthStore.instance.resetForTest();
  await ContentRepository.instance.resetForTest();
  await ProgressStore.instance.resetForTest();
  SearchIndex.instance.build(ContentRepository.instance.levels);
}

Future<void> _pumpHighSchool(WidgetTester tester) async {
  final highSchool = ContentRepository.instance.levelById('high-school')!;
  await tester.pumpWidget(MaterialApp(home: CourseScreen(level: highSchool)));
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(_prepare);

  test('il corso è diviso in sezioni con i rispettivi argomenti', () {
    final highSchool = ContentRepository.instance.levelById('high-school')!;
    final year1 = highSchool.courses.first;

    expect(year1.sections.length, 2);
    expect(year1.sections.first.title, 'Numeri e operazioni');
    expect(
      year1.sections.first.topics.map((t) => t.title),
      contains('Frazioni'),
    );
    expect(year1.sections.last.title, 'Equazioni');
    expect(year1.sections.last.topics.single.title, 'Equazioni di primo grado');

    final moduli = highSchool.courses[1].sections.firstWhere(
      (s) => s.title == 'Moduli',
    );
    expect(moduli.topics.single.title, 'Moduli');
    expect(moduli.topics.single.exercises, hasLength(2));
  });

  test('gli anni sono etichettati con i nomi ordinali', () {
    final highSchool = ContentRepository.instance.levelById('high-school')!;
    expect(
      highSchool.courses.map((c) => c.title),
      ['prima', 'seconda', 'terza', 'quarta', 'quinta'],
    );
  });

  test('yearCircleText mappa gli anni ordinali ai numeri romani', () {
    expect(yearCircleText('prima'), 'I');
    expect(yearCircleText('seconda'), 'II');
    expect(yearCircleText('terza'), 'III');
    expect(yearCircleText('quarta'), 'IV');
    expect(yearCircleText('quinta'), 'V');
  });

  test("Course.fromJson ignora la chiave 'image' legacy senza rompersi", () {
    final course = Course.fromJson({
      'id': 'x',
      'title': 'prima',
      'image': 'assets/images/anno1.png',
    });
    expect(course.title, 'prima');
  });

  testWidgets('anno: l\'elenco è piatto per argomento, con la card aggregata', (
    tester,
  ) async {
    await _pumpHighSchool(tester);

    expect(find.text('Tutti gli esercizi'), findsOneWidget);
    expect(find.text('Frazioni'), findsOneWidget);
    expect(find.text('Equazioni di primo grado'), findsOneWidget);
    expect(find.text('Numeri e operazioni'), findsNothing);
    expect(find.text('Equazioni'), findsNothing);

    await tester.tap(find.text('Frazioni'));
    await tester.pumpAndSettle();

    expect(find.byType(ExerciseFeedScreen), findsOneWidget);
  });

  testWidgets(
    'anno: la card "Tutti gli esercizi" apre la raccolta dell\'anno',
    (tester) async {
      await _pumpHighSchool(tester);

      await tester.tap(find.text('Tutti gli esercizi'));
      await tester.pumpAndSettle();

      expect(find.byType(YearExercisesScreen), findsOneWidget);
    },
  );

  testWidgets('anno 2: l\'elenco è piatto per argomento, senza sezioni', (
    tester,
  ) async {
    await _pumpHighSchool(tester);

    await tester.tap(find.text('seconda'));
    await tester.pumpAndSettle();

    expect(find.text('Equazioni di secondo grado'), findsOneWidget);
    expect(find.text('Moduli'), findsOneWidget);
    expect(find.text('Definizione'), findsNothing);
    expect(find.text('Equazioni con i moduli'), findsNothing);

    await tester.tap(find.text('Moduli'));
    await tester.pumpAndSettle();

    expect(find.byType(ExerciseFeedScreen), findsOneWidget);
  });
}
