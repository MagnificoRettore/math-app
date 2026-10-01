import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:math_app/models/course.dart';
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
    'anno selezionato: l\'etichetta contrasta con il cerchio accent',
    (tester) async {
      await _pumpTabs(tester, AppTheme.light);
      expect(_circleTextColor(tester), AppTheme.light.colorScheme.onPrimary);

      // In tema scuro l'accent è un lavanda chiaro: un bianco hardcoded qui
      // renderebbe il numero illeggibile.
      await _pumpTabs(tester, AppTheme.dark);
      expect(_circleTextColor(tester), isNot(Colors.white));
      expect(_circleTextColor(tester), AppTheme.dark.colorScheme.onPrimary);
    },
  );
}
