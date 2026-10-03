import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:math_app/theme/app_colors.dart';
import 'package:math_app/theme/app_text.dart';
import 'package:math_app/theme/app_theme.dart';
import 'package:math_app/widgets/app_button.dart';

Future<void> _pump(WidgetTester tester, Widget button) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(body: Center(child: button)),
    ),
  );
}

/// La decorazione della faccia del bottone: il primo `AnimatedContainer`.
BoxDecoration _faccia(WidgetTester tester) =>
    tester.widget<AnimatedContainer>(find.byType(AnimatedContainer)).decoration!
        as BoxDecoration;

void main() {
  const p = AppPalette.light;

  testWidgets('principale: indaco col gradino pieno sotto', (tester) async {
    await _pump(tester, AppButton(label: 'Inizia', onPressed: () {}));

    final faccia = _faccia(tester);
    expect(faccia.color, p.accent);
    final gradino = faccia.boxShadow!.single;
    expect(gradino.color, p.accentDeep);
    expect(gradino.blurRadius, 0);
    expect(gradino.offset, const Offset(0, AppButton.depth));
  });

  testWidgets('secondario: giallo con l\'inchiostro sopra', (tester) async {
    await _pump(
      tester,
      AppButton(
        label: 'Continua',
        variant: AppButtonVariant.secondary,
        onPressed: () {},
      ),
    );

    expect(_faccia(tester).color, p.yellow);
    expect(_faccia(tester).boxShadow!.single.color, p.yellowDeep);
    final testo = tester.widget<Text>(find.text('Continua')).style!;
    expect(testo.color, p.textPrimary);
    expect(testo.fontFamily, AppText.headingFont);
  });

  testWidgets('disabilitato: grigio caldo e senza gradino', (tester) async {
    await _pump(tester, const AppButton(label: 'Salva', onPressed: null));

    expect(_faccia(tester).color, p.disabled);
    expect(_faccia(tester).boxShadow, isEmpty);
  });

  testWidgets('l\'altezza comprende il gradino e non cambia premendo', (
    tester,
  ) async {
    await _pump(tester, AppButton(label: 'Inizia', onPressed: () {}));
    final prima = tester.getSize(find.byType(AppButton)).height;
    expect(prima, 52 + AppButton.depth);

    final gesto = await tester.startGesture(
      tester.getCenter(find.byType(AppButton)),
    );
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(AppButton)).height, prima);
    // Premuto, il gradino si accorcia: la faccia scende.
    expect(
      _faccia(tester).boxShadow!.single.offset.dy,
      lessThan(AppButton.depth),
    );
    await gesto.up();
  });

  testWidgets('il tap chiama onPressed, occupato no', (tester) async {
    var tocchi = 0;
    await _pump(tester, AppButton(label: 'Accedi', onPressed: () => tocchi++));
    await tester.tap(find.text('Accedi'));
    expect(tocchi, 1);

    await _pump(
      tester,
      AppButton(label: 'Accedi', busy: true, onPressed: () => tocchi++),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.tap(find.byType(AppButton));
    expect(tocchi, 1);
  });
}
