import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:math_app/data/content_repository.dart';
import 'package:math_app/data/progress_store.dart';
import 'package:math_app/data/study_store.dart';
import 'package:math_app/models/exercise.dart';
import 'package:math_app/models/exercise_step.dart';
import 'package:math_app/screens/exercise_detail_screen.dart';
import 'package:math_app/theme/app_theme.dart';
import 'package:math_app/widgets/exercise_step_card.dart';
import 'package:math_app/widgets/guided_solution.dart';
import 'package:math_app/widgets/mcq_option_tile.dart';

Exercise _esercizio(List<Object> steps) => Exercise.fromJson({
  'id': 'x',
  'title': 'X',
  'difficulty': 'easy',
  'problem': 'p',
  'steps': steps,
});

Map<String, Object> _passo(String testo, int giusta) => {
  'prompt': 'Domanda per $testo',
  'options': ['A $testo', 'B $testo', 'C $testo'],
  'correctIndex': giusta,
  'text': testo,
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('modello', () {
    test('una stringa è un passaggio di solo testo', () {
      final e = _esercizio(['Solo testo']);
      expect(e.steps.single.text, 'Solo testo');
      expect(e.steps.single.isGuided, isFalse);
      expect(e.isGuided, isFalse);
    });

    test('un oggetto con opzioni e risposta è un passaggio guidato', () {
      final e = _esercizio([_passo('uno', 1), _passo('due', 2)]);
      expect(e.steps.first.question!.correctIndex, 1);
      expect(e.steps.first.text, 'uno');
      expect(e.isGuided, isTrue);
    });

    test('con un passaggio senza domanda la soluzione non è guidata', () {
      final e = _esercizio([_passo('uno', 0), 'Solo testo']);
      expect(e.isGuided, isFalse);
    });

    test('una risposta giusta fuori dalle opzioni non vale', () {
      final e = _esercizio([_passo('uno', 7)]);
      expect(e.isGuided, isFalse);
    });

    test('senza passaggi non è guidata', () {
      expect(_esercizio(const []).isGuided, isFalse);
    });

    test('ExerciseStep.fromJson accetta stringa e mappa', () {
      expect(ExerciseStep.fromJson('a').text, 'a');
      expect(ExerciseStep.fromJson(_passo('b', 0)).isGuided, isTrue);
    });
  });

  group('soluzione guidata', () {
    Future<void> pump(WidgetTester tester, List<ExerciseStep> steps) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: SingleChildScrollView(child: GuidedSolution(steps: steps)),
          ),
        ),
      );
    }

    final steps = [
      ExerciseStep.fromJson(_passo('uno', 1)),
      ExerciseStep.fromJson(_passo('due', 0)),
    ];

    Finder opzione(int i) => find.byKey(ValueKey('guided-option-$i'));

    McqOptionState stato(WidgetTester tester, int i) =>
        tester.widget<McqOptionTile>(opzione(i)).state;

    testWidgets('all\'inizio c\'è solo la prima domanda', (tester) async {
      await pump(tester, steps);
      expect(find.text('Passaggio 1 di 2'), findsOneWidget);
      expect(find.byType(ExerciseStepCard), findsNothing);
      expect(find.text('Passaggio 2 di 2'), findsNothing);
    });

    testWidgets('una risposta sbagliata si segna e non fa avanzare', (
      tester,
    ) async {
      await pump(tester, steps);
      await tester.tap(opzione(0));
      await tester.pump();

      expect(stato(tester, 0), McqOptionState.wrong);
      expect(find.text('Passaggio 1 di 2'), findsOneWidget);
      expect(find.byType(ExerciseStepCard), findsNothing);

      // Si riprova: l'opzione sbagliata resta segnata, quella giusta passa.
      await tester.tap(opzione(1));
      await tester.pump();
      expect(stato(tester, 0), McqOptionState.wrong);
      expect(stato(tester, 1), McqOptionState.correct);
      await tester.pumpAndSettle();
    });

    testWidgets('indovinata, il passaggio si appende e arriva la domanda '
        'dopo', (tester) async {
      await pump(tester, steps);
      await tester.tap(opzione(1));
      await tester.pump();
      // La risposta giusta resta un attimo in vista, poi avanza.
      expect(find.byType(ExerciseStepCard), findsNothing);
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpAndSettle();

      expect(find.byType(ExerciseStepCard), findsOneWidget);
      expect(find.text('uno', findRichText: true), findsOneWidget);
      expect(find.text('Passaggio 2 di 2'), findsOneWidget);
    });

    testWidgets('finiti i passaggi la soluzione è completa', (tester) async {
      await pump(tester, steps);
      await tester.tap(opzione(1));
      await tester.pumpAndSettle(const Duration(milliseconds: 800));
      await tester.tap(opzione(0));
      await tester.pumpAndSettle(const Duration(milliseconds: 800));

      expect(find.byType(ExerciseStepCard), findsNWidgets(2));
      expect(find.text('Corretto!'), findsOneWidget);
      expect(find.textContaining('passo dopo passo', findRichText: true), findsOneWidget);
      expect(find.byType(McqOptionTile), findsNothing);
    });

    testWidgets('col movimento ridotto il passaggio si appende subito', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: true),
              child: Scaffold(body: GuidedSolution(steps: steps)),
            ),
          ),
        ),
      );
      await tester.tap(opzione(1));
      await tester.pump();
      await tester.pump();
      expect(find.byType(ExerciseStepCard), findsOneWidget);
    });
  });

  group('pagina dell\'esercizio', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await ContentRepository.instance.resetForTest();
      await ProgressStore.instance.resetForTest();
      await StudyStore.instance.resetForTest();
    });

    Future<void> apri(WidgetTester tester, String id) async {
      final level = ContentRepository.instance.levels.firstWhere(
        (l) => l.courses.any(
          (c) => c.topics.any((t) => t.exercises.any((e) => e.id == id)),
        ),
      );
      final course = level.courses.firstWhere(
        (c) => c.topics.any((t) => t.exercises.any((e) => e.id == id)),
      );
      final topic = course.topics.firstWhere(
        (t) => t.exercises.any((e) => e.id == id),
      );
      final exercise = topic.exercises.firstWhere((e) => e.id == id);
      tester.view.physicalSize = const Size(400, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: ExerciseDetailScreen(
            level: level,
            course: course,
            topic: topic,
            exercise: exercise,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
    }

    testWidgets('un esercizio guidato mostra una domanda alla volta', (
      tester,
    ) async {
      await apri(tester, 'eq-medium-1');
      expect(find.byType(GuidedSolution), findsOneWidget);
      expect(find.text('Passaggio 1 di 4'), findsOneWidget);
      expect(find.byType(ExerciseStepCard), findsNothing);
      // I pulsanti di stato restano, in fondo.
      expect(find.text('Assimilato'), findsOneWidget);
    });

    testWidgets('un esercizio senza domande ha la soluzione di sempre', (
      tester,
    ) async {
      await apri(tester, 'mod-easy-1');
      expect(find.byType(GuidedSolution), findsNothing);
      expect(find.byType(ExerciseStepCard), findsNWidgets(3));
    });

    testWidgets('si risolve l\'equazione fino in fondo', (tester) async {
      await apri(tester, 'ms-eq-1');
      for (final giusta in [1, 1, 2]) {
        await tester.tap(find.byKey(ValueKey('guided-option-$giusta')));
        await tester.pumpAndSettle(const Duration(milliseconds: 800));
      }
      expect(find.byType(ExerciseStepCard), findsNWidgets(3));
      expect(find.textContaining('passo dopo passo', findRichText: true), findsOneWidget);
    });
  });
}
