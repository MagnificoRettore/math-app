import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:math_app/theme/app_colors.dart';
import 'package:math_app/theme/app_motion.dart';
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

  group('riempimento animato', () {
    Future<void> barra(
      WidgetTester tester,
      double progress, {
      bool reduced = false,
    }) => tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: reduced),
          child: Scaffold(
            body: SizedBox(
              width: 200,
              child: ProgressBar(progress: progress, height: 18),
            ),
          ),
        ),
      ),
    );

    double larghezza(WidgetTester tester) =>
        tester.getSize(find.byType(FractionallySizedBox)).width;

    // Dentro i 2 px di bordo per lato.
    const pieno = 200 - 4;

    testWidgets('al primo disegno è già al suo valore', (tester) async {
      await barra(tester, 0.5);
      expect(larghezza(tester), closeTo(0.5 * pieno, 0.5));
    });

    testWidgets('cambiando valore il riempimento ci arriva animato', (
      tester,
    ) async {
      await barra(tester, 0.2);
      await barra(tester, 0.8);
      await tester.pump(AppMotion.slow ~/ 2);
      final meta = larghezza(tester);
      expect(meta, greaterThan(0.2 * pieno));
      expect(meta, lessThan(0.8 * pieno));

      await tester.pumpAndSettle();
      expect(larghezza(tester), closeTo(0.8 * pieno, 0.5));
    });

    testWidgets('durata e curva da AppMotion, zero col movimento ridotto', (
      tester,
    ) async {
      await barra(tester, 0.3);
      final animazione = tester.widget<TweenAnimationBuilder<double>>(
        find.byType(TweenAnimationBuilder<double>),
      );
      expect(animazione.duration, AppMotion.slow);
      expect(animazione.curve, AppMotion.standard);

      await barra(tester, 0.3, reduced: true);
      await barra(tester, 0.9, reduced: true);
      await tester.pump();
      expect(larghezza(tester), closeTo(0.9 * pieno, 0.5));
    });

    testWidgets('lo screen reader legge la percentuale', (tester) async {
      final semantica = tester.ensureSemantics();
      await barra(tester, 0.4);
      expect(
        tester.getSemantics(find.byType(ProgressBar)),
        matchesSemantics(value: '40%'),
      );
      semantica.dispose();
    });
  });
}
