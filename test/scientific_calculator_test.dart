import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_app/widgets/scientific_calculator.dart';

Future<void> _pump(WidgetTester tester, {VoidCallback? onClose}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Stack(
          children: [
            SingleChildScrollView(child: Container(height: 800)),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: ScientificCalculatorSheet(onClose: onClose ?? () {}),
            ),
          ],
        ),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 300));
}

String _result(WidgetTester tester) {
  return tester.widget<Text>(find.byKey(const ValueKey('calc-result'))).data!;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('somma 2 + 3 = 5', (tester) async {
    await _pump(tester);
    await tester.tap(find.text('2'));
    await tester.tap(find.text('+'));
    await tester.tap(find.text('3'));
    await tester.tap(find.text('='));
    await tester.pump();
    expect(_result(tester), '5');
  });

  testWidgets('funzione scientifica sqrt(16) = 4', (tester) async {
    await _pump(tester);
    await tester.tap(find.text('√'));
    await tester.tap(find.text('1'));
    await tester.tap(find.text('6'));
    await tester.tap(find.text(')'));
    await tester.tap(find.text('='));
    await tester.pump();
    expect(_result(tester), '4');
  });

  testWidgets('AC azzera la calcolatrice', (tester) async {
    await _pump(tester);
    await tester.tap(find.text('1'));
    await tester.tap(find.text('2'));
    await tester.tap(find.text('3'));
    await tester.tap(find.text('AC'));
    await tester.pump();
    expect(_result(tester), '0');
  });

  testWidgets('errore mostra Errore', (tester) async {
    await _pump(tester);
    await tester.tap(find.text('√'));
    await tester.tap(find.text('='));
    await tester.pump();
    expect(_result(tester), 'Errore');
  });

  testWidgets('trascinando giù la sheet si chiude', (tester) async {
    var closed = false;
    await _pump(tester, onClose: () => closed = true);
    await tester.drag(
      find.byType(ScientificCalculatorSheet),
      const Offset(0, 220),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(closed, isTrue);
  });

  testWidgets('drag piccolo riporta la sheet su', (tester) async {
    var closed = false;
    await _pump(tester, onClose: () => closed = true);
    await tester.drag(
      find.byType(ScientificCalculatorSheet),
      const Offset(0, 40),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(closed, isFalse);
  });

  testWidgets('il contenuto sopra la sheet resta scrollabile', (tester) async {
    final controller = ScrollController();
    var closed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              ListView(
                controller: controller,
                children: [
                  for (var i = 0; i < 30; i++)
                    SizedBox(height: 100, child: Text('riga $i')),
                ],
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: ScientificCalculatorSheet(onClose: () => closed = true),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    final rectBefore = tester.getRect(find.byType(ScientificCalculatorSheet));
    await tester.dragFrom(
      Offset(400, rectBefore.top - 60),
      const Offset(0, -300),
    );
    await tester.pump();

    expect(controller.offset, greaterThan(0));
    expect(closed, isFalse);
    expect(
      tester.getRect(find.byType(ScientificCalculatorSheet)),
      rectBefore,
    );

    controller.dispose();
  });
}
