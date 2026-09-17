import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:math_app/data/content_repository.dart';
import 'package:math_app/data/lesson_repository.dart';
import 'package:math_app/data/progress_store.dart';
import 'package:math_app/models/lesson.dart';
import 'package:math_app/screens/lesson_screen.dart';
import 'package:math_app/theme/app_theme.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    TestWidgetsFlutterBinding.ensureInitialized();
    await ContentRepository.instance.resetForTest();
    await LessonRepository.instance.resetForTest();
    await ProgressStore.instance.resetForTest();
  });

  test('repository carica le lezioni con i passaggi', () {
    final lessons = LessonRepository.instance.lessons;
    expect(lessons.length, greaterThanOrEqualTo(2));
    for (final lesson in lessons) {
      expect(lesson.steps, isNotEmpty);
      expect(lesson.title, isNotEmpty);
    }
  });

  test('le lezioni sono assegnate a un anno del proprio livello', () {
    final content = ContentRepository.instance;
    for (final lesson in LessonRepository.instance.lessons) {
      expect(lesson.yearId, isNotEmpty, reason: lesson.id);
      final level = content.levelById(lesson.levelId);
      expect(level, isNotNull, reason: lesson.id);
      expect(
        level!.courses.any((c) => c.id == lesson.yearId),
        isTrue,
        reason: '${lesson.id}: anno ${lesson.yearId} non nel livello',
      );
    }
  });

  test('lessonsInYear filtra per livello e anno', () {
    final repo = LessonRepository.instance;

    final ms1 = repo.lessonsInYear('middle-school', 'ms-year1');
    expect(ms1.map((l) => l.id), contains('fractions-basics'));
    expect(ms1.every((l) => l.yearId == 'ms-year1'), isTrue);

    final ms3 = repo.lessonsInYear('middle-school', 'ms-year3');
    expect(ms3.map((l) => l.id), contains('pythagoras'));

    expect(repo.lessonsInYear('middle-school', 'ms-year2'), isEmpty);
    expect(repo.lessonsInYear('university', 'analysis1'), isEmpty);
  });

  test('Lesson.fromJson legge year e usa vuoto come default', () {
    final withYear = Lesson.fromJson({
      'id': 'x',
      'title': 'X',
      'level': 'high-school',
      'year': 'year2',
    });
    expect(withYear.yearId, 'year2');

    final without = Lesson.fromJson({
      'id': 'y',
      'title': 'Y',
      'level': 'high-school',
    });
    expect(without.yearId, '');
  });

  test('checkAnswer confronta numeri e frazioni', () {
    final repo = LessonRepository.instance;
    final fractions = repo.lessons.firstWhere(
      (l) => l.id == 'fractions-basics',
    );
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
      MaterialApp(
        theme: AppTheme.light,
        home: LessonScreen(lesson: lesson),
      ),
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

  testWidgets('la lezione con animazione mostra il visual interattivo', (
    tester,
  ) async {
    final lesson = LessonRepository.instance.lessons.firstWhere(
      (l) => l.animation == LessonAnimation.pie,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: LessonScreen(lesson: lesson),
      ),
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
