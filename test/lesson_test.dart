import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:math_app/data/content_repository.dart';
import 'package:math_app/data/lesson_repository.dart';
import 'package:math_app/data/progress_store.dart';
import 'package:math_app/models/lesson.dart';
import 'package:math_app/screens/lesson_list_screen.dart';
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

  test('ogni lezione è assegnata a una sezione del proprio anno', () {
    final content = ContentRepository.instance;
    for (final lesson in LessonRepository.instance.lessons) {
      expect(lesson.sectionId, isNotEmpty, reason: lesson.id);
      final level = content.levelById(lesson.levelId)!;
      final course = level.courses.firstWhere((c) => c.id == lesson.yearId);
      expect(
        course.sections.any((s) => s.id == lesson.sectionId),
        isTrue,
        reason: '${lesson.id}: sezione ${lesson.sectionId} non nell\'anno',
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

  test('lessonsInSection filtra per livello e sezione', () {
    final repo = LessonRepository.instance;

    final moduli = repo.lessonsInSection('high-school', 'year2-moduli');
    expect(
      moduli.map((l) => l.id),
      containsAll(['moduli-definition', 'moduli-equations']),
    );
    expect(moduli.every((l) => l.sectionId == 'year2-moduli'), isTrue);

    expect(repo.lessonsInSection('high-school', 'year1-numbers'), isEmpty);
    expect(
      repo.lessonsInSection('middle-school', 'ms3-geometry').map((l) => l.id),
      contains('pythagoras'),
    );
  });

  test('Lesson.fromJson legge sezione e anno e usa vuoto come default', () {
    final withSection = Lesson.fromJson({
      'id': 'x',
      'title': 'X',
      'level': 'high-school',
      'year': 'year2',
      'section': 'year2-moduli',
    });
    expect(withSection.yearId, 'year2');
    expect(withSection.sectionId, 'year2-moduli');

    final without = Lesson.fromJson({
      'id': 'y',
      'title': 'Y',
      'level': 'high-school',
    });
    expect(without.yearId, '');
    expect(without.sectionId, '');
    expect(without.image, isNull);
  });

  test('Lesson.fromJson legge la immagine opzionale di introduzione', () {
    final withImage = Lesson.fromJson({
      'id': 'z',
      'title': 'Z',
      'level': 'middle-school',
      'image': 'assets/images/lesson-intro-fractions.png',
    });
    expect(withImage.image, 'assets/images/lesson-intro-fractions.png');
  });

  test('la sezione "Moduli" ha lezioni reali, complete e senza TODO', () {
    final repo = LessonRepository.instance;
    final moduli = repo.lessonsInSection('high-school', 'year2-moduli');
    expect(moduli, hasLength(2));

    for (final lesson in moduli) {
      expect(lesson.subtitle, isNot(contains('[TODO]')), reason: lesson.id);
      expect(lesson.introduction, isNot(contains('[TODO]')), reason: lesson.id);
      expect(
        lesson.completionMessage,
        isNot(contains('[TODO]')),
        reason: lesson.id,
      );
      expect(lesson.steps, isNotEmpty, reason: lesson.id);
      for (final step in lesson.steps) {
        expect(step.prompt, isNot(contains('[TODO]')), reason: lesson.id);
        expect(step.explanation, isNot(contains('[TODO]')), reason: lesson.id);
      }
    }

    final definition = moduli.singleWhere((l) => l.id == 'moduli-definition');
    expect(definition.topics, contains('year2-moduli-definition'));

    final equations = moduli.singleWhere((l) => l.id == 'moduli-equations');
    expect(equations.topics, contains('year2-moduli-definition'));
    expect(equations.steps[1].checkAnswer('5'), isTrue);
    expect(equations.steps[1].checkAnswer('-1'), isTrue);
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

  testWidgets(
    'il flusso lezioni è a cascata: anno (tab) → argomento → sezione',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const LessonListScreen(levelId: 'high-school'),
        ),
      );
      await tester.pumpAndSettle();

      // Step anno: barra anni in alto (come ESERCIZI), prima già attivo
      expect(find.text('prima'), findsWidgets);
      expect(find.text('seconda'), findsWidgets);
      expect(find.text('terza'), findsWidgets);

      await tester.tap(find.text('seconda'));
      await tester.pumpAndSettle();

      // Step argomento: un unico argomento "Moduli" con entrambe le lezioni
      expect(find.text('Moduli'), findsOneWidget);
      expect(find.text('Definizione'), findsNothing);
      expect(find.text('Il valore assoluto'), findsNothing);
      expect(find.text('Equazioni con i moduli'), findsNothing);

      await tester.tap(find.text('Moduli'));
      await tester.pumpAndSettle();

      // Step sezione: "Moduli" (titolo + intestazione) con entrambe le lezioni
      expect(find.text('Moduli'), findsNWidgets(2));
      expect(find.text('Il valore assoluto'), findsOneWidget);
      expect(find.text('Equazioni con i moduli'), findsOneWidget);
    },
  );

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
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('option_1')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
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
    expect(
      ProgressStore.instance.isLessonCompleted(lesson.levelId, lesson.id),
      isTrue,
    );

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

  testWidgets('la card di introduzione mostra l\'immagine della lezione', (
    tester,
  ) async {
    final lesson = LessonRepository.instance.lessons.firstWhere(
      (l) => l.image != null && l.image!.isNotEmpty,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: LessonScreen(lesson: lesson),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(Image), findsWidgets);
  });
}

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}
