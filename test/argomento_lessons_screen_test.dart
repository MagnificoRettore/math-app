import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:math_app/data/lesson_repository.dart';
import 'package:math_app/data/progress_store.dart';
import 'package:math_app/screens/argomento_lessons_screen.dart';
import 'package:math_app/screens/lesson_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await ProgressStore.instance.resetForTest();
    await LessonRepository.instance.resetForTest();
  });

  Widget host(String levelId) {
    final argomento = LessonRepository.instance.argomenti.firstWhere(
      (a) => a.title == 'Equazioni di primo grado',
    );
    return MaterialApp(
      home: ArgomentoLessonsScreen(argomento: argomento, levelId: levelId),
    );
  }

  testWidgets('il capitolo mostra le lezioni con numero e minuti', (
    tester,
  ) async {
    await tester.pumpWidget(host('high-school'));
    await tester.pump();

    expect(find.byType(ArgomentoLessonsScreen), findsOneWidget);
    expect(find.text('Equazioni di primo grado'), findsWidgets);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('Concetti e risoluzione guidata'), findsOneWidget);
    expect(find.text('5 min'), findsOneWidget);
    expect(find.text('Completata'), findsNothing);
  });

  testWidgets('toccare una lezione apre il player dei passaggi', (
    tester,
  ) async {
    await tester.pumpWidget(host('high-school'));
    await tester.pump();

    await tester.tap(find.text('Concetti e risoluzione guidata'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.byType(LessonScreen), findsOneWidget);
  });

  testWidgets('lezione completata mostra il badge', (tester) async {
    await ProgressStore.instance.completeLesson(
      'high-school',
      'eq1-intro',
    );
    await tester.pumpWidget(host('high-school'));
    await tester.pump();

    expect(find.text('Completata'), findsOneWidget);
  });

  testWidgets('Moduli mostra le lezioni Definizione e Modulo e Equazioni', (
    tester,
  ) async {
    final argomento = LessonRepository.instance.argomenti.firstWhere(
      (a) => a.title == 'Moduli',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: ArgomentoLessonsScreen(argomento: argomento, levelId: 'high-school'),
      ),
    );
    await tester.pump();

    expect(find.text('Moduli'), findsOneWidget);
    expect(find.text('Definizione'), findsOneWidget);
    expect(find.text('Modulo e Equazioni con Modulo'), findsOneWidget);
    expect(find.text('6 min'), findsOneWidget);

    await tester.tap(find.text('Modulo e Equazioni con Modulo'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.byType(LessonScreen), findsOneWidget);
  });
}