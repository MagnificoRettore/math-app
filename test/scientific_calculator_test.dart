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

/// Tocca un tasto: l'ultimo testo uguale, perché il display può mostrare lo
/// stesso testo (un `5` scritto è anche il tasto `5`).
Future<void> _keys(WidgetTester tester, List<String> labels) async {
  for (final label in labels) {
    await tester.tap(find.text(label).last);
    await tester.pump();
  }
}

String _expr(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(const ValueKey('calc-expr'))).data!;

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

  testWidgets('√(16 senza chiusa: la parentesi si chiude e risolve', (
    tester,
  ) async {
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

  testWidgets('espressione e risultato sono allineati a destra', (
    tester,
  ) async {
    await _pump(tester);
    final displayRect = tester.getRect(
      find.byKey(const ValueKey('calc-display')),
    );
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
    await tester.fling(_sheet(), const Offset(0, 300), 1200);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(closed, isTrue);
  });

  testWidgets('drag lento oltre metà altezza chiude la sheet', (tester) async {
    var closed = false;
    await _pump(tester, onClose: () => closed = true);
    final sheetHeight = tester.getSize(_sheet()).height;
    await tester.drag(_sheet(), Offset(0, sheetHeight * 0.8));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(closed, isTrue);
  });

  testWidgets('drag piccolo riporta la sheet su', (tester) async {
    var closed = false;
    await _pump(tester, onClose: () => closed = true);
    await tester.drag(_sheet(), const Offset(0, 40));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(closed, isFalse);
  });

  testWidgets('drag parziale lento rivela il contenuto e riporta la sheet su', (
    tester,
  ) async {
    var closed = false;
    await _pump(tester, onClose: () => closed = true);
    await tester.drag(_sheet(), const Offset(0, 150));
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
    await tester.dragFrom(Offset(400, 20), const Offset(0, -300));
    await tester.pump();

    expect(controller.offset, greaterThan(0));
    expect(closed, isFalse);
    expect(tester.getRect(_sheet()), rectBefore);

    controller.dispose();
  });

  group('come una calcolatrice classica', () {
    testWidgets('divisione: 8 ÷ 2 = 4', (tester) async {
      await _pump(tester);
      await _keys(tester, ['8', '÷', '2', '=']);
      expect(_result(tester), '4');
    });

    testWidgets('± due volte torna al numero di partenza', (tester) async {
      await _pump(tester);
      await _keys(tester, ['5', '±']);
      expect(_expr(tester), '−5');
      await _keys(tester, ['±']);
      expect(_expr(tester), '5');
    });

    testWidgets('un solo punto per numero', (tester) async {
      await _pump(tester);
      await _keys(tester, ['1', '.', '.', '5', '=']);
      expect(_result(tester), '1.5');
    });

    testWidgets('dopo = un operatore continua dal risultato', (tester) async {
      await _pump(tester);
      await _keys(tester, ['2', '+', '3', '=', '×', '2', '=']);
      expect(_result(tester), '10');
    });

    testWidgets('dopo = un numero comincia da capo', (tester) async {
      await _pump(tester);
      await _keys(tester, ['2', '+', '3', '=', '7', '=']);
      expect(_result(tester), '7');
    });

    testWidgets('il meno dopo × è il segno: 5 × −3 = −15', (tester) async {
      await _pump(tester);
      await _keys(tester, ['5', '×', '−', '3', '=']);
      expect(_result(tester), '-15');
    });

    testWidgets('moltiplicazione implicita: 2π e 2(3)', (tester) async {
      await _pump(tester);
      await _keys(tester, ['2', 'π', '=']);
      expect(_result(tester), startsWith('6.28318'));
      await _keys(tester, ['AC', '2', '(', '3', ')', '=']);
      expect(_result(tester), '6');
    });

    testWidgets('percentuale: 50% = 0.5 e 200 × 10% = 20', (tester) async {
      await _pump(tester);
      await _keys(tester, ['5', '0', '%', '=']);
      expect(_result(tester), '0.5');
      await _keys(tester, ['AC', '2', '0', '0', '×', '1', '0', '%', '=']);
      expect(_result(tester), '20');
    });

    testWidgets('x², x⁻¹ e n! sul numero scritto', (tester) async {
      await _pump(tester);
      await _keys(tester, ['3', 'x²', '=']);
      expect(_result(tester), '9');
      await _keys(tester, ['AC', '4', 'x⁻¹', '=']);
      expect(_result(tester), '0.25');
      await _keys(tester, ['AC', '5', 'n!', '=']);
      expect(_result(tester), '120');
    });

    testWidgets('2nd dà le inverse e si spegne dopo l\'uso', (tester) async {
      await _pump(tester);
      await tester.tap(find.byKey(const ValueKey('calc-mode')));
      await tester.pump();
      await _keys(tester, ['2nd']);
      expect(find.text('sin⁻¹'), findsOneWidget);
      await _keys(tester, ['sin⁻¹', '1', '=']);
      expect(_result(tester), '90');
      expect(find.text('sin'), findsOneWidget);
      expect(find.text('sin⁻¹'), findsNothing);
    });

    testWidgets('2nd su log dà 10ˣ', (tester) async {
      await _pump(tester);
      await _keys(tester, ['2nd', '10ˣ', '3', '=']);
      expect(_result(tester), '1000');
    });

    testWidgets('memoria: M+, MR e MC', (tester) async {
      await _pump(tester);
      await _keys(tester, ['5', 'M+']);
      expect(find.byKey(const ValueKey('calc-memory')), findsOneWidget);
      await _keys(tester, ['AC', 'MR', '+', '1', '=']);
      expect(_result(tester), '6');
      await _keys(tester, ['MC']);
      expect(find.byKey(const ValueKey('calc-memory')), findsNothing);
    });

    testWidgets('Ans richiama l\'ultimo risultato', (tester) async {
      await _pump(tester);
      await _keys(tester, ['2', '+', '3', '=', 'AC', 'Ans', '×', '2', '=']);
      expect(_result(tester), '10');
    });

    testWidgets('⌫ toglie una funzione intera', (tester) async {
      await _pump(tester);
      await _keys(tester, ['2', '+', 'sin']);
      expect(_expr(tester), '2+sin(');
      await _keys(tester, ['⌫']);
      expect(_expr(tester), '2+');
    });

    testWidgets('0 elevato a −1 è un errore, non zero', (tester) async {
      await _pump(tester);
      await _keys(tester, ['0', 'xʸ', '−', '1', '=']);
      expect(_result(tester), 'Errore');
    });
  });
}
