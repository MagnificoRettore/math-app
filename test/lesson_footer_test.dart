import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:math_app/data/lesson_repository.dart';
import 'package:math_app/data/progress_store.dart';
import 'package:math_app/screens/lesson_screen.dart';
import 'package:math_app/widgets/app_button.dart';
import 'package:math_app/widgets/math_text.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LessonRepository.instance.resetForTest();
    await ProgressStore.instance.resetForTest();
  });

  /// Le rette: l'ultima card è una verifica con più esercizi, quindi il piede
  /// ha insieme il reload e «Completa la lezione».
  Future<void> apriVerifica(WidgetTester tester, {double width = 400}) async {
    final lesson = LessonRepository.instance.argomenti
        .firstWhere((a) => a.title == 'Le rette')
        .lessons
        .single;
    tester.view
      ..physicalSize = Size(width, 800)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: LessonScreen(lesson: lesson, levelId: 'high-school'),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    for (var i = 0; i < lesson.steps.length - 1; i++) {
      await tester.drag(find.byType(PageView), const Offset(-500, 0));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
    }
    await tester.pump(const Duration(seconds: 1));
  }

  // Si provano le opzioni finché non compare «Completa la lezione».
  Future<void> risolvi(WidgetTester tester) async {
    for (var i = 0; i < 4; i++) {
      if (find.byIcon(Icons.check_circle_outline).evaluate().isNotEmpty) break;
      final opzione = find.byKey(ValueKey('quiz_option_$i'));
      if (opzione.evaluate().isEmpty) continue;
      await tester.ensureVisible(opzione);
      await tester.tap(opzione, warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 400));
    }
    await tester.pump(const Duration(seconds: 1));
  }

  /// Di quanto la faccia del bottone è scesa (0 su, 5 giù).
  double scesa(WidgetTester tester, Finder button) {
    final container = tester.widget<AnimatedContainer>(
      find.descendant(of: button, matching: find.byType(AnimatedContainer)),
    );
    return container.transform!.getTranslation().y;
  }

  testWidgets('il reload simula la pressione', (tester) async {
    await apriVerifica(tester);
    final reload = find.widgetWithIcon(AppButton, Icons.refresh_rounded);
    expect(scesa(tester, reload), 0);

    final gesture = await tester.startGesture(tester.getCenter(reload));
    await tester.pump(const Duration(milliseconds: 400));
    expect(scesa(tester, reload), AppButton.depth);
    await gesture.cancel();
    await tester.pump(const Duration(milliseconds: 400));
    expect(scesa(tester, reload), 0);
  });

  testWidgets('Completa la lezione simula la pressione', (tester) async {
    await apriVerifica(tester);
    await risolvi(tester);
    final complete = find.widgetWithIcon(AppButton, Icons.check_circle_outline);
    expect(complete, findsOneWidget);
    expect(scesa(tester, complete), 0);

    final gesture = await tester.startGesture(tester.getCenter(complete));
    await tester.pump(const Duration(milliseconds: 400));
    expect(scesa(tester, complete), AppButton.depth);
    await gesture.cancel();
    await tester.pump(const Duration(milliseconds: 400));
    expect(scesa(tester, complete), 0);
  });

  for (final width in [320.0, 360.0, 400.0]) {
    testWidgets('il piede non sfora su ${width.toInt()} px', (tester) async {
      await apriVerifica(tester, width: width);
      await risolvi(tester);

      expect(tester.takeException(), isNull);
      // Reload e «Completa la lezione» stanno dentro la colonna della card.
      final card = tester.getRect(find.byType(PageView));
      for (final finder in [
        find.byIcon(Icons.refresh_rounded),
        find.byIcon(Icons.check_circle_outline),
      ]) {
        final r = tester.getRect(finder);
        expect(r.left, greaterThanOrEqualTo(card.left));
        expect(r.right, lessThanOrEqualTo(card.right));
      }
    });
  }

  test('la matematica in linea sta sulla linea di base del testo', () {
    final span = mathSpan(r'$y$', fontSize: 15, color: Colors.black);
    expect(span, isA<WidgetSpan>());
    // Con `middle` le lettere stavano alte e piccole come un apice.
    expect((span as WidgetSpan).alignment, PlaceholderAlignment.baseline);
    expect(span.baseline, TextBaseline.alphabetic);
  });
}
