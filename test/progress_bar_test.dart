import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:math_app/theme/app_colors.dart';
import 'package:math_app/theme/app_theme.dart';
import 'package:math_app/widgets/progress_bar.dart';

Future<void> _pump(WidgetTester tester, ProgressBar bar) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(body: SizedBox(width: 200, child: bar)),
    ),
  );
}

BoxDecoration _fondo(WidgetTester tester) =>
    tester
            .widget<Container>(
              find
                  .descendant(
                    of: find.byType(ProgressBar),
                    matching: find.byType(Container),
                  )
                  .first,
            )
            .decoration!
        as BoxDecoration;

void main() {
  const p = AppPalette.light;

  testWidgets('alta: fondo giallo chiaro, bordo oro, riempimento a strisce', (
    tester,
  ) async {
    await _pump(tester, const ProgressBar(progress: 0.4, height: 18));

    expect(_fondo(tester).color, p.yellowSoft);
    expect((_fondo(tester).border! as Border).top.color, p.yellowDeep);
    expect(
      find.descendant(
        of: find.byType(ProgressBar),
        matching: find.byType(CustomPaint),
      ),
      findsWidgets,
    );
    // Il riempimento occupa la frazione giusta, dentro i 2 px di bordo.
    final riempimento = tester.getSize(find.byType(FractionallySizedBox));
    expect(riempimento.width, closeTo(0.4 * (200 - 4), 0.5));
  });

  testWidgets('sottile: piena e senza bordo, le strisce non si leggerebbero', (
    tester,
  ) async {
    await _pump(tester, ProgressBar(progress: 0.5, height: 4, color: p.medium));

    expect(_fondo(tester).border, isNull);
    final pieno = tester.widget<ColoredBox>(
      find.descendant(
        of: find.byType(FractionallySizedBox),
        matching: find.byType(ColoredBox),
      ),
    );
    expect(pieno.color, p.medium);
  });
}
