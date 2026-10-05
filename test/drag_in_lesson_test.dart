import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:math_app/data/lesson_repository.dart';
import 'package:math_app/models/multifunction_box/box_payload.dart';
import 'package:math_app/screens/lesson_screen.dart';
import 'package:math_app/widgets/graph/graph_painter.dart';

/// Il trascinamento di un punto dentro una lezione vera: la card ha una
/// `PageView` (swipe orizzontale) e uno scroll verticale, e il dito sul punto
/// deve muovere il punto, non cambiare card né scorrere.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LessonRepository.instance.resetForTest();
  });

  testWidgets('il punto si trascina e la card non cambia', (tester) async {
    final lesson = LessonRepository.instance.argomenti
        .expand((a) => a.lessons)
        .firstWhere((l) => l.id == 'ex-arg-interattivi');
    tester.view
      ..physicalSize = const Size(400, 900)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: LessonScreen(lesson: lesson, levelId: 'high-school'),
      ),
    );
    for (var i = 0; i < 2; i++) {
      await tester.pump(const Duration(milliseconds: 600));
      await tester.drag(find.byType(PageView), const Offset(-380, 0));
    }
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Due punti da trascinare'), findsOneWidget);

    // Le card vicine sono costruite anch'esse: il grafico di quella aperta è
    // l'ultimo.
    GraphXY a() {
      final canvas = tester.widget<CustomPaint>(
        find.byKey(const Key('graph-canvas')).last,
      );
      final payload = (canvas.painter! as CartesianPainter).payload;
      return (payload.items[1] as GraphPoint).at;
    }

    final before = a();

    final handle = find.byKey(const Key('drag-1'));
    final gesture = await tester.startGesture(tester.getCenter(handle));
    for (var i = 0; i < 20; i++) {
      await gesture.moveBy(const Offset(5, 3));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await gesture.up();
    await tester.pump(const Duration(milliseconds: 600));

    // Il punto si è mosso (a destra e in basso, come il dito)…
    expect(a().x, greaterThan(before.x));
    expect(a().y, lessThan(before.y));
    // …e la lezione è ancora sulla stessa card.
    expect(find.text('Due punti da trascinare'), findsOneWidget);
    expect(find.text('3 di 3'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
