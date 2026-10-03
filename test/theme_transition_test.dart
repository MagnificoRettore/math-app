import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:math_app/app.dart';
import 'package:math_app/data/content_repository.dart';
import 'package:math_app/data/progress_store.dart';
import 'package:math_app/data/settings_store.dart';
import 'package:math_app/theme/app_colors.dart';
import 'package:math_app/theme/app_theme.dart';

/// Metà della durata dichiarata in `AppTheme.transitionStyle`.
final Duration _half = AppTheme.transitionStyle.duration! ~/ 2;

const _swatch = Key('background');

Future<void> _pump(WidgetTester tester, ThemeMode mode) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: mode,
      themeAnimationStyle: AppTheme.transitionStyle,
      home: Builder(
        builder: (context) => ColoredBox(
          key: _swatch,
          color: AppColors.of(context).background,
          child: const SizedBox.expand(),
        ),
      ),
    ),
  );
}

Color _background(WidgetTester tester) =>
    tester.widget<ColoredBox>(find.byKey(_swatch)).color;

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await ContentRepository.instance.resetForTest();
    await ProgressStore.instance.resetForTest();
    await SettingsStore.instance.resetForTest();
  });

  testWidgets('l\'app collega la transizione al MaterialApp', (tester) async {
    await tester.pumpWidget(const MathApp());
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeAnimationStyle, AppTheme.transitionStyle);

    // Lo splash ha un timer di 2s: va lasciato scadere, altrimenti il test
    // finisce con timer pendenti.
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  });

  test('la transizione dura più dei 200ms di default, che si leggono come un lampo', () {
    expect(
      AppTheme.transitionStyle.duration,
      greaterThan(const Duration(milliseconds: 100)),
    );
  });

  testWidgets('il passaggio fra temi interpola i colori invece di saltare', (
    tester,
  ) async {
    await _pump(tester, ThemeMode.light);
    expect(_background(tester), AppPalette.light.background);

    await _pump(tester, ThemeMode.dark);

    // Il cambio di tema non deve essere uno scatto: al primo frame si è ancora
    // al colore di partenza.
    expect(_background(tester), AppPalette.light.background);

    // A metà transizione il colore non è ancora né chiaro né scuro: sta
    // viaggiando. È questo che rende il passamento visibile.
    await tester.pump(_half);
    final mid = _background(tester);
    expect(mid, isNot(AppPalette.light.background));
    expect(mid, isNot(AppPalette.dark.background));

    await tester.pump(_half);
    expect(_background(tester), AppPalette.dark.background);
  });
}
