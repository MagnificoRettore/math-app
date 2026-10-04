import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:math_app/models/course.dart';
import 'package:math_app/theme/app_colors.dart';
import 'package:math_app/theme/app_motion.dart';
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
    DefaultTextStyle.of(tester.element(find.text('I'))).style.color!;

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

  group('scelta animata', () {
    const anni = [
      Course(id: 'prima', title: 'prima', subtitle: '', sections: []),
      Course(id: 'seconda', title: 'seconda', subtitle: '', sections: []),
      Course(id: 'terza', title: 'terza', subtitle: '', sections: []),
    ];

    Future<void> pumpAnni(WidgetTester tester, {bool reduced = false}) async {
      var scelto = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: reduced),
            child: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) => YearTabs(
                  courses: anni,
                  selectedIndex: scelto,
                  onSelected: (i) => setState(() => scelto = i),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    BoxDecoration quadrato(WidgetTester tester, String lettera) =>
        tester
                .widget<AnimatedContainer>(
                  find.ancestor(
                    of: find.text(lettera),
                    matching: find.byType(AnimatedContainer),
                  ),
                )
                .decoration!
            as BoxDecoration;

    testWidgets('lo scelto è giallo col bordo oro, senza spunta', (
      tester,
    ) async {
      await pumpAnni(tester);
      expect(quadrato(tester, 'I').color, AppPalette.light.yellow);
      expect(quadrato(tester, 'III').color, AppPalette.light.surface);
      expect(find.byIcon(Icons.check_rounded), findsNothing);

      await tester.tap(find.text('terza'));
      await tester.pumpAndSettle();
      expect(quadrato(tester, 'I').color, AppPalette.light.surface);
      expect(quadrato(tester, 'III').color, AppPalette.light.yellow);
      expect(
        (quadrato(tester, 'III').border! as Border).top.color,
        AppPalette.light.yellowDeep,
      );
      expect(
        DefaultTextStyle.of(tester.element(find.text('III'))).style.color,
        AppPalette.light.textPrimary,
      );
      expect(find.byIcon(Icons.check_rounded), findsNothing);
    });

    testWidgets('durate e curve da AppMotion, zero col movimento ridotto', (
      tester,
    ) async {
      await pumpAnni(tester);
      final quadrato = tester
          .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
          .first;
      expect(quadrato.duration, AppMotion.medium);
      expect(quadrato.curve, AppMotion.standard);

      await pumpAnni(tester, reduced: true);
      expect(
        tester
            .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
            .first
            .duration,
        Duration.zero,
      );
    });

    testWidgets('ogni anno è un bottone, quello scelto «selezionato»', (
      tester,
    ) async {
      final semantica = tester.ensureSemantics();
      await pumpAnni(tester);
      expect(
        tester.getSemantics(find.text('prima')),
        matchesSemantics(
          label: 'prima',
          isButton: true,
          isSelected: true,
          hasSelectedState: true,
          hasTapAction: true,
        ),
      );
      semantica.dispose();
    });
  });
}
