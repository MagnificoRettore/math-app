import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:math_app/data/auth_store.dart';
import 'package:math_app/data/math_facts.dart';
import 'package:math_app/data/progress_store.dart';
import 'package:math_app/data/settings_store.dart';
import 'package:math_app/models/practice_exercise.dart';
import 'package:math_app/screens/customization_screen.dart';
import 'package:math_app/widgets/expression_evaluator.dart';
import 'package:math_app/widgets/math_fact_card.dart';
import 'package:math_app/widgets/practice_quiz_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AuthStore.instance.resetForTest();
    await SettingsStore.instance.resetForTest();
    await ProgressStore.instance.resetForTest();
  });

  group('progressi per utente', () {
    test('ogni utente e l\'ospite hanno i propri progressi', () async {
      final store = ProgressStore.instance;
      await store.completeLesson('high-school', 'l1');
      expect(store.isLessonCompleted('high-school', 'l1'), isTrue);

      await AuthStore.instance.registerManual(
        name: 'Anna',
        email: 'anna@example.com',
        accountId: 'anna',
        password: 'Segreta1',
        schoolLevelId: 'high-school',
      );
      expect(store.isLessonCompleted('high-school', 'l1'), isFalse);
      await store.completeLesson('high-school', 'l2');
      expect(store.isLessonCompleted('high-school', 'l2'), isTrue);

      await AuthStore.instance.signOut();
      expect(store.isLessonCompleted('high-school', 'l1'), isTrue);
      expect(store.isLessonCompleted('high-school', 'l2'), isFalse);
    });

    test('un salvataggio di prima diventa dell\'ospite', () async {
      SharedPreferences.setMockInitialValues({
        'lessons_completed_v1': ['high-school::vecchia'],
      });
      await ProgressStore.instance.resetForTest();
      expect(
        ProgressStore.instance.isLessonCompleted('high-school', 'vecchia'),
        isTrue,
      );
    });
  });

  group('calcolatrice', () {
    test('il rumore del double vale zero', () {
      expect(ExpressionEvaluator.tryEvaluate('sin(180)', deg: true), 0);
      expect(ExpressionEvaluator.tryEvaluate('sin(900)', deg: true), 0);
      expect(ExpressionEvaluator.tryEvaluate('cos(90)', deg: true), 0);
    });

    test('la tangente dove non esiste è un errore', () {
      expect(ExpressionEvaluator.tryEvaluate('tan(90)', deg: true), isNull);
      expect(ExpressionEvaluator.tryEvaluate('tan(270)', deg: true), isNull);
      expect(
        ExpressionEvaluator.tryEvaluate('tan(45)', deg: true),
        closeTo(1, 1e-9),
      );
    });
  });

  testWidgets('due risposte sbagliate consigliano di rileggere', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PracticeQuizView(
            exercises: [
              PracticeExercise(
                prompt: 'Quanto fa 1 + 1?',
                options: ['1', '2', '3', '4'],
                correctIndex: 1,
              ),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('quiz_option_0')));
    await tester.pumpAndSettle();
    expect(find.textContaining('rileggi', findRichText: true), findsNothing);

    await tester.tap(find.byKey(const ValueKey('quiz_option_2')));
    await tester.pumpAndSettle();
    expect(find.textContaining('rileggi', findRichText: true), findsOneWidget);
  });

  testWidgets(
    'la guida si apre dalle impostazioni e non segna il primo avvio',
    (tester) async {
      await tester.pumpWidget(const MaterialApp(home: CustomizationScreen()));
      await tester.tap(find.byKey(const Key('open-guide')));
      await tester.pumpAndSettle();
      expect(find.text('Tre sezioni'), findsOneWidget);

      for (var i = 0; i < 4; i++) {
        await tester.tap(find.text('Avanti'));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.text('Ho capito'));
      await tester.pumpAndSettle();

      expect(find.byType(CustomizationScreen), findsOneWidget);
      expect(SettingsStore.instance.onboardingSeen, isFalse);
    },
  );

  testWidgets('la curiosità nuova si scrive a macchina', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: MathFactCard())),
    );
    final first = tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data ?? t.textSpan?.toPlainText() ?? '')
        .firstWhere(mathFacts.contains);
    final next = mathFacts[(mathFacts.indexOf(first) + 1) % mathFacts.length];

    await tester.tap(find.byKey(const Key('math-fact-card')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    // A metà il testo c'è già tutto ma una parte è ancora trasparente.
    final spans = tester
        .widgetList<Text>(find.byType(Text))
        .where((t) => t.textSpan?.toPlainText() == next)
        .single
        .textSpan!;
    expect((spans as TextSpan).children, hasLength(2));
    expect((spans.children![1] as TextSpan).text, isNotEmpty);

    await tester.pumpAndSettle();
    expect(find.text(next), findsOneWidget);
  });
}
