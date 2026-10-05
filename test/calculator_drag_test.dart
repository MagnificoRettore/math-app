import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:math_app/widgets/scientific_calculator.dart';

void main() {
  const sheet = ValueKey('calc-sheet');

  Future<bool> pump(WidgetTester tester) async {
    var closed = false;
    tester.view
      ..physicalSize = const Size(1400, 1600)
      ..devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ScientificCalculatorSheet(onClose: () => closed = true),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));
    return closed;
  }

  testWidgets('trascinata giù segue il dito e, lasciata presto, torna su', (
    tester,
  ) async {
    await pump(tester);
    final riposo = tester.getTopLeft(find.text('Calcolatrice')).dy;

    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(sheet)),
    );
    // Prima la soglia del tocco (kTouchSlop), poi il trascinamento vero.
    await gesture.moveBy(const Offset(0, 24));
    await tester.pump();
    await gesture.moveBy(const Offset(0, 60));
    await tester.pump();
    // Si vede il contenuto dietro: la calcolatrice è scesa con il dito.
    final sceso = tester.getTopLeft(find.text('Calcolatrice')).dy - riposo;
    expect(sceso, greaterThan(50));

    await gesture.moveBy(const Offset(0, -20));
    await tester.pump();
    expect(
      tester.getTopLeft(find.text('Calcolatrice')).dy - riposo,
      closeTo(sceso - 20, 1),
    );

    await gesture.up();
    await tester.pumpAndSettle();
    expect(find.byType(ScientificCalculatorSheet), findsOneWidget);
    expect(tester.getTopLeft(find.text('Calcolatrice')).dy, riposo);
  });

  testWidgets('lasciata oltre la soglia si chiude', (tester) async {
    var closed = false;
    tester.view
      ..physicalSize = const Size(1400, 1600)
      ..devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ScientificCalculatorSheet(onClose: () => closed = true),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));

    final altezza = tester.getSize(find.byKey(sheet)).height;
    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(sheet)),
    );
    await gesture.moveBy(const Offset(0, 24));
    await tester.pump();
    await gesture.moveBy(Offset(0, altezza * 0.5));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
    expect(closed, isTrue);
  });

  testWidgets('verso l\'alto non si muove', (tester) async {
    await pump(tester);
    final riposo = tester.getTopLeft(find.text('Calcolatrice')).dy;
    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(sheet)),
    );
    await gesture.moveBy(const Offset(0, -24));
    await tester.pump();
    await gesture.moveBy(const Offset(0, -80));
    await tester.pump();
    expect(tester.getTopLeft(find.text('Calcolatrice')).dy, riposo);
    await gesture.up();
  });
}
