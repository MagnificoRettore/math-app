import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:math_app/data/lesson_repository.dart';
import 'package:math_app/data/progress_store.dart';
import 'package:math_app/models/lesson.dart';
import 'package:math_app/screens/lesson_screen.dart';
import 'package:math_app/theme/app_theme.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    TestWidgetsFlutterBinding.ensureInitialized();
    await LessonRepository.instance.load();
    await ProgressStore.instance.load();
  });

  test('repository carica le lezioni con i passaggi', () {
    final lessons = LessonRepository.instance.lessons;
    expect(lessons.length, greaterThanOrEqualTo(2));
    for (final lesson in lessons) {
      expect(lesson.steps, isNotEmpty);
      expect(lesson.title, isNotEmpty);
    }
  });

  test('checkAnswer confronta numeri e frazioni', () {
    final repo = LessonRepository.instance;
    final fractions = repo.lessons.firstWhere((l) => l.id == 'fractions-basics');
    final sumStep = fractions.steps[1];

    expect(sumStep.checkAnswer('5/6'), isTrue);
    expect(sumStep.checkAnswer('0.8333333333'), isTrue);
    expect(sumStep.checkAnswer('2'), isFalse);
    expect(sumStep.checkAnswer(''), isFalse);
  });

  testWidgets('flusso completo di una lezione', (tester) async {
    final lesson = LessonRepository.instance.lessons.first;
    final total = lesson.steps.length;
    expect(total, greaterThanOrEqualTo(3));

    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: LessonScreen(lesson: lesson)),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Passo 1 di'), findsOneWidget);

    // Passo 1 (multiple choice): risposta sbagliata → feedback immediato
    await tapVisible(tester, find.byKey(const ValueKey('option_1')));
    expect(find.text('Non è corretto'), findsOneWidget);
    expect(find.text('Continua'), findsNothing);

    // risposta corretta → feedback + Continua
    await tapVisible(tester, find.byKey(const ValueKey('option_0')));
    expect(find.text('Corretto!'), findsOneWidget);
    expect(find.text('Continua'), findsOneWidget);

    // avanza al passo 2 (numerico)
    await tapVisible(tester, find.text('Continua'));
    expect(find.textContaining('Passo 2 di'), findsOneWidget);

    // risposta numerica sbagliata
    await tester.ensureVisible(find.byType(TextField));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '999');
    await tapVisible(tester, find.text('Controlla'));
    expect(find.text('Non è corretto'), findsOneWidget);
    expect(find.text('Continua'), findsNothing);

    // risposta numerica corretta
    await tester.enterText(find.byType(TextField), '5/6');
    await tapVisible(tester, find.text('Controlla'));
    expect(find.text('Corretto!'), findsOneWidget);

    await tapVisible(tester, find.text('Continua'));
    expect(find.textContaining('Passo 3 di'), findsOneWidget);

    // passo 3 testo
    await tester.ensureVisible(find.byType(TextField));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '4/3');
    await tapVisible(tester, find.text('Controlla'));
    expect(find.text('Corretto!'), findsOneWidget);

    await tapVisible(tester, find.text('Continua'));
    expect(find.text('Lezione completata!'), findsOneWidget);
    expect(find.text('Torna alle lezioni'), findsOneWidget);
    expect(ProgressStore.instance.isLessonCompleted(lesson.id), isTrue);

    // ripeti la lezione
    await tapVisible(tester, find.text('Ripeti la lezione'));
    expect(find.textContaining('Passo 1 di'), findsOneWidget);
  });

  testWidgets('la lezione con animazione mostra il visual interattivo',
      (tester) async {
    final lesson = LessonRepository.instance.lessons
        .firstWhere((l) => l.animation == LessonAnimation.pie);

    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: LessonScreen(lesson: lesson)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Animazione interattiva'), findsOneWidget);
    expect(find.text('Tocca la torta per esplorare'), findsOneWidget);
  });
}

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}