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

    List<double> spunte(WidgetTester tester) => tester
        .widgetList<AnimatedScale>(find.byKey(const Key('year-tab-check')))
        .map((s) => s.scale)
        .toList();

    testWidgets('la spunta sta solo sull\'anno scelto e si sposta', (
      tester,
    ) async {
      await pumpAnni(tester);
      expect(spunte(tester), [1, 0, 0]);

      await tester.tap(find.text('terza'));
      await tester.pumpAndSettle();
      expect(spunte(tester), [0, 0, 1]);
      expect(
        DefaultTextStyle.of(tester.element(find.text('III'))).style.color,
        AppPalette.light.textPrimary,
      );
    });

    testWidgets('durate e curve da AppMotion, zero col movimento ridotto', (
      tester,
    ) async {
      await pumpAnni(tester);
      final spunta = tester
          .widgetList<AnimatedScale>(find.byKey(const Key('year-tab-check')))
          .first;
      expect(spunta.duration, AppMotion.slow);
      expect(spunta.curve, AppMotion.bounce);
      expect(
        tester
            .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
            .first
            .duration,
        AppMotion.medium,
      );

      await pumpAnni(tester, reduced: true);
      expect(
        tester
            .widgetList<AnimatedScale>(find.byKey(const Key('year-tab-check')))
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
