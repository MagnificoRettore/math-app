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
            Positioned.fill(
              child: ScientificCalculatorSheet(onClose: onClose ?? () {}),
            ),
          ],
        ),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 300));
}

Finder _sheet() => find.byKey(const ValueKey('calc-sheet'));

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

  testWidgets('√(16 senza chiusa: la parentesi si chiude e risolve', (tester) async {
    await _pump(tester);
    await tester.tap(find.text('√'));
    await tester.tap(find.text('1'));
    await tester.tap(find.text('6'));
    await tester.tap(find.text('='));
    await tester.pump();
    expect(_result(tester), '4');
    final expr = tester
        .widget<Text>(find.byKey(const ValueKey('calc-expr')))
        .data!;
    expect(expr, '√(16)');
  });

  testWidgets('(2+3 senza chiusa: si chiude e risolve', (tester) async {
    await _pump(tester);
    await tester.tap(find.text('('));
    await tester.tap(find.text('2'));
    await tester.tap(find.text('+'));
    await tester.tap(find.text('3'));
    await tester.tap(find.text('='));
    await tester.pump();
    expect(_result(tester), '5');
  });

  testWidgets('settaggio angoli: default RAD, tap passa a DEG', (tester) async {
    await _pump(tester);
    expect(find.text('RAD'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('calc-mode')));
    await tester.pump();
    expect(find.text('DEG'), findsOneWidget);
    expect(find.text('RAD'), findsNothing);
  });

  testWidgets('in DEG sin(30) = 0.5', (tester) async {
    await _pump(tester);
    await tester.tap(find.byKey(const ValueKey('calc-mode')));
    await tester.pump();
    await tester.tap(find.text('sin'));
    await tester.tap(find.text('3').last);
    await tester.tap(find.text('0').last);
    await tester.tap(find.text('='));
    await tester.pump();
    expect(_result(tester), '0.5');
  });

  testWidgets('espressione e risultato sono allineati a destra', (tester) async {
    await _pump(tester);
    final displayRect = tester.getRect(find.byKey(const ValueKey('calc-display')));
    final expr = tester.getRect(find.byKey(const ValueKey('calc-expr')));
    final result = tester.getRect(find.byKey(const ValueKey('calc-result')));
    expect(displayRect.right - expr.right, lessThanOrEqualTo(20));
    expect(displayRect.right - result.right, lessThanOrEqualTo(20));
  });

  testWidgets('chip modalità e input sono sulla stessa riga', (tester) async {
    await _pump(tester);
    final chip = tester.getRect(find.byKey(const ValueKey('calc-mode')));
    final expr = tester.getRect(find.byKey(const ValueKey('calc-expr')));
    expect(chip.top < expr.bottom, isTrue);
    expect(chip.bottom > expr.top, isTrue);
  });

  testWidgets('fling veloce verso il basso chiude la sheet', (tester) async {
    var closed = false;
    await _pump(tester, onClose: () => closed = true);
    await tester.fling(
      _sheet(),
      const Offset(0, 300),
      1200,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(closed, isTrue);
  });

  testWidgets('drag lento oltre metà altezza chiude la sheet', (tester) async {
    var closed = false;
    await _pump(tester, onClose: () => closed = true);
    final sheetHeight = tester.getSize(_sheet()).height;
    await tester.drag(
      _sheet(),
      Offset(0, sheetHeight * 0.8),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(closed, isTrue);
  });

  testWidgets('drag piccolo riporta la sheet su', (tester) async {
    var closed = false;
    await _pump(tester, onClose: () => closed = true);
    await tester.drag(
      _sheet(),
      const Offset(0, 40),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(closed, isFalse);
  });

  testWidgets('drag parziale lento rivela il contenuto e riporta la sheet su', (
    tester,
  ) async {
    var closed = false;
    await _pump(tester, onClose: () => closed = true);
    await tester.drag(
      _sheet(),
      const Offset(0, 150),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(closed, isFalse);
  });

  testWidgets('tap fuori dalla sheet la chiude', (tester) async {
    var closed = false;
    await _pump(tester, onClose: () => closed = true);
    final sheetRect = tester.getRect(_sheet());
    await tester.tapAt(Offset(200, sheetRect.top - 60));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(closed, isTrue);
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
              Positioned.fill(
                child: ScientificCalculatorSheet(onClose: () => closed = true),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    final rectBefore = tester.getRect(_sheet());
    await tester.dragFrom(
      Offset(400, 20),
      const Offset(0, -300),
    );
    await tester.pump();

    expect(controller.offset, greaterThan(0));
    expect(closed, isFalse);
    expect(
      tester.getRect(_sheet()),
      rectBefore,
    );

    controller.dispose();
  });
}
