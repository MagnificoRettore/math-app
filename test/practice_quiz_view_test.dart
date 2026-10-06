import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_app/models/lesson_step.dart';
import 'package:math_app/models/practice_exercise.dart';
import 'package:math_app/widgets/app_card.dart';
import 'package:math_app/widgets/mcq_option_tile.dart';
import 'package:math_app/widgets/practice_quiz_view.dart';

Map<String, dynamic> _step(List<Map<String, dynamic>> exercises) => {
  'type': 'practice_quiz',
  'title': 'Verifica',
  'exercises': exercises,
};

Map<String, dynamic> _exercise(
  String prompt, {
  String text = '',
  required List<String> options,
  int correctIndex = 0,
  String explanation = '',
}) => {
  'prompt': prompt,
  if (text.isNotEmpty) 'text': text,
  'options': options,
  'correctIndex': correctIndex,
  if (explanation.isNotEmpty) 'explanation': explanation,
};

final _threeExercises = _step([
  _exercise(
    r'$$3x - 1 = 5$$',
    text: 'Primo esercizio',
    options: ['Opzione A', 'Opzione B'],
    explanation: 'Spiegazione del primo',
  ),
  _exercise(
    r'$$2y + 4 = 0$$',
    text: 'Secondo esercizio',
    options: ['Terzo esercizio', 'Opzione D'],
    correctIndex: 1,
  ),
  _exercise(r'$$z^2 = 9$$', text: 'Terzo esercizio', options: ['Opzione E']),
]);

final _oneExercise = _step([
  _exercise(r'$$a + b$$', text: 'Unico esercizio', options: ['Opzione F']),
]);

final _oneExercise2 = _step([
  _exercise(r'$$a + b$$', options: ['Giusta', 'Errata 1', 'Errata 2']),
]);

List<PracticeExercise> _parse(Map<String, dynamic> stepJson) =>
    LessonStep.fromJson(stepJson).exercises;

/// La card di verifica è uno step di lezione: qui la montiamo dentro una
/// `AppCard` come fa `_StepCard`, senza la `PageView` del player.
Widget _host(
  Map<String, dynamic> stepJson, {
  GlobalKey<PracticeQuizViewState>? key,
}) {
  return MaterialApp(
    home: Scaffold(
      body: AppCard(
        child: PracticeQuizView(key: key, exercises: _parse(stepJson)),
      ),
    ),
  );
}

Future<void> _pump(WidgetTester tester, Map<String, dynamic> stepJson) async {
  await tester.pumpWidget(_host(stepJson));
  await tester.pump();
}

/// Avanza la transizione dell'`AnimatedSwitcher`: il primo `pump()` costruisce
/// il frame in cui la transizione parte, il secondo la porta a fine.
Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

String _label(WidgetTester tester, int index) => tester
    .widget<McqOptionTile>(find.byKey(ValueKey('quiz_option_$index')))
    .label;

void main() {
  Finder rich(String text) => find.text(text, findRichText: true);

  test('canReload richiede più di un esercizio', () {
    expect(PracticeQuizView(exercises: const []).canReload, isFalse);
    expect(
      PracticeQuizView(exercises: _parse(_oneExercise)).canReload,
      isFalse,
    );
    expect(
      PracticeQuizView(exercises: _parse(_threeExercises)).canReload,
      isTrue,
    );
  });

  test('lo step practice_quiz parsifica gli esercizi', () {
    final step = LessonStep.fromJson(_threeExercises);
    expect(step.type, LessonStepType.practiceQuiz);
    expect(step.isPracticeQuiz, isTrue);
    expect(step.isQuestion, isFalse);
    expect(step.exercises, hasLength(3));
    final first = step.exercises.first;
    expect(first.prompt, r'$$3x - 1 = 5$$');
    expect(first.text, 'Primo esercizio');
    expect(first.options, ['Opzione A', 'Opzione B']);
    expect(first.correctIndex, 0);
    expect(first.explanation, 'Spiegazione del primo');
    expect(first.hasAnswer, isTrue);
    expect(step.exercises[1].correctIndex, 1);
  });

  test('hasAnswer falso se correctIndex fuori range o assente', () {
    final outOfRange = PracticeExercise.fromJson(const {
      'prompt': 'x',
      'options': ['a', 'b'],
      'correctIndex': 7,
    });
    expect(outOfRange.hasAnswer, isFalse);

    final missing = PracticeExercise.fromJson(const {
      'prompt': 'x',
      'options': ['a', 'b'],
    });
    expect(missing.correctIndex, -1);
    expect(missing.hasAnswer, isFalse);
  });

  test('text ed explanation vuoti non finiscono nel json', () {
    const exercise = PracticeExercise(
      prompt: r'$$x$$',
      options: ['a'],
      correctIndex: 0,
    );
    final json = exercise.toJson();
    expect(json.containsKey('text'), isFalse);
    expect(json.containsKey('explanation'), isFalse);
    expect(json['prompt'], r'$$x$$');
  });

  group('card practice_quiz', () {
    testWidgets('mostra un solo esercizio alla volta', (tester) async {
      await _pump(tester, _threeExercises);
      expect(tester.takeException(), isNull);

      expect(find.byType(McqOptionTile), findsNWidgets(2));
      expect(rich('Primo esercizio'), findsOneWidget);
      expect(rich('Secondo esercizio'), findsNothing);
      expect(rich('Terzo esercizio'), findsNothing);
      expect(rich('Opzione A'), findsOneWidget);
      expect(rich('Opzione B'), findsOneWidget);
    });

    testWidgets('risposta sbagliata poi giusta mostra i due esiti', (
      tester,
    ) async {
      await _pump(tester, _threeExercises);

      await tester.tap(find.byKey(const ValueKey('quiz_option_1')));
      await _settle(tester);
      expect(find.text('Non è corretto'), findsOneWidget);
      expect(find.text('Corretto!'), findsNothing);

      await tester.tap(find.byKey(const ValueKey('quiz_option_0')));
      await _settle(tester);
      expect(find.text('Corretto!'), findsOneWidget);
      expect(find.text('Non è corretto'), findsNothing);
      expect(rich('Spiegazione del primo'), findsOneWidget);
    });

    testWidgets('il reload cambia esercizio e azzera le risposte', (
      tester,
    ) async {
      final key = GlobalKey<PracticeQuizViewState>();
      await tester.pumpWidget(_host(_threeExercises, key: key));

      await tester.tap(find.byKey(const ValueKey('quiz_option_0')));
      await _settle(tester);
      expect(find.text('Corretto!'), findsOneWidget);
      final before = _label(tester, 0);

      key.currentState!.reload();
      await _settle(tester);

      expect(find.text('Corretto!'), findsNothing);
      expect(rich('Primo esercizio'), findsNothing);
      final option = tester.widget<McqOptionTile>(
        find.byKey(const ValueKey('quiz_option_0')),
      );
      // la coda è mescolata: conta che sia un altro esercizio, non quale
      expect(option.label, isNot(before));
      expect(option.state, McqOptionState.idle);
      expect(find.text('Non è corretto'), findsNothing);
    });

    testWidgets('il reload non ripete lo stesso esercizio prima del giro', (
      tester,
    ) async {
      final key = GlobalKey<PracticeQuizViewState>();
      await tester.pumpWidget(_host(_threeExercises, key: key));
      final seen = <String>{_label(tester, 0)};
      for (var tap = 0; tap < 2; tap++) {
        key.currentState!.reload();
        await _settle(tester);
        final label = _label(tester, 0);
        expect(seen.add(label), isTrue, reason: 'ripetuto $label');
      }
      expect(seen, hasLength(3));
    });

    testWidgets("a coda svuotata il refill non ripete l'esercizio uscente", (
      tester,
    ) async {
      final key = GlobalKey<PracticeQuizViewState>();
      await tester.pumpWidget(_host(_threeExercises, key: key));

      var previous = _label(tester, 0);
      // 3 esercizi: il terzo reload esaurisce la coda iniziale e passa dal ramo
      // di refill, che esclude l'esercizio corrente.
      for (var tap = 0; tap < 3; tap++) {
        key.currentState!.reload();
        await _settle(tester);
        final label = _label(tester, 0);
        expect(label, isNot(previous));
        previous = label;
      }
    });

    testWidgets('con un solo esercizio il reload non fa nulla', (tester) async {
      final key = GlobalKey<PracticeQuizViewState>();
      await tester.pumpWidget(_host(_oneExercise, key: key));

      key.currentState!.reload();
      await _settle(tester);

      expect(tester.takeException(), isNull);
      expect(rich('Unico esercizio'), findsOneWidget);
      expect(rich('Opzione F'), findsOneWidget);
    });

    testWidgets('il prompt immagine usa il placeholder, il testo MathText', (
      tester,
    ) async {
      await _pump(
        tester,
        _step([
          _exercise('assets/images/missing.png', options: ['Opzione G']),
        ]),
      );
      expect(tester.takeException(), isNull);
      expect(find.byIcon(Icons.image_outlined), findsOneWidget);

      await _pump(tester, _threeExercises);
      expect(find.byIcon(Icons.image_outlined), findsNothing);
      expect(find.byType(Math), findsWidgets);
      expect(rich('Primo esercizio'), findsOneWidget);
    });

    testWidgets('il tap non fa nulla se correctIndex è fuori range', (
      tester,
    ) async {
      await _pump(
        tester,
        _step([
          _exercise(
            r'$$v$$',
            text: 'Senza risposta',
            options: ['Opzione L', 'Opzione M'],
            correctIndex: 7,
          ),
        ]),
      );

      await tester.tap(find.byKey(const ValueKey('quiz_option_1')));
      await _settle(tester);
      expect(find.text('Corretto!'), findsNothing);
      expect(find.text('Non è corretto'), findsNothing);
      expect(
        tester
            .widget<McqOptionTile>(find.byKey(const ValueKey('quiz_option_1')))
            .state,
        McqOptionState.idle,
      );
    });
  });

  group('esiti per il badge', () {
    Future<List<(int, bool)>> provaRisposte(
      WidgetTester tester,
      List<int> tocchi,
    ) async {
      final esiti = <(int, bool)>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PracticeQuizView(
              exercises: _parse(_oneExercise2),
              onAnswered: (exercise, correct) => esiti.add((exercise, correct)),
            ),
          ),
        ),
      );
      await tester.pump();
      for (final i in tocchi) {
        await tester.tap(find.byKey(ValueKey('quiz_option_$i')));
        await tester.pump(const Duration(milliseconds: 400));
      }
      return esiti;
    }

    testWidgets('giusta al primo colpo: un esito giusto', (tester) async {
      expect(await provaRisposte(tester, [0]), [(0, true)]);
    });

    testWidgets('sbagliata e poi giusta: solo l\'errore, una volta sola', (
      tester,
    ) async {
      expect(await provaRisposte(tester, [1, 2, 0]), [(0, false)]);
    });
  });
}
