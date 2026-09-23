import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:math_app/data/lesson_repository.dart';
import 'package:math_app/data/progress_store.dart';
import 'package:math_app/models/lesson_step.dart';
import 'package:math_app/screens/lesson_screen.dart';
import 'package:math_app/widgets/scientific_calculator.dart';

Future<void> _swipeNext(WidgetTester tester) async {
  await tester.drag(find.byType(PageView), const Offset(-500, 0));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await ProgressStore.instance.resetForTest();
    await LessonRepository.instance.resetForTest();
  });

  test('il repository carica gli argomenti e filtra per anno', () {
    expect(LessonRepository.instance.loaded, isTrue);
    expect(LessonRepository.instance.argomenti, hasLength(2));

    final argomento = LessonRepository.instance.argomenti.firstWhere(
      (a) => a.title == 'Equazioni di primo grado',
    );
    expect(argomento.levelId, 'high-school');
    expect(argomento.yearId, 'year1');
    expect(argomento.lessons, hasLength(1));

    final moduli = LessonRepository.instance.argomenti.firstWhere(
      (a) => a.title == 'Moduli',
    );
    expect(moduli.levelId, 'high-school');
    expect(moduli.yearId, 'year2');
    expect(moduli.topicId, 'year2-moduli-definition');
    expect(moduli.lessons, hasLength(2));

    final lessons = LessonRepository.instance.lessonsInYear(
      'high-school',
      'year1',
    );
    expect(lessons, hasLength(1));
    expect(LessonRepository.instance.lessonsInYear('high-school', 'year2'), [
      ...moduli.lessons,
    ]);
    expect(
      LessonRepository.instance.lessonsInYear('scuola-media', 'year1'),
      isEmpty,
    );
  });

  test('la lezione parsifica passaggi info e mcq', () {
    final lesson = LessonRepository.instance.argomenti
        .firstWhere((a) => a.title == 'Equazioni di primo grado')
        .lessons
        .first;
    expect(lesson.id, 'eq1-intro');
    expect(lesson.minutes, 5);
    expect(lesson.steps, hasLength(3));
    expect(lesson.steps[0].type, LessonStepType.info);
    expect(lesson.steps[1].type, LessonStepType.info);
    expect(lesson.steps[2].type, LessonStepType.mcq);
    expect(lesson.steps[2].options, hasLength(3));
    expect(lesson.steps[2].correctIndex, 0);
    expect(lesson.steps[2].explanation, isNotEmpty);
  });

  test('content come array appiattisce testo e riquadri', () {
    final lesson = LessonRepository.instance.argomenti
        .firstWhere((a) => a.title == 'Equazioni di primo grado')
        .lessons
        .first;
    final contenuto = lesson.steps[1].content;

    expect(contenuto.contains('# Titolo'), isTrue);
    expect(contenuto.contains('Blocco monostile:'), isTrue);
    expect(contenuto.split('::box').length - 1, 2);
    expect(contenuto.split('::endbox').length - 1, 2);
    expect(contenuto, contains(r'\frac{b}{a}'));
    expect(contenuto, contains('2 * x + t'));
    expect(contenuto, contains('::left'));
  });

  test('fontSizeMultiplier parsificato e clampato entro 0.5-2.0', () {
    final moduli = LessonRepository.instance.argomenti.firstWhere(
      (a) => a.title == 'Moduli',
    );
    final lesson = moduli.lessons.firstWhere(
      (l) => l.id == 'mod-equations-intro',
    );

    expect(lesson.steps.last.fontSizeMultiplier, 1.0);

    final clampLow = LessonStep.fromJson({
      'type': 'info',
      'title': 'x',
      'fontSizeMultiplier': 0.1,
    });
    expect(clampLow.fontSizeMultiplier, 0.5);

    final clampHigh = LessonStep.fromJson({
      'type': 'info',
      'title': 'x',
      'fontSizeMultiplier': 9.0,
    });
    expect(clampHigh.fontSizeMultiplier, 2.0);

    final defaultStep = LessonStep.fromJson({'type': 'info', 'title': 'x'});
    expect(defaultStep.fontSizeMultiplier, 1.0);
  });

  testWidgets('lo schermo lezione mostra le card e avanza coi passaggi', (
    tester,
  ) async {
    final lesson = LessonRepository.instance.argomenti
        .firstWhere((a) => a.title == 'Equazioni di primo grado')
        .lessons
        .first;
    await tester.pumpWidget(
      MaterialApp(
        home: LessonScreen(lesson: lesson, levelId: 'high-school'),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Cos\'è un\'equazione'), findsOneWidget);

    await _swipeNext(tester);
    expect(find.text('Equazione di primo grado'), findsOneWidget);

    await _swipeNext(tester);
    expect(find.text('Verifica'), findsOneWidget);
  });

  testWidgets('risposta sbagliata scuote, quella giusta spiega e completa', (
    tester,
  ) async {
    final lesson = LessonRepository.instance.argomenti
        .firstWhere((a) => a.title == 'Equazioni di primo grado')
        .lessons
        .first;
    final levelId = 'high-school';
    await tester.pumpWidget(
      MaterialApp(
        home: LessonScreen(lesson: lesson, levelId: levelId),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    await _swipeNext(tester);
    await _swipeNext(tester);

    await tester.ensureVisible(find.byKey(const ValueKey('option_1')));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byKey(const ValueKey('option_1')));
    await tester.pump(const Duration(milliseconds: 450));
    expect(find.text('Non è corretto'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const ValueKey('option_0')));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byKey(const ValueKey('option_0')));
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('Corretto!'), findsOneWidget);

    await tester.tap(find.text('Completa la lezione'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(
      ProgressStore.instance.isLessonCompleted(levelId, lesson.id),
      isTrue,
    );
  });

  testWidgets('la lezione Definizione è una card vuota con solo il titolo', (
    tester,
  ) async {
    final lesson = LessonRepository.instance.argomenti
        .firstWhere((a) => a.title == 'Moduli')
        .lessons
        .first;
    expect(lesson.title, 'Definizione');
    expect(lesson.steps, hasLength(1));
    expect(lesson.steps.single.title, 'Definizione');
    expect(lesson.steps.single.content, isEmpty);

    await tester.pumpWidget(
      MaterialApp(
        home: LessonScreen(lesson: lesson, levelId: 'high-school'),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(LessonScreen), findsOneWidget);
    expect(find.text('Definizione'), findsWidgets);
  });

  test('la lezione Modulo e Equazioni con Modulo ha sei card', () {
    final moduli = LessonRepository.instance.argomenti.firstWhere(
      (a) => a.title == 'Moduli',
    );
    final lesson = moduli.lessons.firstWhere(
      (l) => l.id == 'mod-equations-intro',
    );
    expect(lesson.title, 'Modulo e Equazioni con Modulo');
    expect(lesson.minutes, 6);
    expect(lesson.steps, hasLength(6));
    expect(lesson.steps.map((s) => s.title), [
      'Che cos\'è il Modulo?',
      'Esempi pratici',
      'Modulo ed Espressioni Letterali',
      'Esempi pratici',
      'Equazioni con Modulo',
      'Prova tu',
    ]);
    for (final step in lesson.steps) {
      expect(step.type, LessonStepType.info);
      expect(step.content, isNotEmpty);
    }
    final step1 = lesson.steps[0].content;
    expect(step1.split('::box').length - 1, 1);
    expect(step1, contains(r'\begin{cases}'));
    expect(step1, isNot(contains('Esempi pratici')));
    expect(lesson.steps[4].content, contains('x - 5'));
    expect(lesson.steps[4].content, isNot(contains('Prova tu')));
    expect(lesson.steps[5].content, contains('4x'));
    expect(lesson.steps[2].content, contains('x-3'));
    expect(lesson.steps[2].content, isNot(contains('Esempi pratici')));
    expect(lesson.steps[3].content, contains('x = 5'));
  });

  testWidgets('la toolbar apre la calcolatrice e il drag giù la chiude', (
    tester,
  ) async {
    final lesson = LessonRepository.instance.argomenti
        .firstWhere((a) => a.title == 'Equazioni di primo grado')
        .lessons
        .first;
    await tester.pumpWidget(
      MaterialApp(
        home: LessonScreen(lesson: lesson, levelId: 'high-school'),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(M3EToolbar), findsOneWidget);
    expect(find.byType(ScientificCalculatorSheet), findsNothing);

    await tester.tap(find.byIcon(M3EIcons.handyman_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    await tester.tap(find.byIcon(M3EIcons.calculate_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(ScientificCalculatorSheet), findsOneWidget);

    await tester.fling(
      find.byKey(const ValueKey('calc-sheet')),
      const Offset(0, 300),
      1200,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.byType(ScientificCalculatorSheet), findsNothing);
  });
}
