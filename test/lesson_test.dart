import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:math_app/data/lesson_repository.dart';
import 'package:math_app/data/progress_store.dart';
import 'package:math_app/models/lesson.dart';
import 'package:math_app/models/lesson_step.dart';
import 'package:math_app/models/multifunction_box/box_payload.dart';
import 'package:math_app/models/multifunction_box/box_type.dart';
import 'package:math_app/models/multifunction_box/multifunction_box.dart';
import 'package:math_app/screens/lesson_screen.dart';
import 'package:math_app/widgets/app_button.dart';
import 'package:math_app/widgets/app_card.dart';
import 'package:math_app/widgets/mcq_option_tile.dart';
import 'package:math_app/widgets/practice_quiz_view.dart';
import 'package:math_app/widgets/scientific_calculator.dart';
import 'package:math_app/widgets/tools_bar.dart';

Future<void> _swipeNext(WidgetTester tester) async {
  await tester.drag(find.byType(PageView), const Offset(-500, 0));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

const _kCelebrationTestDuration = Duration(milliseconds: 2500);

/// Apre la prima lezione di «Equazioni di primo grado» sopra una schermata
/// vuota: al completamento la lezione fa pop, e serve una pagina sotto per
/// vedere com'è andata.
Future<Lesson> _apriPrimaLezione(WidgetTester tester) async {
  final lesson = LessonRepository.instance.argomenti
      .firstWhere((a) => a.title == 'Equazioni di primo grado')
      .lessons
      .first;
  await tester.pumpWidget(const MaterialApp(home: Scaffold(body: SizedBox())));
  tester
      .state<NavigatorState>(find.byType(Navigator))
      .push(
        MaterialPageRoute(
          builder: (_) => LessonScreen(lesson: lesson, levelId: 'high-school'),
        ),
      );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  return lesson;
}

/// Porta la lezione aperta all'ultima card con la verifica risolta: sbaglio,
/// poi risposta giusta. Da qui si completa col bottone o collo swipe.
Future<void> _risolviVerifica(WidgetTester tester) async {
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
}

Future<void> _completa(WidgetTester tester) async {
  await _risolviVerifica(tester);
  await tester.tap(find.text('Completa la lezione'));
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
    expect(LessonRepository.instance.argomenti, hasLength(4));

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
    // Le equazioni (1) e l'argomento d'esempio dei grafici (4).
    expect(lessons, hasLength(5));
    expect(LessonRepository.instance.lessonsInYear('high-school', 'year2'), [
      ...moduli.lessons,
    ]);
    expect(
      LessonRepository.instance.lessonsInYear('scuola-media', 'year1'),
      isEmpty,
    );
  });

  test(
    'le rette sono il primo argomento di terza con l\'immagine iniziale',
    () {
      final rettes = LessonRepository.instance.argomenti.firstWhere(
        (a) => a.title == 'Le rette',
      );
      expect(rettes.levelId, 'high-school');
      expect(rettes.yearId, 'year3');
      expect(rettes.topicId, 'year3-rettes');
      expect(rettes.lessons, hasLength(1));

      final lezione = rettes.lessons.single;
      expect(lezione.title, 'Introduzione');
      expect(lezione.steps, hasLength(2));
      final step = lezione.steps.first;
      expect(step.title, 'Definizione');
      expect(step.type, LessonStepType.info);
      final box = MultifunctionBox.fromJson(
        jsonDecode(
          RegExp(
            r'::box\n(.*?)\n::endbox',
            dotAll: true,
          ).firstMatch(step.content)!.group(1)!,
        ) as Map<String, dynamic>,
      );
      expect(box.boxType, BoxType.image);
      expect(
        (box.payload as ImageBoxPayload).source,
        'assets/images/retta.png',
      );

      expect(LessonRepository.instance.lessonsInYear('high-school', 'year3'), [
        lezione,
      ]);
    },
  );

  test('la lezione parsifica passaggi info e mcq', () {
    final lesson = LessonRepository.instance.argomenti
        .firstWhere((a) => a.title == 'Equazioni di primo grado')
        .lessons
        .first;
    expect(lesson.id, 'eq1-intro');
    expect(lesson.minutes, 5);
    expect(lesson.steps, hasLength(4));
    expect(lesson.steps[0].type, LessonStepType.info);
    expect(lesson.steps[1].type, LessonStepType.info);
    expect(lesson.steps[1].content, contains('::box'));
    expect(lesson.steps[2].type, LessonStepType.info);
    expect(lesson.steps[2].title, 'L\'equazione come intersezione');
    expect(lesson.steps[3].type, LessonStepType.mcq);
    expect(lesson.steps[3].options, hasLength(3));
    expect(lesson.steps[3].correctIndex, 0);
    expect(lesson.steps[3].explanation, isNotEmpty);
    expect(lesson.steps[3].prompt, contains('3x - 1 = 5'));
    expect(lesson.steps[0].prompt, isEmpty);
    expect(LessonStep.fromJson(const {'type': 'info'}).prompt, isEmpty);
  });

  test('content come array appiattisce testo e riquadri', () {
    final lesson = LessonRepository.instance.argomenti
        .firstWhere((a) => a.title == 'Equazioni di primo grado')
        .lessons
        .first;
    final contenuto = lesson.steps[1].content;

    expect(contenuto.contains('# Titolo'), isTrue);
    expect(contenuto.contains('Blocco monostile:'), isTrue);
    expect(contenuto.split('::box').length - 1, 1);
    expect(contenuto.split('::endbox').length - 1, 1);
    expect(contenuto, contains(r'\frac{b}{a}'));
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
    expect(
      find.textContaining('Qual è la soluzione di', findRichText: true),
      findsOneWidget,
    );
  });

  testWidgets('risposta sbagliata scuote, quella giusta spiega e completa', (
    tester,
  ) async {
    final levelId = 'high-school';
    final lesson = await _apriPrimaLezione(tester);
    await _completa(tester);

    expect(
      ProgressStore.instance.isLessonCompleted(levelId, lesson.id),
      isTrue,
    );
    expect(find.text('Lezione completata!'), findsOneWidget);
    expect(find.byType(Lottie), findsOneWidget);
    expect(find.text('Tocca per continuare'), findsOneWidget);
    expect(find.byType(LessonScreen), findsOneWidget);

    await tester.tap(find.text('Lezione completata!'));
    await tester.pumpAndSettle();

    expect(find.byType(LessonScreen), findsNothing);
  });

  testWidgets('la celebrazione del trofeo si chiude da sola', (tester) async {
    await _apriPrimaLezione(tester);
    await _completa(tester);

    expect(find.byType(Lottie), findsOneWidget);

    await tester.pump(_kCelebrationTestDuration);
    await tester.pumpAndSettle();

    expect(find.byType(LessonScreen), findsNothing);
  });

  testWidgets('lo swipe verso sinistra sull\'ultima card completa la lezione', (
    tester,
  ) async {
    const levelId = 'high-school';
    final lesson = await _apriPrimaLezione(tester);
    await _risolviVerifica(tester);

    // sotto soglia la card segue il dito ma la lezione resta aperta
    await tester.drag(find.byType(PageView), const Offset(-40, 0));
    await tester.pump();
    expect(find.byType(LessonScreen), findsOneWidget);
    expect(find.byType(Lottie), findsNothing);
    expect(
      ProgressStore.instance.isLessonCompleted(levelId, lesson.id),
      isFalse,
    );

    await tester.drag(find.byType(PageView), const Offset(-200, 0));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(Lottie), findsOneWidget);
    expect(find.text('Lezione completata!'), findsOneWidget);
    expect(
      ProgressStore.instance.isLessonCompleted(levelId, lesson.id),
      isTrue,
    );
  });

  testWidgets('lo swipe verso sinistra su una card non ultima cambia pagina', (
    tester,
  ) async {
    final lesson = await _apriPrimaLezione(tester);
    await _swipeNext(tester);
    expect(find.text('2 di 4'), findsOneWidget);

    await tester.drag(find.byType(PageView), const Offset(-500, 0));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('3 di 4'), findsOneWidget);
    expect(find.byType(Lottie), findsNothing);
    expect(
      ProgressStore.instance.isLessonCompleted('high-school', lesson.id),
      isFalse,
    );
  });

  testWidgets('lo swipe non completa una verifica non risolta', (tester) async {
    final lesson = await _apriPrimaLezione(tester);
    await _swipeNext(tester);
    await _swipeNext(tester);
    expect(find.text('Verifica'), findsOneWidget);

    await tester.drag(find.byType(PageView), const Offset(-200, 0));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(LessonScreen), findsOneWidget);
    expect(find.byType(Lottie), findsNothing);
    expect(find.widgetWithText(AppButton, 'Completa la lezione'), findsNothing);
    expect(
      ProgressStore.instance.isLessonCompleted('high-school', lesson.id),
      isFalse,
    );
  });

  testWidgets("l'ultimo step di Moduli mostra la card di verifica", (
    tester,
  ) async {
    final lesson = LessonRepository.instance.argomenti
        .firstWhere((a) => a.title == 'Moduli')
        .lessons
        .firstWhere((l) => l.id == 'mod-equations-intro');
    await tester.pumpWidget(
      MaterialApp(
        home: LessonScreen(lesson: lesson, levelId: 'high-school'),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    for (var i = 0; i < lesson.steps.length - 1; i++) {
      await _swipeNext(tester);
    }
    // la PageView assorbe i pointer finché lo scroll non è assestato
    await tester.pump(const Duration(seconds: 3));

    expect(find.byType(PracticeQuizView), findsOneWidget);
    expect(find.text('Verifica'), findsOneWidget);
    // solo il primo esercizio dell'array, con le sue quattro risposte
    expect(find.byType(McqOptionTile), findsNWidgets(4));
    expect(tester.takeException(), isNull);

    // il reload galleggiante estrae un altro esercizio
    final before = tester
        .widget<McqOptionTile>(find.byKey(const ValueKey('quiz_option_0')))
        .label;
    await tester.tap(find.byIcon(Icons.refresh_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(
      tester
          .widget<McqOptionTile>(find.byKey(const ValueKey('quiz_option_0')))
          .label,
      isNot(before),
    );
  });

  testWidgets(
    'sulla verifica il reload sta a sinistra di Completa la lezione',
    (tester) async {
      final lesson = LessonRepository.instance.argomenti
          .firstWhere((a) => a.title == 'Moduli')
          .lessons
          .firstWhere((l) => l.id == 'mod-equations-intro');
      await tester.pumpWidget(
        MaterialApp(
          home: LessonScreen(lesson: lesson, levelId: 'high-school'),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      for (var i = 0; i < lesson.steps.length - 1; i++) {
        await _swipeNext(tester);
      }
      await tester.pump(const Duration(seconds: 3));

      final reload = tester.getTopLeft(find.byIcon(Icons.refresh_rounded));
      final complete = tester.getTopLeft(
        find.widgetWithText(AppButton, 'Completa la lezione'),
      );
      expect(reload.dx, lessThan(complete.dx));
      // il bottone è ancorato al padding interno della card, non a piena larghezza
      final card = tester.widget<AppCard>(find.byType(AppCard).last);
      final padding = (card.padding as EdgeInsets).right;
      final cardRight = tester.getTopRight(find.byType(AppCard).last).dx;
      final completeSize = tester.getSize(
        find.widgetWithText(AppButton, 'Completa la lezione'),
      );
      expect(complete.dx + completeSize.width, closeTo(cardRight - padding, 1));
    },
  );

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

  test('la lezione Modulo e Equazioni con Modulo ha nove card', () {
    final moduli = LessonRepository.instance.argomenti.firstWhere(
      (a) => a.title == 'Moduli',
    );
    final lesson = moduli.lessons.firstWhere(
      (l) => l.id == 'mod-equations-intro',
    );
    expect(lesson.title, 'Modulo e Equazioni con Modulo');
    expect(lesson.minutes, 6);
    expect(lesson.steps, hasLength(9));
    expect(lesson.steps.map((s) => s.title), [
      'Che cos\'è il Modulo?',
      'Esempi pratici',
      'Il modulo in un istogramma',
      'Modulo ed Espressioni Letterali',
      'Esempi pratici',
      'Equazioni con Modulo',
      'Esempio guidato',
      'Prova tu',
      'Verifica',
    ]);
    for (final step in lesson.steps.take(8)) {
      expect(step.type, LessonStepType.info);
      expect(step.content, isNotEmpty);
    }
    final quiz = lesson.steps.last;
    expect(quiz.type, LessonStepType.practiceQuiz);
    expect(quiz.exercises, hasLength(4));
    expect(quiz.content, isEmpty);
    for (final exercise in quiz.exercises) {
      expect(exercise.hasAnswer, isTrue);
    }
    final step1 = lesson.steps[0].content;
    expect(step1.split('::box').length - 1, 1);
    expect(step1, contains(r'\begin{cases}'));
    expect(step1, isNot(contains('Esempi pratici')));
    expect(lesson.steps[5].content, isNot(contains('Esempio guidato')));
    expect(lesson.steps[5].content, isNot(contains('Prova tu')));
    expect(lesson.steps[6].content, contains('x - 5'));
    expect(lesson.steps[6].content, isNot(contains('Prova tu')));
    expect(lesson.steps[7].content, contains('4x'));
    expect(lesson.steps[3].content, contains('x-3'));
    expect(lesson.steps[3].content, isNot(contains('Esempi pratici')));
    expect(lesson.steps[4].content, contains('x = 5'));
    // il nuovo step del grafico sta fra i due esempi e non porta testo
    // copiato da un'altra card
    expect(lesson.steps[2].content, contains('"box_type":"graph"'));
    expect(lesson.steps[2].content, contains('"plane":"bars"'));
  });

  testWidgets('la toolbar compatta è allineata a Completa la lezione', (
    tester,
  ) async {
    final lesson = LessonRepository.instance.argomenti
        .firstWhere((a) => a.title == 'Moduli')
        .lessons
        .firstWhere((l) => l.id == 'mod-equations-intro');
    await tester.pumpWidget(
      MaterialApp(
        home: LessonScreen(lesson: lesson, levelId: 'high-school'),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    for (var i = 0; i < lesson.steps.length - 1; i++) {
      await _swipeNext(tester);
    }
    await tester.pump(const Duration(seconds: 3));

    // `getRect` ritorna i bordi dipinti: il pacchetto include la pila
    // clip-paintata a zero, quindi la larghezza è il lato del FAB compatto,
    // che è quadrato, e l'altezza è quella del bottone.
    final toolbar = tester.getRect(find.byKey(ValueKey('lesson_toolbar')));
    final complete = tester.getRect(
      find.widgetWithText(AppButton, 'Completa la lezione'),
    );
    expect(toolbar.width, closeTo(kToolsBarHeight, 1));
    expect(toolbar.bottom, closeTo(complete.bottom, 0.5));
    // ancorata a sinistra: il FAB dipinto è a filo della colonna di testo
    final textLeft = tester.getTopLeft(find.text('Verifica')).dx;
    expect(toolbar.left, closeTo(textLeft, 0.5));
    // bottone ben a destra
    expect(complete.left, greaterThan(toolbar.left + 100));
  });

  testWidgets('la toolbar ha il colore della barra di avanzamento', (
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

    final barra = tester.widget<M3EProgressIndicator>(
      find.byType(M3EProgressIndicator),
    );
    const key = ValueKey('lesson_toolbar');
    final toolbar = tester.widget<M3EToolbar>(find.byKey(key));
    // Il pannello espanso e il FAB sono dell'indaco della barra; il FAB lo
    // prende dal tema del pacchetto, che non legge il `Theme` di Flutter.
    expect(toolbar.backgroundColor, barra.color);
    final tema = tester.widget<M3ETheme>(
      find.ancestor(of: find.byKey(key), matching: find.byType(M3ETheme)),
    );
    expect(tema.data.colorScheme.primaryContainer, barra.color);
    expect(tema.data.colorScheme.onPrimaryContainer, Colors.white);
  });

  testWidgets('la toolbar galleggia sul fondo della card e il FAB la espande', (
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

    final screen = tester.view.physicalSize / tester.view.devicePixelRatio;
    const key = ValueKey('lesson_toolbar');
    final bar = tester.getRect(find.byKey(key));
    expect(bar.center.dx, lessThan(screen.width / 2));
    expect(bar.bottom, greaterThan(screen.height / 2));

    // sul fondo della card ferma, a filo della sua colonna di testo
    final card = tester.getRect(find.byType(AppCard).first);
    expect(bar.left, greaterThan(card.left));
    expect(bar.bottom, lessThanOrEqualTo(card.bottom));

    // il tap va sull'icona del FAB: il centro del pacchetto include la pila
    // clip-paintata a zero e non sarebbe hittable
    final fabIcon = find.descendant(
      of: find.byKey(key),
      matching: find.byIcon(M3EIcons.handyman_rounded),
    );
    expect(fabIcon, findsOneWidget);
    await tester.tap(fabIcon);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    // il FAB passa all'icona di chiusura e il pacchetto si espande: le rect
    // dipinte non cambiano, perché i paint bounds includono la pila
    // clip-paintata a zero
    expect(tester.widget<M3EToolbar>(find.byKey(key)).expanded, isTrue);
    expect(
      find.descendant(
        of: find.byKey(key),
        matching: find.byIcon(M3EIcons.close_rounded),
      ),
      findsOneWidget,
    );
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

    // una toolbar sola, sopra le card
    expect(find.byType(M3EToolbar), findsOneWidget);
    expect(find.byType(ScientificCalculatorSheet), findsNothing);

    const key = ValueKey('lesson_toolbar');
    await tester.tap(
      find.descendant(
        of: find.byKey(key),
        matching: find.byIcon(M3EIcons.handyman_rounded),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    await tester.tap(
      find.descendant(
        of: find.byKey(key),
        matching: find.byIcon(M3EIcons.calculate_rounded),
      ),
    );
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

  testWidgets('i bottoni galleggiano fuori dalle card e restano fermi', (
    tester,
  ) async {
    final lesson = LessonRepository.instance.argomenti
        .firstWhere((a) => a.title == 'Moduli')
        .lessons
        .firstWhere((l) => l.id == 'mod-equations-intro');
    await tester.pumpWidget(
      MaterialApp(
        home: LessonScreen(lesson: lesson, levelId: 'high-school'),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    const toolbar = ValueKey('lesson_toolbar');
    // nessun bottone dentro una card
    for (final bottone in [find.byKey(toolbar), find.byType(AppButton)]) {
      expect(
        find.descendant(of: find.byType(AppCard), matching: bottone),
        findsNothing,
      );
    }
    // sulla prima card niente reload né «Completa la lezione»
    expect(find.byIcon(Icons.refresh_rounded), findsNothing);
    expect(find.text('Completa la lezione'), findsNothing);
    final prima = tester.getRect(find.byKey(toolbar));

    for (var i = 0; i < lesson.steps.length - 1; i++) {
      await _swipeNext(tester);
    }
    await tester.pump(const Duration(seconds: 3));

    // la toolbar non si è mossa con le card; sulla verifica, l'ultima card,
    // compaiono reload e «Completa la lezione»
    expect(tester.getRect(find.byKey(toolbar)), prima);
    expect(find.byIcon(Icons.refresh_rounded), findsOneWidget);
    expect(find.text('Completa la lezione'), findsOneWidget);
  });
}
