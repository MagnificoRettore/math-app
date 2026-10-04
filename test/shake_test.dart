import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:math_app/theme/app_motion.dart';
import 'package:math_app/theme/app_theme.dart';
import 'package:math_app/widgets/shake.dart';

/// Lo spostamento orizzontale della scossa attorno al campo.
double _scostamento(WidgetTester tester) => tester
    .widget<Transform>(
      find
          .descendant(
            of: find.byType(ShakeWidget),
            matching: find.byType(Transform),
          )
          .first,
    )
    .transform
    .getTranslation()
    .x;

void main() {
  final focus = FocusNode();
  final controller = TextEditingController();
  tearDownAll(() {
    focus.dispose();
    controller.dispose();
  });

  Widget campo(int trigger, {bool reduced = false}) => MaterialApp(
    theme: AppTheme.light,
    home: Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
        child: Scaffold(
          body: ShakeWidget(
            trigger: trigger,
            child: TextField(focusNode: focus, controller: controller),
          ),
        ),
      ),
    ),
  );

  testWidgets('con il trigger non si scuote al montaggio', (tester) async {
    await tester.pumpWidget(campo(0));
    await tester.pump(AppMotion.slow ~/ 3);
    expect(_scostamento(tester), 0);
  });

  testWidgets('si scuote quando il trigger cresce, poi torna al suo posto', (
    tester,
  ) async {
    await tester.pumpWidget(campo(0));
    await tester.pumpWidget(campo(1));
    await tester.pump(const Duration(milliseconds: 40));
    expect(_scostamento(tester).abs(), greaterThan(1));

    await tester.pumpAndSettle();
    expect(_scostamento(tester), closeTo(0, 1e-9));
  });

  testWidgets('il campo che si scuote tiene fuoco e testo', (tester) async {
    await tester.pumpWidget(campo(0));
    await tester.tap(find.byType(TextField));
    await tester.enterText(find.byType(TextField), 'abc');
    final prima = tester.state(find.byType(TextField));

    await tester.pumpWidget(campo(1));
    await tester.pumpAndSettle();
    expect(focus.hasFocus, isTrue);
    expect(controller.text, 'abc');
    expect(tester.state(find.byType(TextField)), same(prima));
  });

  testWidgets('col movimento ridotto niente scossa', (tester) async {
    await tester.pumpWidget(campo(0, reduced: true));
    await tester.pumpWidget(campo(1, reduced: true));
    await tester.pump(const Duration(milliseconds: 40));
    expect(
      find.descendant(
        of: find.byType(ShakeWidget),
        matching: find.byType(TweenAnimationBuilder<double>),
      ),
      findsNothing,
    );
  });

  test('FieldShakes fa scuotere solo i campi vuoti', () {
    final pieno = TextEditingController(text: 'Anna');
    final vuoto = TextEditingController(text: '   ');
    final shakes = FieldShakes()..shakeEmpty([pieno, vuoto]);
    expect(shakes.of(pieno), 0);
    expect(shakes.of(vuoto), 1);
    shakes.shakeEmpty([pieno, vuoto]);
    expect(shakes.of(vuoto), 2);
    pieno.dispose();
    vuoto.dispose();
  });
}
