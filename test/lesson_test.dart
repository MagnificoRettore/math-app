import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:math_app/data/lesson_repository.dart';
import 'package:math_app/data/progress_store.dart';
import 'package:math_app/models/lesson_step.dart';
import 'package:math_app/screens/lesson_screen.dart';

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
    expect(LessonRepository.instance.argomenti, hasLength(1));

    final argomento = LessonRepository.instance.argomenti.single;
    expect(argomento.title, 'Equazioni di primo grado');
    expect(argomento.levelId, 'high-school');
    expect(argomento.yearId, 'year1');
    expect(argomento.lessons, hasLength(1));

    final lessons = LessonRepository.instance.lessonsInYear(
      'high-school',
      'year1',
    );
    expect(lessons, hasLength(1));
    expect(
      LessonRepository.instance.lessonsInYear('scuola-media', 'year1'),
      isEmpty,
    );
  });

  test('la lezione parsifica passaggi info e mcq', () {
    final lesson = LessonRepository.instance.argomenti.single.lessons.first;
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
    final lesson = LessonRepository.instance.argomenti.single.lessons.first;
    final contenuto = lesson.steps[1].content;

    expect(contenuto.contains('# Titolo'), isTrue);
    expect(contenuto.contains('Blocco monostile:'), isTrue);
    expect(contenuto.split('::box').length - 1, 2);
    expect(contenuto.split('::endbox').length - 1, 2);
    expect(contenuto, contains(r'\frac{b}{a}'));
    expect(contenuto, contains('2 * x + t'));
    expect(contenuto, contains('::left'));
  });

  testWidgets('lo schermo lezione mostra le card e avanza coi passaggi', (
    tester,
  ) async {
    final lesson = LessonRepository.instance.argomenti.single.lessons.first;
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
    final lesson = LessonRepository.instance.argomenti.single.lessons.first;
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
}
