import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:math_app/theme/app_theme.dart';
import 'package:math_app/widgets/mcq_option_tile.dart';
import 'package:math_app/widgets/shake.dart';

Widget _host(Widget child, {bool reduced = false}) => MaterialApp(
  theme: AppTheme.light,
  home: Builder(
    builder: (context) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
      child: Scaffold(body: Center(child: child)),
    ),
  ),
);

Widget _opzione(McqOptionState state, {bool reduced = false}) => _host(
  SizedBox(
    width: 300,
    child: McqOptionTile(
      label: 'x = 3',
      state: state,
      enabled: true,
      scale: 1,
      onTap: () {},
    ),
  ),
  reduced: reduced,
);

/// La scala del pop: il `Transform` più esterno dentro l'opzione. Si legge
/// la scala orizzontale (`storage[0]`): `getMaxScaleOnAxis` conta anche l'asse
/// z, che `Transform.scale` lascia a 1, e sotto 1 direbbe sempre 1.
double _scalaPop(WidgetTester tester) => tester
    .widget<Transform>(
      find
          .descendant(
            of: find.byType(McqOptionTile),
            matching: find.byType(Transform),
          )
          .first,
    )
    .transform
    .storage[0];

void main() {
  group('pop della risposta giusta', () {
    testWidgets('l\'opzione giusta cresce e torna alla sua misura', (
      tester,
    ) async {
      await tester.pumpWidget(_opzione(McqOptionState.selected));
      expect(_scalaPop(tester), 1);

      await tester.pumpWidget(_opzione(McqOptionState.correct));
      await tester.pump(const Duration(milliseconds: 150));
      expect(_scalaPop(tester), greaterThan(1.03));

      await tester.pumpAndSettle();
      expect(_scalaPop(tester), closeTo(1, 1e-9));
    });

    testWidgets('la spunta entra in scala', (tester) async {
      await tester.pumpWidget(_opzione(McqOptionState.selected));
      await tester.pumpWidget(_opzione(McqOptionState.correct));
      await tester.pump(const Duration(milliseconds: 30));

      double scalaSpunta() => tester
          .widget<Transform>(
            find
                .ancestor(
                  of: find.byIcon(Icons.check_circle),
                  matching: find.byType(Transform),
                )
                .first,
          )
          .transform
          .storage[0];
      expect(scalaSpunta(), lessThan(1));
      await tester.pumpAndSettle();
      expect(scalaSpunta(), closeTo(1, 1e-9));
    });

    testWidgets('col movimento ridotto niente pop', (tester) async {
      await tester.pumpWidget(_opzione(McqOptionState.selected, reduced: true));
      await tester.pumpWidget(_opzione(McqOptionState.correct, reduced: true));
      await tester.pump();
      expect(_scalaPop(tester), closeTo(1, 1e-9));
    });
  });

  group('shake della risposta sbagliata', () {
    const card = McqFeedbackCard(correct: false, message: 'Riprova', scale: 1);

    testWidgets('la card si scuote e torna al suo posto', (tester) async {
      await tester.pumpWidget(_host(const ShakeWidget(child: card)));
      final riposo = tester.getTopLeft(find.byType(McqFeedbackCard)).dx;

      await tester.pump(const Duration(milliseconds: 40));
      expect(
        tester.getTopLeft(find.byType(McqFeedbackCard)).dx,
        isNot(closeTo(riposo, 0.5)),
      );

      await tester.pumpAndSettle();
      expect(
        tester.getTopLeft(find.byType(McqFeedbackCard)).dx,
        closeTo(riposo, 0.01),
      );
    });

    testWidgets('col movimento ridotto niente scossa', (tester) async {
      await tester.pumpWidget(
        _host(const ShakeWidget(child: card), reduced: true),
      );
      expect(
        find.descendant(
          of: find.byType(ShakeWidget),
          matching: find.byType(TweenAnimationBuilder<double>),
        ),
        findsNothing,
      );
      expect(find.text('Non è corretto'), findsOneWidget);
    });
  });
}
