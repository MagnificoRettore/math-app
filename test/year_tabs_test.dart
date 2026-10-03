import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:math_app/models/course.dart';
import 'package:math_app/theme/app_colors.dart';
import 'package:math_app/theme/app_theme.dart';
import 'package:math_app/widgets/year_tabs.dart';

/// Il tema si applica in partenza, ma `MaterialApp` lo avvolge comunque in un
/// `AnimatedTheme` da 200ms: senza aspettare, l'albero è ancora al tema
/// precedente e i colori non sono quelli finali.
Future<void> _pumpTabs(WidgetTester tester, ThemeData theme) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: theme,
      home: Scaffold(
        body: YearTabs(
          courses: const [
            Course(id: 'prima', title: 'prima', subtitle: '', sections: []),
          ],
          selectedIndex: 0,
          onSelected: (_) {},
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Colore del numero dentro il cerchio dell'anno selezionato.
Color _circleTextColor(WidgetTester tester) =>
    tester.widget<Text>(find.text('I')).style!.color!;

void main() {
  testWidgets(
    'anno selezionato: inchiostro sul giallo, come la «Classe» del design',
    (tester) async {
      await _pumpTabs(tester, AppTheme.light);
      expect(_circleTextColor(tester), AppPalette.light.textPrimary);
      // L'inchiostro sul giallo passa ampiamente 4.5:1.
      final fondo = AppPalette.light.yellow.computeLuminance();
      final testo = _circleTextColor(tester).computeLuminance();
      expect((fondo + 0.05) / (testo + 0.05), greaterThan(4.5));
    },
  );
}
