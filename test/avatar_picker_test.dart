import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:math_app/theme/app_colors.dart';
import 'package:math_app/theme/app_motion.dart';
import 'package:math_app/theme/app_theme.dart';
import 'package:math_app/widgets/avatar_picker.dart';
import 'package:math_app/widgets/profile_avatar.dart';

final _razzo = find.byKey(
  const ValueKey('avatar-option-rocket_launch_rounded'),
);

Future<List<String>> _pump(WidgetTester tester, {bool reduced = false}) async {
  final scelte = <String>[];
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: reduced),
        child: Scaffold(
          body: Center(
            child: AvatarPicker(value: '', onChanged: scelte.add),
          ),
        ),
      ),
    ),
  );
  return scelte;
}

AnimatedScale _scala(WidgetTester tester, Finder option) => tester.widget(
  find.descendant(of: option, matching: find.byType(AnimatedScale)),
);

BoxDecoration _cerchio(WidgetTester tester, Finder option) =>
    tester
            .widget<AnimatedContainer>(
              find.descendant(
                of: option,
                matching: find.byType(AnimatedContainer),
              ),
            )
            .decoration!
        as BoxDecoration;

void main() {
  test('il razzo è fra gli avatar proposti', () {
    expect(avatarOptions, contains('rocket_launch_rounded'));
  });

  testWidgets('scelto: cresce con un rimbalzo e il bordo compare', (
    tester,
  ) async {
    final scelte = await _pump(tester);
    expect(_scala(tester, _razzo).scale, 1);

    await tester.tap(_razzo);
    await tester.pump();

    expect(scelte, ['rocket_launch_rounded']);
    final scala = _scala(tester, _razzo);
    expect(scala.scale, greaterThan(1));
    expect(scala.curve, AppMotion.bounce);
    expect(scala.duration, AppMotion.slow);
    final cerchio = _cerchio(tester, _razzo);
    expect((cerchio.border! as Border).top.color, AppPalette.light.accent);
    expect(cerchio.boxShadow!.last.color, AppPalette.light.yellow);
    await tester.pumpAndSettle();
  });

  testWidgets('la scelta passa da un avatar all\'altro', (tester) async {
    await _pump(tester);
    final scienza = find.byKey(const ValueKey('avatar-option-science_rounded'));
    await tester.tap(_razzo);
    await tester.pumpAndSettle();
    await tester.tap(scienza);
    await tester.pumpAndSettle();

    expect(_scala(tester, _razzo).scale, 1);
    expect(_scala(tester, scienza).scale, greaterThan(1));
  });

  testWidgets('col movimento ridotto niente animazione', (tester) async {
    await _pump(tester, reduced: true);
    await tester.tap(_razzo);
    await tester.pump();
    expect(_scala(tester, _razzo).duration, Duration.zero);
  });

  testWidgets('l\'avatar scelto è «selezionato» per lo screen reader', (
    tester,
  ) async {
    final semantica = tester.ensureSemantics();
    await _pump(tester);
    await tester.tap(_razzo);
    await tester.pumpAndSettle();
    expect(
      tester.getSemantics(_razzo),
      matchesSemantics(
        label: 'Avatar rocket_launch_rounded',
        isButton: true,
        isSelected: true,
        hasSelectedState: true,
        hasTapAction: true,
        hasFocusAction: true,
        isFocusable: true,
      ),
    );
    // L'area di tocco è il cerchio da 52: oltre i 44.
    expect(tester.getSize(_razzo).width, greaterThanOrEqualTo(44));
    semantica.dispose();
  });
}
