import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:math_app/theme/app_theme.dart';
import 'package:math_app/widgets/math_text.dart';

Future<Size> _misura(WidgetTester tester, MathText testo) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: Align(alignment: Alignment.topLeft, child: testo),
      ),
    ),
  );
  return tester.getSize(find.byType(MathText));
}

void main() {
  testWidgets('una formula sola in linea non è più alta di una riga di testo', (
    tester,
  ) async {
    final testo = await _misura(tester, const MathText('Testo semplice'));
    final formula = await _misura(
      tester,
      const MathText(r'$$x + 1$$', inline: true),
    );
    expect(formula.height, lessThanOrEqualTo(testo.height));
  });

  testWidgets('senza `inline` una formula sola resta «in display», più alta', (
    tester,
  ) async {
    final testo = await _misura(tester, const MathText('Testo semplice'));
    final formula = await _misura(tester, const MathText(r'$$x + 1$$'));
    expect(formula.height, greaterThan(testo.height + 8));
  });
}
