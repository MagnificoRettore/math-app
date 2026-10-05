import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:math_app/data/settings_store.dart';
import 'package:math_app/screens/onboarding_screen.dart';
import 'package:math_app/screens/welcome_screen.dart';
import 'package:math_app/theme/app_theme.dart';
import 'package:math_app/widgets/empty_state.dart';
import 'package:math_app/widgets/illustration.dart';

Future<void> _pump(WidgetTester tester, Widget home) async {
  await tester.pumpWidget(MaterialApp(theme: AppTheme.light, home: home));
  await tester.pump();
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SettingsStore.instance.resetForTest();
  });

  test('ogni illustrazione è un SVG statico, senza segnaposto del canvas', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    for (final illustration in AppIllustration.values) {
      final svg = await rootBundle.loadString(illustration.asset);
      expect(svg, contains('<svg'));
      // Niente `{{bg}}` del canvas, niente `<use>` e `currentColor`: sono stati
      // risolti nella conversione, così il disegno non dipende dal parser.
      expect(svg, isNot(contains('{{')));
      expect(svg, isNot(contains('<use')));
      expect(svg, isNot(contains('currentColor')));
    }
  });

  testWidgets('lo stato vuoto mostra l\'albero, il merito il razzo', (
    tester,
  ) async {
    await _pump(
      tester,
      const Scaffold(
        body: EmptyState(title: 'Vuoto', subtitle: 'In arrivo'),
      ),
    );
    expect(find.byKey(const ValueKey('illustration-albero')), findsOneWidget);

    await _pump(
      tester,
      const Scaffold(
        body: EmptyState(
          title: 'Tutto assimilato!',
          subtitle: 'Ottimo lavoro',
          illustration: AppIllustration.razzo,
        ),
      ),
    );
    expect(find.byKey(const ValueKey('illustration-razzo')), findsOneWidget);
  });

  testWidgets('l\'onboarding non ha illustrazioni', (tester) async {
    await _pump(tester, const OnboardingScreen());
    expect(find.byType(IllustrationView), findsNothing);
  });

  testWidgets('il benvenuto ha la testata indaco ondulata', (tester) async {
    await _pump(tester, const WelcomeScreen());
    expect(
      find.descendant(
        of: find.byKey(const Key('welcome-hero')),
        matching: find.text('Math App\nStudia con noi'),
      ),
      findsOneWidget,
    );
  });
}
